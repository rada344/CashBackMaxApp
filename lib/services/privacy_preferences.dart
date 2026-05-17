import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'connectivity_service.dart';

/// Persisted privacy toggles. Local cache for offline + Firestore doc
/// `users/{uid}/preferences/privacy` for cross-device sync.
class PrivacyPreferences {
  PrivacyPreferences._();
  static final PrivacyPreferences instance = PrivacyPreferences._();

  static const _location = 'privacy.locationBasedRecommendations';
  static const _marketing = 'privacy.marketingConsent';

  bool _locationBasedRecommendations = true;
  bool _marketingConsent = false;

  bool _loaded = false;

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    _loaded = true;
    final prefs = await SharedPreferences.getInstance();
    _locationBasedRecommendations =
        prefs.getBool(_location) ?? _locationBasedRecommendations;
    _marketingConsent = prefs.getBool(_marketing) ?? _marketingConsent;
  }

  bool get locationBasedRecommendations => _locationBasedRecommendations;
  bool get marketingConsent => _marketingConsent;

  Future<void> setLocationBasedRecommendations(bool v) async {
    _locationBasedRecommendations = v;
    await _writeLocal(_location, v);
    await _writeCloud();
  }

  Future<void> setMarketingConsent(bool v) async {
    _marketingConsent = v;
    await _writeLocal(_marketing, v);
    await _writeCloud();
  }

  static const _timeout = Duration(seconds: 10);

  Future<void> syncFromCloud(String uid) async {
    if (uid.isEmpty) return;
    if (!ConnectivityService.instance.isOnline.value) return;
    try {
      final ref = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('preferences')
          .doc('privacy');
      final snap = await ref.get().timeout(_timeout);
      if (!snap.exists) {
        await _writeCloud();
        return;
      }
      final data = snap.data()!;
      _locationBasedRecommendations = data['locationBasedRecommendations'] as bool? ??
          _locationBasedRecommendations;
      _marketingConsent = data['marketingConsent'] as bool? ?? _marketingConsent;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_location, _locationBasedRecommendations);
      await prefs.setBool(_marketing, _marketingConsent);
    } catch (e) {
      debugPrint('PrivacyPreferences.syncFromCloud failed: $e');
    }
  }

  Future<void> _writeLocal(String key, bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, v);
  }

  Future<void> _writeCloud() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    if (!ConnectivityService.instance.isOnline.value) return;
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('preferences')
          .doc('privacy')
          .set({
        'locationBasedRecommendations': _locationBasedRecommendations,
        'marketingConsent': _marketingConsent,
        'updatedAt': FieldValue.serverTimestamp(),
      }).timeout(_timeout);
    } catch (e) {
      debugPrint('PrivacyPreferences._writeCloud failed: $e');
    }
  }

  /// Force-push current local state to cloud. Use when reconnecting.
  Future<void> flushToCloud() => _writeCloud();

  /// Resets to defaults and removes cached values from shared_preferences.
  /// Used on logout / account deletion / UID change.
  Future<void> clearLocal() async {
    _locationBasedRecommendations = true;
    _marketingConsent = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_location);
    await prefs.remove(_marketing);
    _loaded = true;
  }
}
