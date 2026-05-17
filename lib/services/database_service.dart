import '../models/card_model.dart';
import '../models/transaction_model.dart';
import '../utils/app_colors.dart';

class DatabaseService {
  final List<RewardCardModel> _cards = [
    RewardCardModel(
      id: 'c1', userId: 'u1', name: 'Everyday Rewards Card', lastFourDigits: '4412',
      category: 'Groceries · Retail', benefit: '4x points · 5% cashback', baseRate: 4, cashbackRate: 0.05,
      points: 850, icon: '🛒', gradient: AppColors.cardGreen, supportedStores: ['Woolworths', 'BWS'], bonusCategories: ['Groceries', 'Retail'],
    ),
    RewardCardModel(
      id: 'c2', userId: 'u1', name: 'Flybuys Rewards Card', lastFourDigits: '8821',
      category: 'Groceries · Fuel', benefit: '3.5x points', baseRate: 3.5, cashbackRate: 0.0,
      points: 250, icon: '⭐', gradient: AppColors.cardPurple, supportedStores: ['Coles', 'Kmart', 'Target'], bonusCategories: ['Groceries', 'Fuel'],
    ),
    RewardCardModel(
      id: 'c3', userId: 'u1', name: 'NRMA Fuel Discount', lastFourDigits: '2293',
      category: 'Fuel · Transport', benefit: '12¢/L discount', baseRate: 1.2, cashbackRate: 0.0,
      points: 140, icon: '⛽', gradient: AppColors.cardAmber, supportedStores: ['Caltex', 'BP'], bonusCategories: ['Fuel'],
    ),
  ];

  final List<TransactionModel> transactions = [
    TransactionModel(id: 't1', cardId: 'c1', storeName: 'Woolworths', category: 'Groceries', amount: 86.50, date: DateTime.now().subtract(const Duration(hours: 2)), rewardValue: 5.20),
    TransactionModel(id: 't2', cardId: 'c2', storeName: 'Coles', category: 'Groceries', amount: 44.20, date: DateTime.now().subtract(const Duration(days: 1)), rewardValue: 2.10),
  ];

  List<RewardCardModel> getCards(String userId) =>
    _cards.where((c) => c.userId == userId).toList();

List<RewardCardModel> getDefaultCards() => _cards;

void addCard(RewardCardModel card) => _cards.add(card);

void deleteCard(String id) => _cards.removeWhere((c) => c.id == id);
}

