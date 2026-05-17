import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'connectivity_service.dart';

/// Persisted notification toggles.
///
/// Two-layer storage:
///  - Local `shared_preferences` for offline + instant startup.
///  - Firestore `users/{uid}/preferences/notifications` doc for cross-device.
class NotificationPreferences {
  NotificationPreferences._();
  static final NotificationPreferences instance = NotificationPreferences._();

  static const _smart = 'notif.smartAlerts';
  static const _storeEntry = 'notif.storeEntryAlerts';
  static const _rewardOffers = 'notif.rewardOfferAlerts';
  static const _cashback = 'notif.cashbackAlerts';
  static const _expiry = 'notif.expiryAlerts';
  static const _sound = 'notif.sound';
  static const _vibration = 'notif.vibration';

  bool _smartAlerts = true;
  bool _storeEntryAlerts = true;
  bool _rewardOfferAlerts = true;
  bool _cashbackAlerts = true;
  bool _expiryAlerts = true;
  bool _soundEnabled = false;
  bool _vibrationEnabled = true;

  bool _loaded = false;

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    _loaded = true;
    final prefs = await SharedPreferences.getInstance();
    _smartAlerts = prefs.getBool(_smart) ?? _smartAlerts;
    _storeEntryAlerts = prefs.getBool(_storeEntry) ?? _storeEntryAlerts;
    _rewardOfferAlerts = prefs.getBool(_rewardOffers) ?? _rewardOfferAlerts;
    _cashbackAlerts = prefs.getBool(_cashback) ?? _cashbackAlerts;
    _expiryAlerts = prefs.getBool(_expiry) ?? _expiryAlerts;
    _soundEnabled = prefs.getBool(_sound) ?? _soundEnabled;
    _vibrationEnabled = prefs.getBool(_vibration) ?? _vibrationEnabled;
  }

  bool get smartAlerts => _smartAlerts;
  bool get storeEntryAlerts => _storeEntryAlerts;
  bool get rewardOfferAlerts => _rewardOfferAlerts;
  bool get cashbackAlerts => _cashbackAlerts;
  bool get expiryAlerts => _expiryAlerts;
  bool get soundEnabled => _soundEnabled;
  bool get vibrationEnabled => _vibrationEnabled;

  Future<void> setSmartAlerts(bool v) async {
    _smartAlerts = v;
    await _writeLocal(_smart, v);
    await _writeCloud();
  }

  Future<void> setStoreEntryAlerts(bool v) async {
    _storeEntryAlerts = v;
    await _writeLocal(_storeEntry, v);
    await _writeCloud();
  }

  Future<void> setRewardOfferAlerts(bool v) async {
    _rewardOfferAlerts = v;
    await _writeLocal(_rewardOffers, v);
    await _writeCloud();
  }

  Future<void> setCashbackAlerts(bool v) async {
    _cashbackAlerts = v;
    await _writeLocal(_cashback, v);
    await _writeCloud();
  }

  Future<void> setExpiryAlerts(bool v) async {
    _expiryAlerts = v;
    await _writeLocal(_expiry, v);
    await _writeCloud();
  }

  Future<void> setSoundEnabled(bool v) async {
    _soundEnabled = v;
    await _writeLocal(_sound, v);
    await _writeCloud();
  }

  Future<void> setVibrationEnabled(bool v) async {
    _vibrationEnabled = v;
    await _writeLocal(_vibration, v);
    await _writeCloud();
  }

  bool shouldShowStoreAlert() => _smartAlerts && _storeEntryAlerts;

  /// Pulls the cloud doc for [uid] into local state, or seeds the cloud doc
  /// from current local values if no doc exists. Best-effort.
  static const _timeout = Duration(seconds: 10);

  Future<void> syncFromCloud(String uid) async {
    if (uid.isEmpty) return;
    if (!ConnectivityService.instance.isOnline.value) return;
    try {
      final ref = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('preferences')
          .doc('notifications');
      final snap = await ref.get().timeout(_timeout);
      if (!snap.exists) {
        await _writeCloud();
        return;
      }
      final data = snap.data()!;
      _smartAlerts = data['smartAlerts'] as bool? ?? _smartAlerts;
      _storeEntryAlerts = data['storeEntryAlerts'] as bool? ?? _storeEntryAlerts;
      _rewardOfferAlerts = data['rewardOfferAlerts'] as bool? ?? _rewardOfferAlerts;
      _cashbackAlerts = data['cashbackAlerts'] as bool? ?? _cashbackAlerts;
      _expiryAlerts = data['expiryAlerts'] as bool? ?? _expiryAlerts;
      _soundEnabled = data['soundEnabled'] as bool? ?? _soundEnabled;
      _vibrationEnabled = data['vibrationEnabled'] as bool? ?? _vibrationEnabled;
      // Sync local cache to match cloud
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_smart, _smartAlerts);
      await prefs.setBool(_storeEntry, _storeEntryAlerts);
      await prefs.setBool(_rewardOffers, _rewardOfferAlerts);
      await prefs.setBool(_cashback, _cashbackAlerts);
      await prefs.setBool(_expiry, _expiryAlerts);
      await prefs.setBool(_sound, _soundEnabled);
      await prefs.setBool(_vibration, _vibrationEnabled);
    } catch (e) {
      debugPrint('NotificationPreferences.syncFromCloud failed: $e');
    }
  }

  /// Resets to defaults and removes cached values from shared_preferences.
  /// Used on logout / account deletion / UID change.
  Future<void> clearLocal() async {
    _smartAlerts = true;
    _storeEntryAlerts = true;
    _rewardOfferAlerts = true;
    _cashbackAlerts = true;
    _expiryAlerts = true;
    _soundEnabled = false;
    _vibrationEnabled = true;
    final prefs = await SharedPreferences.getInstance();
    for (final key in [
      _smart, _storeEntry, _rewardOffers, _cashback, _expiry, _sound, _vibration,
    ]) {
      await prefs.remove(key);
    }
    _loaded = true;
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
          .doc('notifications')
          .set({
        'smartAlerts': _smartAlerts,
        'storeEntryAlerts': _storeEntryAlerts,
        'rewardOfferAlerts': _rewardOfferAlerts,
        'cashbackAlerts': _cashbackAlerts,
        'expiryAlerts': _expiryAlerts,
        'soundEnabled': _soundEnabled,
        'vibrationEnabled': _vibrationEnabled,
        'updatedAt': FieldValue.serverTimestamp(),
      }).timeout(_timeout);
    } catch (e) {
      debugPrint('NotificationPreferences._writeCloud failed: $e');
    }
  }

  /// Force-push current local state to cloud. Use when reconnecting.
  Future<void> flushToCloud() => _writeCloud();
}
