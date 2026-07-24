import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../widgets/status_bar.dart';
import '../../services/mock/ride_models.dart';
import '../../services/mock/mock_repository.dart';
import 'choose_ride_screen.dart';
import 'confirm_pickup_screen.dart';
import 'add_shortcut_screen.dart';

const _ink = Color(0xFF0A0F2C);
const _muted = Color(0xFF8A90A8);
const _fieldBg = Color(0xFFF5F6FA);

class RouteSearchScreen extends StatefulWidget {
  const RouteSearchScreen({super.key});

  @override
  State<RouteSearchScreen> createState() => _RouteSearchScreenState();
}

class _RouteSearchScreenState extends State<RouteSearchScreen> {
  final _dest = TextEditingController();
  final _pickupCtrl = TextEditingController(text: PlacesRepository.currentLocation.name);
  final _pickupFocus = FocusNode();
  Place _pickup = PlacesRepository.currentLocation;
  List<Place> _results = const [];

  @override
  void initState() {
    super.initState();
    _dest.addListener(() {
      setState(() => _results = PlacesRepository.instance.search(_dest.text));
    });
    // Keep the pickup Place in step with whatever the rider types.
    _pickupCtrl.addListener(() {
      final text = _pickupCtrl.text.trim();
      _pickup = text.isEmpty
          ? const Place(name: '', subtitle: '', distanceKm: 0)
          : (text == PlacesRepository.currentLocation.name
              ? PlacesRepository.currentLocation
              : Place(name: text, subtitle: '', distanceKm: 0));
    });
  }

  @override
  void dispose() {
    _dest.dispose();
    _pickupCtrl.dispose();
    _pickupFocus.dispose();
    super.dispose();
  }

  void _useCurrentLocation() {
    _pickupCtrl.text = PlacesRepository.currentLocation.name;
    setState(() => _pickup = PlacesRepository.currentLocation);
  }

  bool get _typing => _dest.text.trim().isNotEmpty;

  void _pickDestination(Place p) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ChooseRideScreen(pickup: _pickup, destination: p),
    ));
  }

  Future<void> _openShortcut(ShortcutKind kind) async {
    final s = await Navigator.of(context).push<Place>(MaterialPageRoute(
      builder: (_) => AddShortcutScreen(kind: kind),
    ));
    if (s != null) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Column(
        children: [
          const StatusBar(),
          // Header
          SizedBox(
            height: 42,
            child: Row(
              children: [
                const SizedBox(width: 24),
                InkWell(
                  onTap: () => Navigator.of(context).maybePop(),
                  child: const Icon(Icons.close, size: 22, color: _ink),
                ),
                const Expanded(
                  child: Center(
                    child: Text('Your route',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _ink)),
                  ),
                ),
                const SizedBox(width: 46),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _RouteFields(
              pickupController: _pickupCtrl,
              pickupFocus: _pickupFocus,
              destController: _dest,
              onClearPickup: () {
                _pickupCtrl.clear();
                _pickupFocus.requestFocus();
                setState(() {});
              },
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _typing ? _resultsView() : _actionsView(),
          ),
        ],
      ),
    );
  }

  // ---- Destination empty: actions + shortcuts ----
  Widget _actionsView() {
    return ListenableBuilder(
      listenable: ShortcutsStore.instance,
      builder: (context, _) {
        final store = ShortcutsStore.instance;
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _AddStop(),
              const SizedBox(height: 12),
              const Divider(color: AppColors.stroke, height: 1),
              const SizedBox(height: 12),
              _ActionRow(
                icon: Icons.my_location,
                title: 'Use my current location',
                subtitle: 'Victoria Island, Lagos',
                onTap: _useCurrentLocation,
              ),
              _ActionRow(
                icon: Icons.location_on_outlined,
                title: 'Choose on map',
                subtitle: 'Pin your exact location',
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => ConfirmPickupScreen(
                    pickup: _pickup,
                    destination: PlacesRepository.instance.recents.first,
                  ),
                )),
              ),
              const SizedBox(height: 8),
              const Divider(color: AppColors.stroke, height: 1),
              const SizedBox(height: 16),
              const Text('SAVE SHORTCUTS',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _muted, letterSpacing: 0.5)),
              const SizedBox(height: 12),
              _ShortcutRow(
                icon: Icons.home_outlined,
                shortcut: store.home,
                unsetSubtitle: 'Save your home address',
                onTap: () => store.home.isSet ? _pickDestination(store.home.place!) : _openShortcut(ShortcutKind.home),
              ),
              _ShortcutRow(
                icon: Icons.work_outline,
                shortcut: store.work,
                unsetSubtitle: 'Save your work address',
                onTap: () => store.work.isSet ? _pickDestination(store.work.place!) : _openShortcut(ShortcutKind.work),
              ),
              for (final s in store.custom)
                _ShortcutRow(
                  icon: Icons.push_pin_outlined,
                  shortcut: s,
                  unsetSubtitle: '',
                  onDelete: () => store.removeCustom(s),
                  onTap: () => _pickDestination(s.place!),
                ),
              _ActionRow(
                icon: Icons.add,
                iconColor: AppColors.primary,
                title: 'Add custom shortcut',
                subtitle: 'Gym, School, or any frequent place',
                trailingArrow: true,
                onTap: () => _openShortcut(ShortcutKind.custom),
              ),
            ],
          ),
        );
      },
    );
  }

  // ---- Destination typing: results ----
  Widget _resultsView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AddStop(label: 'Add a another stop'),
          const SizedBox(height: 16),
          const Text('RESULTS',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _muted, letterSpacing: 0.5)),
          const SizedBox(height: 4),
          if (_results.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text('No places found', style: TextStyle(color: _muted)),
            ),
          for (final p in _results) _ResultRow(place: p, query: _dest.text, onTap: () => _pickDestination(p)),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () {},
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text('Search on map instead',
                    style: TextStyle(fontSize: 14, color: AppColors.primary)),
                Icon(Icons.map_outlined, size: 20, color: AppColors.primary),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Pickup + destination stacked fields with the connecting dotted rail.
