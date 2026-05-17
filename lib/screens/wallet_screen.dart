import 'package:flutter/material.dart';
import '../models/card_model.dart';
import '../utils/app_colors.dart';
import '../widgets/card_widget.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_input.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key, required this.cards, required this.onChanged});
  final List<RewardCardModel> cards;
  final VoidCallback onChanged;

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final name = TextEditingController();
  final number = TextEditingController();
  final benefit = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.fromLTRB(20, 12, 20, 24), children: [
      const Text('My Wallet', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
      Text('${widget.cards.length} reward cards', style: const TextStyle(color: AppColors.text2)),
      const SizedBox(height: 18),
      for (final card in widget.cards) CardWidget(card: card, onTap: () => _showDetails(card)),
      GestureDetector(
        onTap: _showAddCard,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: AppColors.bg3, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white.withValues(alpha: .14), style: BorderStyle.solid)),
          child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_circle_outline, color: AppColors.text2), SizedBox(width: 10), Text('Add new reward card', style: TextStyle(color: AppColors.text2, fontWeight: FontWeight.w700))]),
        ),
      )
    ]);
  }

  void _showDetails(RewardCardModel card) => showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.bg2,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    builder: (_) => Padding(
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(card.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
        Text(card.category, style: const TextStyle(color: AppColors.text2)),
        const SizedBox(height: 18),
        _detail('Card number', '•••• •••• •••• ${card.lastFourDigits}'),
        _detail('Benefit', card.benefit, color: AppColors.green),
        _detail('Points balance', '${card.points} pts'),
        _detail('Supported stores', card.supportedStores.join(', ')),
        const SizedBox(height: 16),
        CustomButton(text: 'Remove Card', danger: true, onPressed: () { setState(() => widget.cards.remove(card)); widget.onChanged(); Navigator.pop(context); }),
      ]),
    ),
  );

  Widget _detail(String label, String value, {Color? color}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: const TextStyle(color: AppColors.text2)), Flexible(child: Text(value, textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.w700, color: color)))]),
  );

  void _showAddCard() => showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.bg2,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    builder: (_) => Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Add Card', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
        const SizedBox(height: 18),
        CustomInput(label: 'Card Name', hint: 'e.g. Flybuys Rewards Card', controller: name),
        CustomInput(label: 'Last 4 Digits', hint: '1234', controller: number, keyboardType: TextInputType.number),
        CustomInput(label: 'Benefit', hint: 'e.g. 3.5x points', controller: benefit),
        CustomButton(text: 'Add to Wallet', onPressed: () {
          if (name.text.trim().isEmpty) return;
          setState(() => widget.cards.add(RewardCardModel(
            id: DateTime.now().millisecondsSinceEpoch.toString(), userId: 'u1', name: name.text.trim(), lastFourDigits: number.text.padLeft(4, '0').substring(0, 4), category: 'Groceries · Retail', benefit: benefit.text.isEmpty ? 'Reward points' : benefit.text, baseRate: 2, cashbackRate: 0, points: 0, icon: '💳', gradient: AppColors.cardBlue, supportedStores: ['Coles', 'Woolworths'],
          )));
          name.clear(); number.clear(); benefit.clear(); widget.onChanged(); Navigator.pop(context);
        }),
      ]),
    ),
  );
}

