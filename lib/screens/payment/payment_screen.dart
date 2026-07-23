import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_colors.dart';
import '../../widgets/status_bar.dart';
import '../../services/mock/rewards_repository.dart';
import 'offers_screen.dart';

const _ink = Color(0xFF0A0F2C);
const _grey = Color(0xFF808080);
const _fieldBg = Color(0xFFF5F6FA);

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool _editing = false;
  String? _toast;
  Timer? _toastTimer;

  @override
  void dispose() {
    _toastTimer?.cancel();
    super.dispose();
  }

  void _showToast(String msg) {
    setState(() => _toast = msg);
    _toastTimer?.cancel();
    _toastTimer = Timer(const Duration(milliseconds: 1600), () {
      if (mounted) setState(() => _toast = null);
    });
  }

  Future<void> _addCard() async {
    final added = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const AddCardScreen()),
    );
    if (added == true) _showToast('Card added');
  }

  Future<void> _deleteCard(SavedCard c) async {
    final ok = await showDialog<bool>(context: context, builder: (_) => const _DeleteCardDialog());
    if (ok == true) {
      PaymentStore.instance.removeCard(c);
      _showToast('Card removed');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            Column(
              children: [
                const StatusBar(),
                _Header(title: 'Payment', onClose: () => Navigator.of(context).maybePop()),
                Expanded(
                  child: ListenableBuilder(
                    listenable: PaymentStore.instance,
                    builder: (context, _) {
                      final store = PaymentStore.instance;
                      return SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(24, 8, 24, 120),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Expanded(
                                  child: Text('Payment methods',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.black)),
                                ),
                                InkWell(
                                  onTap: () => setState(() => _editing = !_editing),
                                  customBorder: const CircleBorder(),
                                  child: Container(
                                    width: 28, height: 28,
                                    decoration: const BoxDecoration(color: _fieldBg, shape: BoxShape.circle),
                                    child: Icon(_editing ? Icons.check : Icons.edit_outlined, size: 15, color: _ink),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            _MethodRow(
                              icon: Icons.apple,
                              label: 'Apple Pay',
                              selected: store.selectedId == 'apple',
                              onTap: () => store.select('apple'),
                            ),
                            _MethodRow(
                              icon: Icons.credit_card,
                              label: 'Add Card or debit card',
                              selected: false,
                              showRadio: false,
                              trailing: const Icon(Icons.add, size: 20, color: AppColors.primary),
                              onTap: _addCard,
                            ),
                            for (final c in store.cards)
                              _CardRow(
                                card: c,
                                selected: store.selectedId == 'card:${c.last4}',
                                editing: _editing,
                                onTap: () => store.select('card:${c.last4}'),
                                onDelete: () => _deleteCard(c),
                              ),
                            const Divider(color: Color(0xFFEDEDED), height: 1),
                            _MethodRow(
                              icon: Icons.account_balance_wallet_outlined,
                              iconColor: AppColors.green,
                              label: 'Bank Transfer',
                              selected: store.selectedId == 'bank',
                              onTap: () => store.select('bank'),
                            ),
                            const SizedBox(height: 24),
                            const Text('Rewards and coupons',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.black)),
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const OffersScreen()),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                child: Row(
                                  children: const [
                                    Icon(Icons.add, size: 18, color: AppColors.primary),
                                    SizedBox(width: 8),
                                    Text('Add promo code',
                                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.primary)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            Positioned(
              left: 0, right: 0, bottom: 0,
              child: _BottomButton(label: 'Continue', onTap: () => Navigator.of(context).maybePop()),
            ),
            if (_toast != null)
              Positioned(top: 26, left: 24, right: 24, child: _Toast(message: _toast!)),
          ],
        ),
      ),
    );
  }
}

class _MethodRow extends StatelessWidget {
  const _MethodRow({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.iconColor = AppColors.black,
    this.showRadio = true,
    this.trailing,
  });
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color iconColor;
  final bool showRadio;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            Icon(icon, size: 20, color: iconColor),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: const TextStyle(fontSize: 14, color: AppColors.black))),
            if (trailing != null) trailing! else if (showRadio) _Radio(selected: selected),
          ],
        ),
      ),
    );
  }
}