class _RouteFields extends StatelessWidget {
  const _RouteFields({
    required this.pickupController,
    required this.pickupFocus,
    required this.destController,
    required this.onClearPickup,
  });
  final TextEditingController pickupController;
  final FocusNode pickupFocus;
  final TextEditingController destController;
  final VoidCallback onClearPickup;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Pickup (filled)
        Container(
          height: 60,
          decoration: BoxDecoration(color: _fieldBg, borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              const Icon(Icons.trip_origin, size: 18, color: AppColors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Pickup', style: TextStyle(fontSize: 12, color: _muted)),
                    TextField(
                      controller: pickupController,
                      focusNode: pickupFocus,
                      cursorColor: AppColors.primary,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _ink),
                      decoration: const InputDecoration(
                        isCollapsed: true,
                        border: InputBorder.none,
                        hintText: 'Enter pickup location',
                        hintStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: _muted),
                      ),
                    ),
                  ],
                ),
              ),
              // Clear appears only when there is something to clear.
              ValueListenableBuilder(
                valueListenable: pickupController,
                builder: (_, value, __) => value.text.isEmpty
                    ? const SizedBox.shrink()
                    : GestureDetector(
                        onTap: onClearPickup,
                        child: const Text('Clear',
                            style: TextStyle(fontSize: 14, color: AppColors.primary)),
                      ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Destination (editable)
        Container(
          height: 60,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFDDE1EC)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              const Icon(Icons.location_on, size: 18, color: AppColors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Destination', style: TextStyle(fontSize: 12, color: _muted)),
                    TextField(
                      controller: destController,
                      autofocus: true,
                      cursorColor: AppColors.primary,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _ink),
                      decoration: const InputDecoration(
                        isCollapsed: true,
                        border: InputBorder.none,
                        hintText: 'Where are you going?',
                        hintStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: _muted),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.search, size: 18, color: _muted),
            ],
          ),
        ),
      ],
    );
  }
}

class _AddStop extends StatelessWidget {
  const _AddStop({this.label = 'Add a stop'});
  final String label;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.add, size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.primary)),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.iconColor = _ink,
    this.trailingArrow = false,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color iconColor;
  final bool trailingArrow;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(color: _fieldBg, shape: BoxShape.circle),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _ink)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: _muted)),
                ],
              ),
            ),
            if (trailingArrow)
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(color: _fieldBg, shape: BoxShape.circle),
                child: const Icon(Icons.arrow_forward, size: 14, color: _muted),
              ),
          ],
        ),
      ),
    );
  }
}

class _ShortcutRow extends StatelessWidget {
  const _ShortcutRow({
    required this.icon,
    required this.shortcut,
    required this.unsetSubtitle,
    required this.onTap,
    this.onDelete,
  });
  final IconData icon;
  final Shortcut shortcut;
  final String unsetSubtitle;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final set = shortcut.isSet;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(color: _fieldBg, shape: BoxShape.circle),
              child: Icon(icon, size: 18, color: AppColors.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(shortcut.label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _ink)),
                  const SizedBox(height: 2),
                  Text(set ? shortcut.place!.subtitle : unsetSubtitle,
                      style: const TextStyle(fontSize: 12, color: _muted)),
                ],
              ),
            ),
            if (set && onDelete != null)
              InkWell(
                onTap: onDelete,
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.delete_outline, size: 20, color: _muted),
                ),
              )
            else
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(color: _fieldBg, shape: BoxShape.circle),
                child: const Icon(Icons.arrow_forward, size: 14, color: _muted),
              ),
          ],
        ),
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.place, required this.query, required this.onTap});
  final Place place;
  final String query;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.stroke)),
        ),
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
                  _highlighted(place.name, query),
                  const SizedBox(height: 2),
                  Text(place.subtitle, style: const TextStyle(fontSize: 12, color: _muted)),
                ],
              ),
            ),
            if (place.distanceKm > 0)
              Text('${place.distanceKm.toStringAsFixed(1)} km',
                  style: const TextStyle(fontSize: 12, color: _muted)),
          ],
        ),
      ),
    );
  }

  Widget _highlighted(String text, String query) {
    final q = query.trim().toLowerCase();
    final lower = text.toLowerCase();
    final idx = q.isEmpty ? -1 : lower.indexOf(q);
    const base = TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _ink);
    if (idx < 0) return Text(text, style: base);
    return Text.rich(TextSpan(children: [
      TextSpan(text: text.substring(0, idx), style: base),
      TextSpan(text: text.substring(idx, idx + q.length), style: base.copyWith(color: AppColors.primary)),
      TextSpan(text: text.substring(idx + q.length), style: base),
    ]));
  }
}
