import 'dart:async';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../widgets/status_bar.dart';
import '../../services/mock/rewards_repository.dart';

const _ink = Color(0xFF0A0F2C);
const _grey = Color(0xFF808080);
const _detailGrey = Color(0xFF4A5565);
const _stroke = Color(0xFFE6E6E6);

class OffersScreen extends StatefulWidget {
  const OffersScreen({super.key});

  @override
  State<OffersScreen> createState() => _OffersScreenState();
}

class _OffersScreenState extends State<OffersScreen> {
  final _promo = TextEditingController();
  String? _promoError;
  String? _promoSuccess;
  String? _toast;
  Timer? _toastTimer;

  @override
  void initState() {
    super.initState();
    _promo.addListener(() {
      if (_promoError != null || _promoSuccess != null) {
        setState(() {
          _promoError = null;
          _promoSuccess = null;
        });
      } else {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _promo.dispose();
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

  void _redeem() {
    final err = OffersStore.instance.redeem(_promo.text);
    setState(() {
      if (err == null) {
        _promoSuccess = 'Promo code applied! You saved 20%';
        _promoError = null;
        _promo.clear();
      } else {
        _promoError = err;
        _promoSuccess = null;
      }
    });
  }

  Future<void> _confirmRemove(Offer o) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => const _RemoveOfferDialog(),
    );
    if (ok == true) {
      OffersStore.instance.remove(o);
      _showToast('Offer removed');
    }
  }

  @override
  Widget build(BuildContext context) {
    final canRedeem = _promo.text.trim().isNotEmpty;
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            Column(
              children: [
                const StatusBar(),
                _Header(title: 'Offers and promos', onClose: () => Navigator.of(context).maybePop()),
                Expanded(
                  child: ListenableBuilder(
                    listenable: OffersStore.instance,
                    builder: (context, _) {
                      final store = OffersStore.instance;
                      return SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(24, 8, 24, 120),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'We automatically apply eligible offers. You can edit what’s applied after each ride.',
                              style: TextStyle(fontSize: 14, color: AppColors.black, height: 1.35),
                            ),
                            const SizedBox(height: 24),
                            _promoField(canRedeem),
                            const SizedBox(height: 24),
                            const Divider(color: _stroke, height: 1),
                            const SizedBox(height: 24),
                            if (store.applied.isNotEmpty) ...[
                              const Text('Applied to this ride',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.black)),
                              const SizedBox(height: 12),
                              for (final o in store.applied)
                                _AppliedRow(offer: o, onRemove: () => _confirmRemove(o)),
                              const SizedBox(height: 26),
                            ],
                            const Text('Available offers',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.black)),
                            const SizedBox(height: 12),
                            if (store.available.isEmpty)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child: Text('No more offers available right now.',
                                    style: TextStyle(fontSize: 13, color: _grey)),
                              ),
                            for (final o in store.available)
                              _AvailableRow(
                                offer: o,
                                onApply: () {
                                  store.apply(o);
                                  _showToast('Offer applied');
                                },
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            // Continue bar
            ListenableBuilder(
              listenable: OffersStore.instance,
              builder: (context, _) {
                if (!OffersStore.instance.hasApplied) return const SizedBox.shrink();
                return Positioned(
                  left: 0, right: 0, bottom: 0,
                  child: _BottomButton(
                    label: 'Continue',
                    onTap: () => Navigator.of(context).maybePop(),
                  ),
                );
              },
            ),
            // Toast
            if (_toast != null)
              Positioned(
                top: 26, left: 24, right: 24,
                child: _Toast(message: _toast!),
              ),
          ],
        ),
      ),
    );
  }

  Widget _promoField(bool canRedeem) {
    final error = _promoError != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: error ? AppColors.red : _stroke),
          ),
          padding: const EdgeInsets.only(left: 16, right: 10),
          child: Row(
            children: [
              Icon(Icons.auto_awesome, size: 18, color: error ? AppColors.red : _grey),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _promo,
                  cursorColor: AppColors.primary,
                  textCapitalization: TextCapitalization.characters,
                  style: const TextStyle(fontSize: 14, color: _ink),
                  decoration: const InputDecoration(
                    isCollapsed: true,
                    border: InputBorder.none,
                    hintText: 'Enter promo code',
                    hintStyle: TextStyle(fontSize: 14, color: _grey),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_promoSuccess != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                const Icon(Icons.check_circle, size: 16, color: AppColors.green),
                const SizedBox(width: 6),
                Text(_promoSuccess!, style: const TextStyle(fontSize: 12, color: AppColors.green)),
              ],
            ),
          ),
        if (_promoError != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                const Icon(Icons.error_outline, size: 16, color: AppColors.red),
                const SizedBox(width: 6),
                Text(_promoError!, style: const TextStyle(fontSize: 12, color: AppColors.red)),
              ],
            ),
          ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 51,
          child: Material(
            color: canRedeem ? AppColors.primary : AppColors.primary.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(30),
            child: InkWell(
              onTap: canRedeem ? _redeem : null,
              borderRadius: BorderRadius.circular(30),
              child: const Center(
                child: Text('Redeem',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.white)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AppliedRow extends StatelessWidget {
  const _AppliedRow({required this.offer, required this.onRemove});
  final Offer offer;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: _stroke)),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      child: Row(
        children: [
          _Badge(offer: offer),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(offer.code, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.black)),
                const SizedBox(height: 4),
                Text(offer.title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: _detailGrey)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: const Color(0x1A00853F), borderRadius: BorderRadius.circular(30)),
            child: const Text('APPLIED',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.green)),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: onRemove,
            customBorder: const CircleBorder(),
            child: Container(
              width: 24, height: 24,
              decoration: const BoxDecoration(color: Color(0xFFE5E7EB), shape: BoxShape.circle),
              child: const Icon(Icons.close, size: 12, color: _detailGrey),
            ),
          ),
        ],
      ),
    );
  }
}

class _AvailableRow extends StatelessWidget {
  const _AvailableRow({required this.offer, required this.onApply});
  final Offer offer;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: _stroke)),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      child: Row(
        children: [
          _Badge(offer: offer),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(offer.code, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.black)),
                const SizedBox(height: 4),
                Text(offer.title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: _detailGrey)),
                if (offer.detail.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(offer.detail, style: const TextStyle(fontSize: 12, color: Color(0xFF6A7282))),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onApply,
            behavior: HitTestBehavior.opaque,
            child: const Text('Apply',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.offer});
  final Offer offer;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34, height: 34,
      decoration: BoxDecoration(color: offer.badgeBg, shape: BoxShape.circle),
      child: Icon(offer.icon, size: 18, color: offer.badgeFg),
    );
  }
}

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
            InkWell(onTap: onClose, child: const Icon(Icons.arrow_back_ios_new, size: 20, color: _ink)),
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
              child: Text(label,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.white)),
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
      child: Text(message,
          style: const TextStyle(color: AppColors.white, fontSize: 14, fontWeight: FontWeight.w500)),
    );
  }
}

class _RemoveOfferDialog extends StatelessWidget {
  const _RemoveOfferDialog();
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
              child: const Icon(Icons.logout, size: 26, color: AppColors.red),
            ),
            const SizedBox(height: 16),
            const Text('Remove this offer?',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _ink)),
            const SizedBox(height: 6),
            const Text('Are you sure you want to remove this offer?',
                textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: _grey)),
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
