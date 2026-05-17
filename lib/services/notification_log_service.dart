import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'connectivity_service.dart';

enum NotificationType { storeAlert, recommendation, reward, security, system }

class NotificationEntry {
  NotificationEntry({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.createdAt,
    this.read = false,
  });

  final String id;
  final NotificationType type;
  final String title;
  final String message;
  final DateTime createdAt;
  bool read;

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'title': title,
        'message': message,
        'createdAt': createdAt.toIso8601String(),
        'read': read,
      };

  factory NotificationEntry.fromJson(Map<String, dynamic> json) {
    return NotificationEntry(
      id: json['id'] as String,
      type: NotificationType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => NotificationType.system,
      ),
      title: json['title'] as String,
      message: json['message'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      read: json['read'] as bool? ?? false,
    );
  }
}

/// Persisted log of triggered notifications.
///
/// Two-layer storage:
///  - Local `shared_preferences` for offline + instant startup.
///  - Firestore `users/{uid}/notifications/{entryId}` subcollection for
///    cross-device sync.
class NotificationLog {
  NotificationLog._();
  static final NotificationLog instance = NotificationLog._();

  static const _key = 'notifications.log.v1';
  static const _maxEntries = 100;

  final ValueNotifier<List<NotificationEntry>> entries = ValueNotifier(const []);

  bool _loaded = false;

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    _loaded = true;

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return;

    try {
      final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      entries.value = list.map(NotificationEntry.fromJson).toList();
    } catch (e) {
      debugPrint('NotificationLog decode failed: $e');
      entries.value = const [];
    }
  }

  int get unreadCount => entries.value.where((e) => !e.read).length;

  Future<void> add({
    required NotificationType type,
    required String title,
    required String message,
  }) async {
    final entry = NotificationEntry(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      type: type,
      title: title,
      message: message,
      createdAt: DateTime.now(),
    );
    final next = [entry, ...entries.value];
    if (next.length > _maxEntries) {
      next.removeRange(_maxEntries, next.length);
    }
    entries.value = next;
    await _persistLocal();
    await _cloudUpsert(entry);
  }

  Future<void> markAllRead() async {
    if (entries.value.every((e) => e.read)) return;
    entries.value = entries.value
        .map((e) => NotificationEntry(
              id: e.id,
              type: e.type,
              title: e.title,
              message: e.message,
              createdAt: e.createdAt,
              read: true,
            ))
        .toList();
    await _persistLocal();
    await _cloudMarkAllRead();
  }

  Future<void> clear() async {
    final ids = entries.value.map((e) => e.id).toList();
    entries.value = const [];
    await _persistLocal();
    await _cloudDeleteMany(ids);
  }

  /// Pull cloud entries and merge with local (newest-first, deduped by id).
  /// Any local-only entries are uploaded to cloud as part of merge.
  Future<void> syncFromCloud(String uid) async {
    if (uid.isEmpty) return;
    if (!ConnectivityService.instance.isOnline.value) return;
    try {
      final coll = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('notifications');
      final snap = await coll.get().timeout(_timeout);
      final remote = snap.docs
          .map((d) => NotificationEntry.fromJson(d.data()))
          .toList();

      final byId = <String, NotificationEntry>{};
      for (final e in entries.value) {
        byId[e.id] = e;
      }
      for (final e in remote) {
        byId[e.id] = e;
      }
      final merged = byId.values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      if (merged.length > _maxEntries) {
        merged.removeRange(_maxEntries, merged.length);
      }
      entries.value = merged;
      await _persistLocal();

      // Upload any local-only entries that aren't in the cloud yet.
      final remoteIds = remote.map((e) => e.id).toSet();
      for (final e in merged) {
        if (!remoteIds.contains(e.id)) {
          await _cloudUpsert(e);
        }
      }
    } catch (e) {
      debugPrint('NotificationLog.syncFromCloud failed: $e');
    }
  }

  /// Wipes the in-memory list and the shared_preferences cache.
  /// Used on logout / account deletion / UID change.
  Future<void> clearLocal() async {
    entries.value = const [];
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
    _loaded = true;
  }

  Future<void> _persistLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(entries.value.map((e) => e.toJson()).toList());
    await prefs.setString(_key, encoded);
  }

  static const _timeout = Duration(seconds: 10);

  Future<void> _cloudUpsert(NotificationEntry e) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    if (!ConnectivityService.instance.isOnline.value) return;
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('notifications')
          .doc(e.id)
          .set(e.toJson())
          .timeout(_timeout);
    } catch (err) {
      debugPrint('NotificationLog._cloudUpsert ${e.id} failed: $err');
    }
  }

  Future<void> _cloudMarkAllRead() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    if (!ConnectivityService.instance.isOnline.value) return;
    try {
      final db = FirebaseFirestore.instance;
      final coll = db.collection('users').doc(uid).collection('notifications');
      final batch = db.batch();
      for (final e in entries.value) {
        batch.set(coll.doc(e.id), e.toJson());
      }
      await batch.commit().timeout(_timeout);
    } catch (err) {
      debugPrint('NotificationLog._cloudMarkAllRead failed: $err');
    }
  }

  Future<void> _cloudDeleteMany(List<String> ids) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || ids.isEmpty) return;
    if (!ConnectivityService.instance.isOnline.value) return;
    try {
      final db = FirebaseFirestore.instance;
      final coll = db.collection('users').doc(uid).collection('notifications');
      final batch = db.batch();
      for (final id in ids) {
        batch.delete(coll.doc(id));
      }
      await batch.commit().timeout(_timeout);
    } catch (err) {
      debugPrint('NotificationLog._cloudDeleteMany failed: $err');
    }
  }
}
