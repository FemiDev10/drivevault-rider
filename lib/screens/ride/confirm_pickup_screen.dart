import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../widgets/status_bar.dart';
import '../../widgets/live_map.dart';
import '../../services/mock/ride_models.dart';
import 'make_offer_screen.dart';
import 'ride_progress_screen.dart';

const _ink = Color(0xFF0A0F2C);
const _muted = Color(0xFF8A90A8);
const _sub = Color(0xFF9AA0B4);

class ConfirmPickupScreen extends StatefulWidget {
  const ConfirmPickupScreen({
    super.key,
    required this.pickup,
    required this.destination,
    this.quote,
    this.mode = PriceMode.instant,
  });
  final Place pickup;
  final Place destination;
  final RideQuote? quote;
  final PriceMode mode;

  @override
  State<ConfirmPickupScreen> createState() => _ConfirmPickupScreenState();
}

class _ConfirmPickupScreenState extends State<ConfirmPickupScreen> {
  final _note = TextEditingController();
  bool _noteOpen = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  String get _street {
    final s = widget.pickup.subtitle.isNotEmpty ? widget.pickup.subtitle : widget.pickup.name;
    return s.split(',').first;
  }

  void _confirm() {
    final q = widget.quote;
    if (q == null) {
      // Reached via "Choose on map" (no ride selected yet) — just set the spot.
      Navigator.of(context).maybePop();
      return;
    }
    if (widget.mode == PriceMode.negotiate) {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => MakeOfferScreen(pickup: widget.pickup, destination: widget.destination, quote: q),
      ));
    } else {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => RideProgressScreen(
          pickup: widget.pickup, destination: widget.destination, quote: q, mode: PriceMode.instant,
        ),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Stack(
        children: [
          Positioned.fill(
            child: LiveMap(
              showCentrePin: true,
              centrePinLabel: 'Pick up on $_street',
              filledLabel: _noteOpen,
            ),
          ),
          const Positioned(top: 0, left: 0, right: 0, child: StatusBar()),
          Positioned(
            top: 64,
            left: 24,
            child: InkWell(
              onTap: () => Navigator.of(context).maybePop(),
              child: const Icon(Icons.arrow_back, size: 24, color: _ink),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: _sheet(),
          ),
        ],
      ),
    );
  }

  Widget _sheet() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [BoxShadow(color: Color(0x22000000), blurRadius: 12, offset: Offset(0, -2))],
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 68, height: 5,
              decoration: BoxDecoration(color: const Color(0xFFDCDFE5), borderRadius: BorderRadius.circular(18)),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Confirm pick-up spot',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _ink)),
          const SizedBox(height: 4),
          const Text('Drag map or edit address to set your pickup',
              style: TextStyle(fontSize: 13, color: _sub)),
          const SizedBox(height: 16),

          if (!_noteOpen) _addressCard() else _addressField(),

          const SizedBox(height: 12),
          if (!_noteOpen)
            GestureDetector(
              onTap: () => setState(() => _noteOpen = true),
              behavior: HitTestBehavior.opaque,
              child: Row(
                children: const [
                  Icon(Icons.add, size: 18, color: AppColors.primary),
                  SizedBox(width: 6),
                  Text('Add note for driver',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.primary)),
                ],
              ),
            )
          else
            _noteField(),

          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: Material(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(30),
              child: InkWell(
                onTap: _confirm,
                borderRadius: BorderRadius.circular(30),
                child: const Center(
                  child: Text('Confirm pick-up',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.white)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Collapsed: bordered card with icon + name/address + Edit link.
  Widget _addressCard() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE6E8F0)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.location_on, size: 18, color: AppColors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.pickup.name,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _ink)),
                const SizedBox(height: 2),
                Text(widget.pickup.subtitle,
                    style: const TextStyle(fontSize: 12, color: _muted), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => setState(() => _noteOpen = true),
            child: const Text('Edit', style: TextStyle(fontSize: 14, color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  // Expanded: address shown as a search-style field.
  Widget _addressField() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE6E8F0)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.pickup.name,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _ink)),
                const SizedBox(height: 2),
                Text('Near ${widget.pickup.subtitle}'.toUpperCase(),
                    style: const TextStyle(fontSize: 11, color: _muted, letterSpacing: 0.3),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const Icon(Icons.search, size: 20, color: _muted),
        ],
      ),
    );
  }

  Widget _noteField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Note for driver',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _ink)),
            GestureDetector(
              onTap: () => setState(() {
                _noteOpen = false;
                _note.clear();
              }),
              child: const Icon(Icons.close, size: 18, color: _muted),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 84,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE6E8F0)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: TextField(
            controller: _note,
            maxLines: null,
            expands: true,
            textAlignVertical: TextAlignVertical.top,
            cursorColor: AppColors.primary,
            style: const TextStyle(fontSize: 14, color: _ink),
            decoration: const InputDecoration(
              isCollapsed: true,
              border: InputBorder.none,
              hintText: 'e.g. I’m at the second gate, blue umbrella',
              hintStyle: TextStyle(fontSize: 13, color: _muted),
            ),
          ),
        ),
      ],
    );
  }
}