class _CardRow extends StatelessWidget {
  const _CardRow({
    required this.card,
    required this.selected,
    required this.editing,
    required this.onTap,
    required this.onDelete,
  });
  final SavedCard card;
  final bool selected;
  final bool editing;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            _BrandMark(brand: card.brand),
            const SizedBox(width: 12),
            Expanded(child: Text('•••• ${card.last4}', style: const TextStyle(fontSize: 14, color: AppColors.black))),
            if (editing) ...[
              InkWell(
                onTap: onDelete,
                customBorder: const CircleBorder(),
                child: const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: Icon(Icons.remove_circle, size: 20, color: AppColors.red),
                ),
              ),
            ],
            _Radio(selected: selected),
          ],
        ),
      ),
    );
  }
}

class _Radio extends StatelessWidget {
  const _Radio({required this.selected});
  final bool selected;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18, height: 18,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: selected ? AppColors.primary : const Color(0xFFC7CBD9), width: selected ? 5 : 1.5),
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark({required this.brand});
  final String brand;
  @override
  Widget build(BuildContext context) {
    if (brand == 'visa') {
      return Container(
        width: 28, height: 18,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFF2F4FF),
          borderRadius: BorderRadius.circular(3),
        ),
        child: const Text('VISA',
            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF1A1F71), letterSpacing: 0.5)),
      );
    }
    // mastercard: two overlapping circles
    return SizedBox(
      width: 28, height: 18,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(left: 3, child: Container(width: 14, height: 14, decoration: const BoxDecoration(color: Color(0xFFEB001B), shape: BoxShape.circle))),
          Positioned(right: 3, child: Container(width: 14, height: 14, decoration: const BoxDecoration(color: Color(0xCCF79E1B), shape: BoxShape.circle))),
        ],
      ),
    );
  }
}

/// ---------------- Add new card ----------------

class AddCardScreen extends StatefulWidget {
  const AddCardScreen({super.key});
  @override
  State<AddCardScreen> createState() => _AddCardScreenState();
}

class _AddCardScreenState extends State<AddCardScreen> {
  final _number = TextEditingController();
  final _exp = TextEditingController();
  final _cvv = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    for (final c in [_number, _exp, _cvv]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _number.dispose();
    _exp.dispose();
    _cvv.dispose();
    super.dispose();
  }

  bool get _valid =>
      _number.text.replaceAll(' ', '').length >= 12 && _exp.text.length >= 4 && _cvv.text.length >= 3;

