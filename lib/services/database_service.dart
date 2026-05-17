import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/card_model.dart';
import '../models/transaction_model.dart';
import 'card_sync_service.dart';

class DatabaseService {
  DatabaseService._();
  static final DatabaseService instance = DatabaseService._();

  static const _cardsKey = 'wallet.cards.v1';

  final List<RewardCardModel> _cards = [];
  final CardSyncService _sync = CardSyncService();

  final List<TransactionModel> transactions = [
    TransactionModel(id: 't1', cardId: 'c1', storeName: 'Woolworths', category: 'Groceries', amount: 86.50, date: DateTime.now().subtract(const Duration(hours: 2)), rewardValue: 5.20),
    TransactionModel(id: 't2', cardId: 'c2', storeName: 'Coles', category: 'Groceries', amount: 44.20, date: DateTime.now().subtract(const Duration(days: 1)), rewardValue: 2.10),
  ];

  bool _loaded = false;

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    _loaded = true;

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cardsKey);

    if (raw == null) return;

    try {
      final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      _cards
        ..clear()
        ..addAll(list.map(RewardCardModel.fromJson));
    } catch (e) {
      debugPrint('Failed to decode saved cards: $e — starting empty');
      _cards.clear();
      await _persist();
    }
  }

  List<RewardCardModel> getCards(String userId) =>
      _cards.where((c) => c.userId == userId).toList();

  /// Creates starter cards for [userId] if they have no cards yet.
  /// Returns the user's resulting card list.
  Future<List<RewardCardModel>> seedDefaultsForUser(String userId) async {
    if (userId.isEmpty) return const [];
    final existing = getCards(userId);
    if (existing.isNotEmpty) return existing;

    final stamp = DateTime.now().millisecondsSinceEpoch;
    final seeds = _defaultSeed();
    for (var i = 0; i < seeds.length; i++) {
      final s = seeds[i];
      final clone = RewardCardModel(
        id: '${stamp}_$i',
        userId: userId,
        name: s.name,
        lastFourDigits: s.lastFourDigits,
        category: s.category,
        benefit: s.benefit,
        baseRate: s.baseRate,
        cashbackRate: s.cashbackRate,
        points: s.points,
        icon: s.icon,
        gradientKey: s.gradientKey,
        supportedStores: List.of(s.supportedStores),
        bonusCategories: List.of(s.bonusCategories),
        fee: s.fee,
      );
      _cards.add(clone);
      await _sync.upsert(clone);
    }
    await _persist();
    return getCards(userId);
  }

  Future<void> addCard(RewardCardModel card) async {
    _cards.add(card);
    await _persist();
    await _sync.upsert(card);
  }

  Future<void> updateCard(RewardCardModel card) async {
    final i = _cards.indexWhere((c) => c.id == card.id);
    if (i == -1) return;
    _cards[i] = card;
    await _persist();
    await _sync.upsert(card);
  }

  Future<void> deleteCard(String id) async {
    final card = _cards.firstWhere(
      (c) => c.id == id,
      orElse: () => RewardCardModel(
        id: '', userId: '', name: '', lastFourDigits: '', category: '',
        benefit: '', baseRate: 0, cashbackRate: 0, points: 0,
        icon: '', gradientKey: 'blue', supportedStores: const [],
      ),
    );
    _cards.removeWhere((c) => c.id == id);
    await _persist();
    if (card.id.isNotEmpty) {
      await _sync.delete(card.userId, id);
    }
  }

  /// Wipes the in-memory wallet and the shared_preferences cache.
  /// Used on logout / account deletion / UID change.
  Future<void> clearLocal() async {
    _cards.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cardsKey);
    _loaded = true;
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(_cards.map((c) => c.toJson()).toList());
    await prefs.setString(_cardsKey, encoded);
  }

  /// Pulls cloud cards for [userId], merges them with local cache, and pushes
  /// any local-only entries back to the cloud (so cards added while offline
  /// don't stay stranded). Best-effort: silently no-ops on errors.
  Future<void> mergeRemoteCards(String userId) async {
    if (userId.isEmpty) return;
    final remote = await _sync.fetchAll(userId);

    final byId = {for (final c in _cards) c.id: c};
    final remoteIds = <String>{};
    for (final r in remote) {
      byId[r.id] = r;
      remoteIds.add(r.id);
    }
    _cards
      ..clear()
      ..addAll(byId.values);
    await _persist();

    // Upload local-only cards belonging to this user.
    for (final c in _cards) {
      if (c.userId == userId && !remoteIds.contains(c.id)) {
        await _sync.upsert(c);
      }
    }
  }

  List<RewardCardModel> _defaultSeed() => [
        RewardCardModel(
          id: 'c1', userId: 'u1', name: 'Everyday Rewards Card', lastFourDigits: '4412',
          category: 'Groceries · Retail', benefit: '4x points · 5% cashback', baseRate: 4, cashbackRate: 0.05,
          points: 850, icon: '🛒', gradientKey: 'green', supportedStores: const ['Woolworths', 'BWS'], bonusCategories: const ['Groceries', 'Retail'],
        ),
        RewardCardModel(
          id: 'c2', userId: 'u1', name: 'Flybuys Rewards Card', lastFourDigits: '8821',
          category: 'Groceries · Fuel', benefit: '3.5x points', baseRate: 3.5, cashbackRate: 0.0,
          points: 250, icon: '⭐', gradientKey: 'purple', supportedStores: const ['Coles', 'Kmart', 'Target'], bonusCategories: const ['Groceries', 'Fuel'],
        ),
        RewardCardModel(
          id: 'c3', userId: 'u1', name: 'NRMA Fuel Discount', lastFourDigits: '2293',
          category: 'Fuel · Transport', benefit: '12¢/L discount', baseRate: 1.2, cashbackRate: 0.0,
          points: 140, icon: '⛽', gradientKey: 'amber', supportedStores: const ['Caltex', 'BP'], bonusCategories: const ['Fuel'],
        ),
      ];
}

