import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/card_model.dart';
import 'connectivity_service.dart';

/// Mirrors wallet writes to Firestore at users/{uid}/cards/{cardId}.
/// All methods are best-effort: failures are logged but never thrown to the
/// caller, so a misconfigured Firebase project does not break local wallet ops.
/// Skips cloud calls entirely when offline so awaits don't hang.
class CardSyncService {
  CardSyncService({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  static const _timeout = Duration(seconds: 10);

  Future<void> upsert(RewardCardModel card) async {
    if (card.userId.isEmpty) return;
    if (!ConnectivityService.instance.isOnline.value) {
      debugPrint('CardSync.upsert ${card.id} skipped: offline');
      return;
    }
    try {
      await _db
          .collection('users')
          .doc(card.userId)
          .collection('cards')
          .doc(card.id)
          .set(card.toJson())
          .timeout(_timeout);
    } catch (e) {
      debugPrint('CardSync.upsert failed for ${card.id}: $e');
    }
  }

  Future<void> delete(String userId, String cardId) async {
    if (userId.isEmpty) return;
    if (!ConnectivityService.instance.isOnline.value) {
      debugPrint('CardSync.delete $cardId skipped: offline');
      return;
    }
    try {
      await _db
          .collection('users')
          .doc(userId)
          .collection('cards')
          .doc(cardId)
          .delete()
          .timeout(_timeout);
    } catch (e) {
      debugPrint('CardSync.delete failed for $cardId: $e');
    }
  }

  Future<List<RewardCardModel>> fetchAll(String userId) async {
    if (userId.isEmpty) return const [];
    if (!ConnectivityService.instance.isOnline.value) return const [];
    try {
      final snap = await _db
          .collection('users')
          .doc(userId)
          .collection('cards')
          .get()
          .timeout(_timeout);
      return snap.docs.map((d) => RewardCardModel.fromJson(d.data())).toList();
    } catch (e) {
      debugPrint('CardSync.fetchAll failed: $e');
      return const [];
    }
  }
}
