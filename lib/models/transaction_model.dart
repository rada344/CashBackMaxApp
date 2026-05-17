class TransactionModel {
  TransactionModel({
    required this.id,
    required this.cardId,
    required this.storeName,
    required this.category,
    required this.amount,
    required this.date,
    required this.rewardValue,
  });

  final String id;
  final String cardId;
  final String storeName;
  final String category;
  final double amount;
  final DateTime date;
  final double rewardValue;
}

