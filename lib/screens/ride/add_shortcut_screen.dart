import 'dart:async';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../widgets/status_bar.dart';
import '../../services/mock/ride_models.dart';
import '../../services/mock/mock_repository.dart';

const _ink = Color(0xFF0A0F2C);
const _muted = Color(0xFF8A90A8);
const _fieldBg = Color(0xFFF5F6FA);

class AddShortcutScreen extends StatefulWidget {
  const AddShortcutScreen({super.key, required this.kind});
  final ShortcutKind kind;

  @override
  State<AddShortcutScreen> createState() => _AddShortcutScreenState();
}

class _AddShortcutScreenState extends State<AddShortcutScreen> {
  final _search = TextEditingController();
  List<Place> _results = const [];

  @override
  void initState() {
    super.initState();
    _results = PlacesRepository.instance.recents;
    _search.addListener(() => setState(() => _results = PlacesRepository.instance.search(_search.text)));
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  String get _title => switch (widget.kind) {
        ShortcutKind.home => 'Add home address',
        ShortcutKind.work => 'Add work address',
        ShortcutKind.custom => 'Add custom shortcut',
      };

  String get _hint => switch (widget.kind) {
        ShortcutKind.home => 'Search for your home address',
        ShortcutKind.work => 'Search for your work address',
        ShortcutKind.custom => 'Search for your address',
      };

  Future<void> _select(Place p) async {
    final store = ShortcutsStore.instance;
    if (widget.kind == ShortcutKind.home) {
      store.setHome(p);
      if (mounted) Navigator.of(context).pop(p);
    } else if (widget.kind == ShortcutKind.work) {
      store.setWork(p);
      if (mounted) Navigator.of(context).pop(p);
    } else {
      final name = await Navigator.of(context).push<String>(MaterialPageRoute(
        builder: (_) => NameShortcutScreen(place: p),
      ));
      if (name != null && name.trim().isNotEmpty) {
        store.addCustom(name.trim(), p);
        if (mounted) Navigator.of(context).pop(p);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Column(
        children: [
          const StatusBar(),
          _Header(title: _title),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _SearchField(controller: _search, hint: _hint),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              children: [
                _CurrentLocationRow(onTap: () => _select(PlacesRepository.currentLocation.copyForCurrent())),
                const SizedBox(height: 4),
                for (final p in _results) _PlaceRow(place: p, onTap: () => _select(p)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Name step for a custom shortcut. Returns the entered name.
class NameShortcutScreen extends StatefulWidget {
  const NameShortcutScreen({super.key, required this.place});
  final Place place;

  @override
  State<NameShortcutScreen> createState() => _NameShortcutScreenState();
}

class _NameShortcutScreenState extends State<NameShortcutScreen> {
  final _name = TextEditingController();
  bool _saved = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _save() {
    if (_name.text.trim().isEmpty) return;
    setState(() => _saved = true);
    Timer(const Duration(milliseconds: 900), () {
      if (mounted) Navigator.of(context).pop(_name.text.trim());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Stack(
        children: [
          Column(
            children: [
              const StatusBar(),
              _Header(
                title: 'Add a name',
                trailing: GestureDetector(
                  onTap: _save,
                  child: const Icon(Icons.check, size: 22, color: AppColors.primary),
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 18, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(widget.place.subtitle,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _ink)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text('SHORTCUT NAME',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _muted, letterSpacing: 0.5)),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: const Color(0xFFDDE1EC)),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: TextField(
                        controller: _name,
                        autofocus: true,
                        cursorColor: AppColors.primary,
                        onSubmitted: (_) => _save(),
                        style: const TextStyle(fontSize: 14, color: _ink),
                        decoration: const InputDecoration(
                          isCollapsed: true,
                          border: InputBorder.none,
                          hintText: 'e.g Gym, School, Mum’s house',
                          hintStyle: TextStyle(fontSize: 14, color: _muted),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_saved)
            Positioned(
              top: 26,
              left: 23,
              right: 23,
              child: Container(
                height: 49,
                decoration: BoxDecoration(color: AppColors.green, borderRadius: BorderRadius.circular(8)),
                alignment: Alignment.center,
                child: const Text('Shortcut added',
                    style: TextStyle(color: AppColors.white, fontSize: 14, fontWeight: FontWeight.w500)),
              ),
            ),
        ],
      ),
    );
  }
}

// ---- shared bits ----

class _Header extends StatelessWidget {
  const _Header({required this.title, this.trailing});
  final String title;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: Row(
        children: [
          const SizedBox(width: 24),
          InkWell(
            onTap: () => Navigator.of(context).maybePop(),
            child: const Icon(Icons.close, size: 22, color: _ink),
          ),
          Expanded(
            child: Center(
              child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _ink)),
            ),
          ),
          SizedBox(
            width: 46,
            child: trailing == null
                ? null
                : Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(padding: const EdgeInsets.only(left: 2), child: trailing),
                  ),
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.hint});
  final TextEditingController controller;
  final String hint;
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: _fieldBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE8ECF8), width: 1.5),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const Icon(Icons.search, size: 18, color: _muted),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              autofocus: true,
              cursorColor: AppColors.primary,
              style: const TextStyle(fontSize: 14, color: _ink),
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: hint,
                hintStyle: const TextStyle(fontSize: 14, color: _muted),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CurrentLocationRow extends StatelessWidget {
  const _CurrentLocationRow({required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(color: _fieldBg, shape: BoxShape.circle),
              child: const Icon(Icons.my_location, size: 18, color: AppColors.primary),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Use my current location',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _ink)),
                  SizedBox(height: 2),
                  Text('Victoria Island, Lagos', style: TextStyle(fontSize: 12, color: _muted)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaceRow extends StatelessWidget {
  const _PlaceRow({required this.place, required this.onTap});
  final Place place;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.stroke))),
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(color: _fieldBg, shape: BoxShape.circle),
              child: Icon(iconFor(place.icon), size: 18, color: _ink),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(place.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _ink)),
                  const SizedBox(height: 2),
                  Text(place.subtitle, style: const TextStyle(fontSize: 12, color: _muted)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension on Place {
  Place copyForCurrent() =>
      Place(name: 'Current location', subtitle: subtitle, distanceKm: 7.0, icon: PlaceIcon.pin);
}
