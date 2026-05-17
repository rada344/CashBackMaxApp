import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Tracks the device's online/offline state and exposes it as a
/// [ValueNotifier] so widgets can rebuild reactively.
///
/// Three layers of detection (in order of preference):
///   1. `connectivity_plus` stream events — fast, but unreliable on web
///      because Chrome / macOS doesn't always fire `online`/`offline` events
///      when Wi-Fi is toggled.
///   2. Periodic poll of `checkConnectivity()` — catches state changes the
///      event listener missed. Polls navigator.onLine on web.
///   3. Periodic HTTP HEAD probe — the source of truth. Issues a tiny
///      request to a CORS-friendly Google CDN URL with a short timeout.
///      Unlike a Firestore probe this has zero SDK state, so recovery on
///      reconnect is instant.
class ConnectivityService {
  ConnectivityService._();
  static final ConnectivityService instance = ConnectivityService._();

  final Connectivity _connectivity = Connectivity();
  final ValueNotifier<bool> isOnline = ValueNotifier<bool>(true);

  StreamSubscription<List<ConnectivityResult>>? _sub;
  Timer? _pollTimer;
  Timer? _probeTimer;
  bool _loaded = false;

  // Small Firebase JS SDK file on Google's CDN. Has permissive CORS, is
  // cached aggressively by browsers, and always returns 200.
  static final Uri _probeUrl =
      Uri.parse('https://www.gstatic.com/firebasejs/10.7.1/firebase-app.js');

  static const _pollEvery = Duration(seconds: 3);
  static const _probeEvery = Duration(seconds: 6);
  static const _probeTimeout = Duration(seconds: 3);

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final initial = await _connectivity.checkConnectivity();
      _update(_anyOnline(initial), source: 'init');
      _sub = _connectivity.onConnectivityChanged.listen((results) {
        _update(_anyOnline(results), source: 'stream');
      });
    } catch (e) {
      debugPrint('ConnectivityService init failed: $e');
    }

    _pollTimer = Timer.periodic(_pollEvery, (_) => _poll());
    _probeTimer = Timer.periodic(_probeEvery, (_) => _probe());
    // Kick off an immediate probe so we don't wait 6s for first signal.
    _probe();
  }

  Future<void> _poll() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _update(_anyOnline(results), source: 'poll');
    } catch (_) {}
  }

  Future<void> _probe() async {
    try {
      final r = await http
          .head(_probeUrl)
          .timeout(_probeTimeout);
      _update(r.statusCode < 500, source: 'probe-${r.statusCode}');
    } catch (_) {
      _update(false, source: 'probe-timeout');
    }
  }

  void _update(bool next, {required String source}) {
    if (next != isOnline.value) {
      debugPrint('Connectivity → ${next ? "online" : "OFFLINE"} ($source)');
      isOnline.value = next;
    }
  }

  bool _anyOnline(List<ConnectivityResult> results) {
    if (results.isEmpty) return false;
    return results.any((r) => r != ConnectivityResult.none);
  }

  void dispose() {
    _sub?.cancel();
    _sub = null;
    _pollTimer?.cancel();
    _pollTimer = null;
    _probeTimer?.cancel();
    _probeTimer = null;
  }
}
