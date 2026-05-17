import 'package:flutter/material.dart';
import '../models/card_model.dart';

class CardWidget extends StatelessWidget {
  const CardWidget({super.key, required this.card, this.onTap});
  final RewardCardModel card;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        height: 168,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: card.gradient,
          borderRadius: BorderRadius.circular(26),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .35), blurRadius: 24, offset: const Offset(0, 12))],
        ),
        child: Stack(children: [
          Positioned(right: -14, top: -14, child: Text(card.icon, style: const TextStyle(fontSize: 76))),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(width: 42, height: 30, decoration: BoxDecoration(color: Colors.white.withValues(alpha: .25), borderRadius: BorderRadius.circular(8))),
            const Spacer(),
            Text('•••• •••• •••• ${card.lastFourDigits}', style: TextStyle(color: Colors.white.withValues(alpha: .75), letterSpacing: 2)),
            const SizedBox(height: 8),
            Text(card.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 17)),
            Text(card.category, style: TextStyle(color: Colors.white.withValues(alpha: .7), fontSize: 12)),
          ]),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: Colors.black.withValues(alpha: .25), borderRadius: BorderRadius.circular(99)),
              child: Text(card.benefit, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
            ),
          ),
        ]),
      ),
    );
  }
}

