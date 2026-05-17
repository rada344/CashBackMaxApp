import 'dart:js_interop';

import 'package:flutter/foundation.dart';

/// Bridges to the JS shim defined in `web/index.html` (`cbmNotify*` functions).
/// On non-web platforms every call is a no-op and the service reports
/// `unsupported` — drop-in callers don't need their own platform guards.
class NativeNotificationService {
  NativeNotificationService._();
  static final NativeNotificationService instance = NativeNotificationService._();

  /// `'granted'`, `'denied'`, `'default'` (not yet asked), or `'unsupported'`.
  String get permission {
    if (!kIsWeb) return 'unsupported';
    try {
      return _cbmNotifyPermission();
    } catch (_) {
      return 'unsupported';
    }
  }

  bool get isSupported {
    if (!kIsWeb) return false;
    try {
      return _cbmNotifySupported();
    } catch (_) {
      return false;
    }
  }

  /// Triggers the browser permission prompt. Resolves with the new permission
  /// string ('granted', 'denied', 'default', or 'unsupported').
  Future<String> requestPermission() async {
    if (!kIsWeb) return 'unsupported';
    try {
      final result = await _cbmNotifyRequest().toDart;
      return result.toDart;
    } catch (e) {
      debugPrint('NativeNotificationService.requestPermission failed: $e');
      return 'unsupported';
    }
  }

  /// Fires a native browser notification if permission has been granted.
  /// Silently no-ops otherwise.
  void show({required String title, required String body}) {
    if (!kIsWeb) return;
    if (permission != 'granted') return;
    try {
      _cbmNotifyShow(title, body);
    } catch (e) {
      debugPrint('NativeNotificationService.show failed: $e');
    }
  }
}

@JS('cbmNotifySupported')
external bool _cbmNotifySupported();

@JS('cbmNotifyPermission')
external String _cbmNotifyPermission();

@JS('cbmNotifyRequest')
external JSPromise<JSString> _cbmNotifyRequest();

@JS('cbmNotifyShow')
external void _cbmNotifyShow(String title, String body);
