import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/card_model.dart';
import '../utils/app_colors.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_input.dart';

class EditCardScreen extends StatefulWidget {
  const EditCardScreen({super.key, required this.card});

  final RewardCardModel card;

  @override
  State<EditCardScreen> createState() => _EditCardScreenState();
}

class _EditCardScreenState extends State<EditCardScreen> {
  late final name = TextEditingController(text: widget.card.name);
  late final digits = TextEditingController(text: widget.card.lastFourDigits);
  late final benefit = TextEditingController(text: widget.card.benefit);
  late final baseRate = TextEditingController(text: widget.card.baseRate.toString());
  late final cashbackRate =
      TextEditingController(text: widget.card.cashbackRate.toString());
  late final supportedStores =
      TextEditingController(text: widget.card.supportedStores.join(', '));
  late final bonusCategories =
      TextEditingController(text: widget.card.bonusCategories.join(', '));
  late final fee = TextEditingController(text: widget.card.fee.toString());
  late final discount = TextEditingController(text: widget.card.discountPercent.toString());
  late final icon = TextEditingController(text: widget.card.icon);

  late String _gradientKey = widget.card.gradientKey;
  late String _category = RewardCardModel.categories.contains(widget.card.category)
      ? widget.card.category
      : RewardCardModel.categories.last;

  @override
  void dispose() {
    name.dispose();
    digits.dispose();
    benefit.dispose();
    baseRate.dispose();
    cashbackRate.dispose();
    supportedStores.dispose();
    bonusCategories.dispose();
    fee.dispose();
    discount.dispose();
    icon.dispose();
    super.dispose();
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  void _save() {
    final n = name.text.trim();
    if (n.isEmpty) {
      _snack('Card name is required');
      return;
    }
    final d = digits.text.trim();
    if (d.length != 4 || int.tryParse(d) == null) {
      _snack('Last 4 digits must be exactly 4 numbers');
      return;
    }

    final updated = RewardCardModel(
      id: widget.card.id,
      userId: widget.card.userId,
      name: n,
      lastFourDigits: d,
      category: _category,
      benefit: benefit.text.trim().isEmpty ? widget.card.benefit : benefit.text.trim(),
      baseRate: double.tryParse(baseRate.text.trim()) ?? widget.card.baseRate,
      cashbackRate: double.tryParse(cashbackRate.text.trim()) ?? widget.card.cashbackRate,
      points: widget.card.points,
      icon: icon.text.trim().isEmpty ? widget.card.icon : icon.text.trim(),
      gradientKey: _gradientKey,
      supportedStores: _splitCsv(supportedStores.text),
      bonusCategories: _splitCsv(bonusCategories.text),
      fee: double.tryParse(fee.text.trim()) ?? widget.card.fee,
      discountPercent: double.tryParse(discount.text.trim()) ?? widget.card.discountPercent,
    );

    Navigator.pop(context, updated);
  }

  List<String> _splitCsv(String s) =>
      s.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        title: const Text('Edit Card'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          children: [
            CustomInput(label: 'Card Name', hint: 'Flybuys Rewards Card', controller: name),
            CustomInput(
              label: 'Last 4 Digits',
              hint: '1234',
              controller: digits,
              keyboardType: TextInputType.number,
              maxLength: 4,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(4),
              ],
            ),
            const _Label('CATEGORY'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final cat in RewardCardModel.categories)
                  ChoiceChip(
                    label: Text(cat),
                    selected: _category == cat,
                    onSelected: (_) => setState(() => _category = cat),
                    selectedColor: AppColors.accent.withValues(alpha: .25),
                    backgroundColor: AppColors.bg3,
                    labelStyle: TextStyle(
                      color: _category == cat ? AppColors.accent2 : AppColors.text2,
                      fontWeight: FontWeight.w700,
                    ),
                    side: BorderSide(
                      color: _category == cat
                          ? AppColors.accent.withValues(alpha: .5)
                          : Colors.white.withValues(alpha: .08),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            CustomInput(label: 'Benefit', hint: '3.5x points', controller: benefit),
            CustomInput(
              label: 'Icon (emoji)',
              hint: '⭐',
              controller: icon,
            ),
            const _Label('CARD COLOUR'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              children: RewardCardModel.gradientKeys.map((key) {
                final selected = key == _gradientKey;
                return GestureDetector(
                  onTap: () => setState(() => _gradientKey = key),
                  child: Container(
                    width: 64,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: RewardCardModel(
                        id: '', userId: '', name: '', lastFourDigits: '', category: '',
                        benefit: '', baseRate: 0, cashbackRate: 0, points: 0,
                        icon: '', gradientKey: key, supportedStores: const [],
                      ).gradient,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selected ? Colors.white : Colors.white.withValues(alpha: .12),
                        width: selected ? 2 : 1,
                      ),
                    ),
                    child: selected
                        ? const Icon(Icons.check, color: Colors.white)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            CustomInput(
              label: 'Base Rate (pts/\$)',
              hint: '3.5',
              controller: baseRate,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            CustomInput(
              label: 'Cashback Rate (0-1)',
              hint: '0.05',
              controller: cashbackRate,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            CustomInput(
              label: 'Annual Fee (\$)',
              hint: '0',
              controller: fee,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            CustomInput(
              label: 'Discount at supported stores (%)',
              hint: '5',
              controller: discount,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            CustomInput(
              label: 'Supported Stores (comma-separated)',
              hint: 'Woolworths, BWS',
              controller: supportedStores,
            ),
            CustomInput(
              label: 'Bonus Categories (comma-separated)',
              hint: 'Groceries, Fuel',
              controller: bonusCategories,
            ),
            const SizedBox(height: 8),
            CustomButton(text: 'Save Changes', onPressed: _save),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          color: AppColors.text2,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: .8,
        ),
      );
}
