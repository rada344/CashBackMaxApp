import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class RewardCardModel {
  RewardCardModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.lastFourDigits,
    required this.category,
    required this.benefit,
    required this.baseRate,
    required this.cashbackRate,
    required this.points,
    required this.icon,
    required this.gradientKey,
    required this.supportedStores,
    this.bonusCategories = const [],
    this.fee = 0.0,
    this.discountPercent = 0.0,
  });

  final String id;
  final String userId;
  String name;
  String lastFourDigits;
  String category;
  String benefit;
  double baseRate;
  double cashbackRate;
  int points;
  String icon;
  String gradientKey;
  List<String> supportedStores;
  List<String> bonusCategories;
  double fee;

  /// Percentage discount (0–100) applied to the purchase amount at any of
  /// the [supportedStores]. Used by the recommendation engine to compare
  /// cards beyond points + cashback.
  double discountPercent;

  LinearGradient get gradient => _gradients[gradientKey] ?? AppColors.cardBlue;

  static const List<String> gradientKeys = ['green', 'purple', 'amber', 'blue'];

  static const List<String> categories = [
    'Groceries',
    'Fuel',
    'Retail',
    'Dining',
    'Travel',
    'Entertainment',
    'Other',
  ];

  static const Map<String, LinearGradient> _gradients = {
    'green': AppColors.cardGreen,
    'purple': AppColors.cardPurple,
    'amber': AppColors.cardAmber,
    'blue': AppColors.cardBlue,
  };

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'name': name,
        'lastFourDigits': lastFourDigits,
        'category': category,
        'benefit': benefit,
        'baseRate': baseRate,
        'cashbackRate': cashbackRate,
        'points': points,
        'icon': icon,
        'gradientKey': gradientKey,
        'supportedStores': supportedStores,
        'bonusCategories': bonusCategories,
        'fee': fee,
        'discountPercent': discountPercent,
      };

  factory RewardCardModel.fromJson(Map<String, dynamic> json) => RewardCardModel(
        id: json['id'] as String,
        userId: json['userId'] as String,
        name: json['name'] as String,
        lastFourDigits: json['lastFourDigits'] as String,
        category: json['category'] as String,
        benefit: json['benefit'] as String,
        baseRate: (json['baseRate'] as num).toDouble(),
        cashbackRate: (json['cashbackRate'] as num).toDouble(),
        points: (json['points'] as num).toInt(),
        icon: json['icon'] as String,
        gradientKey: json['gradientKey'] as String? ?? 'blue',
        supportedStores: List<String>.from(json['supportedStores'] as List? ?? []),
        bonusCategories: List<String>.from(json['bonusCategories'] as List? ?? []),
        fee: (json['fee'] as num?)?.toDouble() ?? 0.0,
        discountPercent: (json['discountPercent'] as num?)?.toDouble() ?? 0.0,
      );
}