  Future<void> _submit() async {
    if (!_valid || _loading) return;
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 1300));
    PaymentStore.instance.addCard(_number.text);
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.white,
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              StatusBar(),
              _Header2(title: 'Add new card'),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(width: 34, height: 34, child: CircularProgressIndicator(strokeWidth: 3, color: AppColors.primary)),
                      SizedBox(height: 16),
                      Text('Adding card details', style: TextStyle(fontSize: 14, color: _grey)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            const StatusBar(),
            _Header2(title: 'Add new card', onBack: () => Navigator.of(context).maybePop()),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _field('Card Number', _number, 'Enter your card details',
                        keyboard: TextInputType.number,
                        formatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(19)]),
                    const SizedBox(height: 20),
                    _field('Exp Date', _exp, 'MM/YY',
                        keyboard: TextInputType.number,
                        formatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4), _ExpFormatter()]),
                    const SizedBox(height: 20),
                    _field('CVV', _cvv, '123',
                        keyboard: TextInputType.number,
                        trailing: const Icon(Icons.help_outline, size: 18, color: _grey),
                        formatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)]),
                    const SizedBox(height: 40),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        _BrandMark(brand: 'mastercard'),
                        SizedBox(width: 10),
                        _BrandMark(brand: 'visa'),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 51,
                      child: Material(
                        color: _valid ? AppColors.primary : AppColors.primary.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(30),
                        child: InkWell(
                          onTap: _valid ? _submit : null,
                          borderRadius: BorderRadius.circular(30),
                          child: const Center(
                            child: Text('Add card',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.white)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.lock_outline, size: 14, color: _grey),
                        SizedBox(width: 6),
                        Text('Your card details are encrypted and secure',
                            style: TextStyle(fontSize: 12, color: _grey)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController c, String hint,
      {TextInputType? keyboard, List<TextInputFormatter>? formatters, Widget? trailing}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.black)),
        const SizedBox(height: 8),
        Container(
          height: 48,
          decoration: BoxDecoration(color: _fieldBg, borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: c,
                  keyboardType: keyboard,
                  inputFormatters: formatters,
                  cursorColor: AppColors.primary,
                  style: const TextStyle(fontSize: 14, color: _ink),
                  decoration: InputDecoration(
                    isCollapsed: true,
                    border: InputBorder.none,
                    hintText: hint,
                    hintStyle: const TextStyle(fontSize: 14, color: _grey),
                  ),
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
        ),
      ],
    );
  }
}

class _ExpFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll('/', '');
    if (digits.length <= 2) return newValue.copyWith(text: digits, selection: TextSelection.collapsed(offset: digits.length));
    final out = '${digits.substring(0, 2)}/${digits.substring(2)}';
    return TextEditingValue(text: out, selection: TextSelection.collapsed(offset: out.length));
  }
}

// ---- shared ----

class _Header extends StatelessWidget {
  const _Header({required this.title, required this.onClose});
  final String title;
  final VoidCallback onClose;
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          children: [
            InkWell(onTap: onClose, child: const Icon(Icons.close, size: 24, color: _ink)),
            Expanded(
              child: Center(
                child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.black)),
              ),
            ),
            const SizedBox(width: 24),
          ],
        ),
      ),
    );
  }
}

class _Header2 extends StatelessWidget {
  const _Header2({required this.title, this.onBack});
  final String title;
  final VoidCallback? onBack;
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          children: [
            InkWell(onTap: onBack, child: const Icon(Icons.arrow_back_ios_new, size: 20, color: _ink)),
            Expanded(
              child: Center(
                child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.black)),
              ),
            ),
            const SizedBox(width: 20),
          ],
        ),
      ),
    );
  }
}

class _BottomButton extends StatelessWidget {
  const _BottomButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: SizedBox(
        width: double.infinity,
        height: 51,
        child: Material(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(30),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(30),
            child: Center(
              child: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.white)),
            ),
          ),
        ),
      ),
    );
  }
}

class _Toast extends StatelessWidget {
  const _Toast({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 49,
      decoration: BoxDecoration(color: AppColors.green, borderRadius: BorderRadius.circular(8)),
      alignment: Alignment.center,
      child: Text(message, style: const TextStyle(color: AppColors.white, fontSize: 14, fontWeight: FontWeight.w500)),
    );
  }
}

class _DeleteCardDialog extends StatelessWidget {
  const _DeleteCardDialog();
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: InkWell(
                onTap: () => Navigator.of(context).pop(false),
                child: const Icon(Icons.close, size: 20, color: _grey),
              ),
            ),
            Container(
              width: 56, height: 56,
              decoration: const BoxDecoration(color: Color(0x1AF04438), shape: BoxShape.circle),
              child: const Icon(Icons.delete_outline, size: 26, color: AppColors.red),
            ),
            const SizedBox(height: 16),
            const Text('Delete Payment Card?',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _ink)),
            const SizedBox(height: 6),
            const Text(
              'Are you sure you want to delete this payment card? You won’t be able to use it for future payments unless you add it again.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: _grey),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.red),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: const Text('Remove', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.red)),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _ink)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
