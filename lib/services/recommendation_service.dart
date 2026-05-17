import '../models/card_model.dart';

class RecommendationResult {
  RecommendationResult({
    required this.card,
    required this.score,
    required this.reason,
    required this.pointsValue,
    required this.cashbackValue,
    required this.bonusValue,
    required this.fees,
  });

  final RewardCardModel card;
  final double score;
  final String reason;
  final double pointsValue;
  final double cashbackValue;
  final double bonusValue;
  final double fees;
}

class RecommendationService {
  // Project assumption: 1000 points = $5, therefore 1 point = $0.005.
  static const double pointDollarValue = 0.005;

  double convertPointsToDollar(double points) => points * pointDollarValue;

  double calculateScore({
    required RewardCardModel card,
    required double amount,
    required String category,
    required String store,
  }) {
    final basePoints = card.baseRate * amount;
    final storeBonusPoints = card.supportedStores.any((s) => store.toLowerCase().contains(s.toLowerCase())) ? 600.0 : 0.0;
    final categoryBonusPoints = card.bonusCategories.any((c) => category.toLowerCase().contains(c.toLowerCase())) ? 400.0 : 0.0;
    final bonusPoints = storeBonusPoints + categoryBonusPoints;
    final pointsValue = convertPointsToDollar(basePoints + bonusPoints);
    final cashbackValue = card.cashbackRate * amount;
    return pointsValue + cashbackValue - card.fee;
  }

  RecommendationResult analyseCard({
    required RewardCardModel card,
    required double amount,
    required String category,
    required String store,
  }) {
    final basePoints = card.baseRate * amount;
    final storeBonusPoints = card.supportedStores.any((s) => store.toLowerCase().contains(s.toLowerCase())) ? 600.0 : 0.0;
    final categoryBonusPoints = card.bonusCategories.any((c) => category.toLowerCase().contains(c.toLowerCase())) ? 400.0 : 0.0;
    final bonusPoints = storeBonusPoints + categoryBonusPoints;
    final pointsValue = convertPointsToDollar(basePoints + bonusPoints);
    final cashbackValue = card.cashbackRate * amount;
    final score = pointsValue + cashbackValue - card.fee;

    return RecommendationResult(
      card: card,
      score: score,
      pointsValue: pointsValue,
      cashbackValue: cashbackValue,
      bonusValue: convertPointsToDollar(bonusPoints),
      fees: card.fee,
      reason: 'Best estimated usable value at $store for ${category.toLowerCase()} spending.',
    );
  }

  RecommendationResult recommend(
    List<RewardCardModel> cards, {
    String store = 'Woolworths',
    String category = 'Groceries',
    double amount = 100,
  }) {
    if (cards.isEmpty) {
      throw StateError('No reward cards available for recommendation.');
    }

    final scored = cards
        .map((card) => analyseCard(card: card, amount: amount, category: category, store: store))
        .toList()
      ..sort((a, b) => b.score.compareTo(a.score));

    return scored.first;
  }
}

