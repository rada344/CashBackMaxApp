import 'package:flutter/material.dart';

import '../models/card_model.dart';
import '../services/recommendation_service.dart';
import '../utils/app_colors.dart';

class CardComparisonScreen extends StatelessWidget {
  const CardComparisonScreen({
    super.key,
    required this.cards,
    required this.store,
    required this.category,
    required this.amount,
  });

  final List<RewardCardModel> cards;
  final String store;
  final String category;
  final double amount;

  @override
  Widget build(BuildContext context) {
    final ranked = RecommendationService().rank(
      cards,
      store: store,
      category: category,
      amount: amount,
    );

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        title: const Text(
          'Compare Cards',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.bg2,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.shopping_bag_outlined, color: AppColors.accent2, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        store,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppColors.text,
                        ),
                      ),
                      Text(
                        '$category · \$${amount.toStringAsFixed(0)} spend',
                        style: const TextStyle(
                          color: AppColors.text2,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          if (ranked.isEmpty)
            const _EmptyState()
          else
            for (var i = 0; i < ranked.length; i++)
              _ComparisonRow(rank: i + 1, result: ranked[i]),
        ],
      ),
    );
  }
}

class _ComparisonRow extends StatelessWidget {
  const _ComparisonRow({required this.rank, required this.result});

  final int rank;
  final RecommendationResult result;

  @override
  Widget build(BuildContext context) {
    final isWinner = rank == 1;
    final card = result.card;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: card.gradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .25),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
        border: isWinner
            ? Border.all(color: Colors.white.withValues(alpha: .85), width: 2)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: .25),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  isWinner ? '👑 #$rank' : '#$rank',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
              const Spacer(),
              Text(card.icon, style: const TextStyle(fontSize: 26)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            card.name,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 17,
            ),
          ),
          Text(
            '•••• ${card.lastFourDigits} · ${card.category}',
            style: TextStyle(
              color: Colors.white.withValues(alpha: .75),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: .3),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                _ScoreRow(
                  label: 'Total value',
                  value: result.score,
                  bold: true,
                ),
                const Divider(color: Colors.white24, height: 18),
                _ScoreRow(label: 'Points', value: result.pointsValue),
                _ScoreRow(label: 'Cashback', value: result.cashbackValue),
                _ScoreRow(label: 'Discount', value: result.discountValue),
                _ScoreRow(label: 'Store bonus', value: result.bonusValue),
                if (result.fees > 0)
                  _ScoreRow(label: 'Fees', value: -result.fees),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreRow extends StatelessWidget {
  const _ScoreRow({required this.label, required this.value, this.bold = false});

  final String label;
  final double value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final negative = value < 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: bold ? 1 : .8),
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
              fontSize: bold ? 14 : 13,
            ),
          ),
          const Spacer(),
          Text(
            '${negative ? '-' : ''}\$${value.abs().toStringAsFixed(2)}',
            style: TextStyle(
              color: Colors.white,
              fontWeight: bold ? FontWeight.w900 : FontWeight.w700,
              fontSize: bold ? 15 : 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.bg2,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Column(
        children: [
          Icon(Icons.credit_card_off_rounded, color: AppColors.text3, size: 40),
          SizedBox(height: 12),
          Text(
            'No cards to compare yet.',
            style: TextStyle(color: AppColors.text2, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 4),
          Text(
            'Add cards in your wallet to see the ranking.',
            style: TextStyle(color: AppColors.text3, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
