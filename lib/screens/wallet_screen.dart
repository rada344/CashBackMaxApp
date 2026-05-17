import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/card_model.dart';
import '../services/database_service.dart';
import '../services/notification_log_service.dart';
import '../utils/app_colors.dart';
import '../widgets/card_widget.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_input.dart';
import 'edit_card_screen.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({
    super.key,
    required this.cards,
    required this.userId,
    required this.onChanged,
  });
  final List<RewardCardModel> cards;
  final String userId;
  final VoidCallback onChanged;

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final name = TextEditingController();
  final number = TextEditingController();
  final benefit = TextEditingController();

  final DatabaseService _db = DatabaseService.instance;
  final NotificationLog _log = NotificationLog.instance;

  @override
  void dispose() {
    name.dispose();
    number.dispose();
    benefit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.fromLTRB(20, 12, 20, 24), children: [
      const Text('My Wallet', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
      Text('${widget.cards.length} reward cards', style: const TextStyle(color: AppColors.text2)),
      const SizedBox(height: 18),
      for (final card in widget.cards)
        CardWidget(card: card, onTap: () => _showDetails(card)),
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
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        builder: (sheetCtx) => Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(card.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
            Text(card.category, style: const TextStyle(color: AppColors.text2)),
            const SizedBox(height: 18),
            _detail('Card number', '•••• •••• •••• ${card.lastFourDigits}'),
            _detail('Benefit', card.benefit, color: AppColors.green),
            _detail('Points balance', '${card.points} pts'),
            _detail('Supported stores', card.supportedStores.join(', ')),
            const SizedBox(height: 16),
            CustomButton(
              text: 'Edit Card',
              onPressed: () {
                Navigator.pop(sheetCtx);
                _openEdit(card);
              },
            ),
            const SizedBox(height: 10),
            CustomButton(
              text: 'Remove Card',
              danger: true,
              onPressed: () async {
                final navigator = Navigator.of(sheetCtx);
                final messenger = ScaffoldMessenger.of(context);
                await _db.deleteCard(card.id);
                if (!mounted) return;
                setState(() => widget.cards.remove(card));
                widget.onChanged();
                navigator.pop();
                await _log.add(
                  type: NotificationType.system,
                  title: 'Card removed · ${card.name}',
                  message: '•••• ${card.lastFourDigits} was deleted from your wallet.',
                );
                messenger
                  ..hideCurrentSnackBar()
                  ..showSnackBar(SnackBar(
                    content: Text('${card.name} removed'),
                  ));
              },
            ),
          ]),
          ),
        ),
      );

  Future<void> _openEdit(RewardCardModel card) async {
    final messenger = ScaffoldMessenger.of(context);
    final updated = await Navigator.push<RewardCardModel>(
      context,
      MaterialPageRoute(builder: (_) => EditCardScreen(card: card)),
    );
    if (updated == null) return;
    await _db.updateCard(updated);
    if (!mounted) return;
    setState(() {
      final i = widget.cards.indexWhere((c) => c.id == updated.id);
      if (i != -1) widget.cards[i] = updated;
    });
    widget.onChanged();
    await _log.add(
      type: NotificationType.system,
      title: 'Card updated · ${updated.name}',
      message: '${updated.category} • •••• ${updated.lastFourDigits}',
    );
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text('${updated.name} updated'),
        backgroundColor: AppColors.green.withValues(alpha: .9),
      ));
  }

  Widget _detail(String label, String value, {Color? color}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: const TextStyle(color: AppColors.text2)), Flexible(child: Text(value, textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.w700, color: color)))]),
      );

  void _showAddCard() {
    // Hoisted OUT of StatefulBuilder so chips + loader survive rebuilds.
    bool adding = false;
    String selectedCategory = RewardCardModel.categories.first;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bg2,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (sheetCtx) => Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(sheetCtx).viewInsets.bottom + 24),
        child: StatefulBuilder(
          builder: (innerCtx, setSheetState) {

              Future<void> submit() async {
                final navigator = Navigator.of(sheetCtx);
                final messenger = ScaffoldMessenger.of(innerCtx);
                final outerMessenger = ScaffoldMessenger.of(context);
                final n = name.text.trim();
                if (n.isEmpty) {
                  messenger
                    ..hideCurrentSnackBar()
                    ..showSnackBar(const SnackBar(content: Text('Card name is required')));
                  return;
                }
                final last4 = number.text.trim();
                if (last4.length != 4 || int.tryParse(last4) == null) {
                  messenger
                    ..hideCurrentSnackBar()
                    ..showSnackBar(const SnackBar(
                      content: Text('Last 4 digits must be exactly 4 numbers'),
                    ));
                  return;
                }

                setSheetState(() => adding = true);
                try {
                  final card = RewardCardModel(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    userId: widget.userId,
                    name: n,
                    lastFourDigits: last4,
                    category: selectedCategory,
                    benefit: benefit.text.trim().isEmpty ? 'Reward points' : benefit.text.trim(),
                    baseRate: 2,
                    cashbackRate: 0,
                    points: 0,
                    icon: '💳',
                    gradientKey: 'blue',
                    supportedStores: const ['Coles', 'Woolworths'],
                  );
                  await _db.addCard(card);
                  if (!mounted) return;
                  setState(() => widget.cards.add(card));
                  name.clear();
                  number.clear();
                  benefit.clear();
                  widget.onChanged();
                  navigator.pop();
                  await _log.add(
                    type: NotificationType.reward,
                    title: 'Card added · ${card.name}',
                    message:
                        '${card.category} • •••• ${card.lastFourDigits} • ${card.benefit}',
                  );
                  outerMessenger
                    ..hideCurrentSnackBar()
                    ..showSnackBar(SnackBar(
                      content: Text('${card.name} added to wallet'),
                      backgroundColor: AppColors.green.withValues(alpha: .9),
                    ));
                } catch (e) {
                  setSheetState(() => adding = false);
                  if (!mounted) return;
                  messenger
                    ..hideCurrentSnackBar()
                    ..showSnackBar(SnackBar(content: Text('Failed to add card: $e')));
                }
              }

              return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Add Card', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                const SizedBox(height: 18),
                CustomInput(label: 'Card Name', hint: 'e.g. Flybuys Rewards Card', controller: name),
                CustomInput(
                  label: 'Last 4 Digits',
                  hint: '1234',
                  controller: number,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                ),
                CustomInput(label: 'Benefit', hint: 'e.g. 3.5x points', controller: benefit),
                const Text(
                  'CATEGORY',
                  style: TextStyle(
                    color: AppColors.text2,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: .8,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final cat in RewardCardModel.categories)
                      ChoiceChip(
                        label: Text(cat),
                        selected: selectedCategory == cat,
                        onSelected: (_) => setSheetState(() => selectedCategory = cat),
                        selectedColor: AppColors.accent.withValues(alpha: .25),
                        backgroundColor: AppColors.bg3,
                        labelStyle: TextStyle(
                          color: selectedCategory == cat ? AppColors.accent2 : AppColors.text2,
                          fontWeight: FontWeight.w700,
                        ),
                        side: BorderSide(
                          color: selectedCategory == cat
                              ? AppColors.accent.withValues(alpha: .5)
                              : Colors.white.withValues(alpha: .08),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                CustomButton(
                  text: adding ? 'Adding…' : 'Add to Wallet',
                  loading: adding,
                  onPressed: submit,
                ),
              ]);
          },
        ),
      ),
    );
  }
}
