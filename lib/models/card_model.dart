import 'package:flutter/material.dart';

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
    required this.gradient,
    required this.supportedStores,
    this.bonusCategories = const [],
    this.fee = 0.0,
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
  LinearGradient gradient;
  List<String> supportedStores;
  List<String> bonusCategories;
  double fee;
}

