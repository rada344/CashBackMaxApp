import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../services/location_service.dart';
import '../services/store_service.dart';
import '../utils/app_colors.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key, this.onManualStoreSelected});
  final ValueChanged<SupportedStore>? onManualStoreSelected;

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  // Canberra Centre — default view when we don't have the user's location yet.
  static const LatLng _canberra = LatLng(-35.2809, 149.1300);
  static const double _defaultZoom = 14.5;

  bool geofence = true;
  bool notifications = true;
  String status = 'Location not checked yet';
  SupportedStore? nearestStore;
  bool loading = false;
  LatLng? userLatLng;

  final locationService = LocationService();
  final storeService = StoreService();
  final mapController = MapController();

  @override
  void dispose() {
    mapController.dispose();
    super.dispose();
  }

  Future<void> detectLocation() async {
    setState(() => loading = true);
    try {
      final position = await locationService.getCurrentLocation();
      final store = storeService.detectNearestStore(position);
      final latLng = LatLng(position.latitude, position.longitude);
      setState(() {
        userLatLng = latLng;
        nearestStore = store;
        status = store == null
            ? 'No supported store found within geofence radius.'
            : '${store.name} detected near your current location.';
      });
      mapController.move(latLng, _defaultZoom);
    } catch (e) {
      setState(() => status = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.fromLTRB(20, 12, 20, 24), children: [
        const Text('Location', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
        const Text('Real-time detection + manual fallback', style: TextStyle(color: AppColors.text2)),
        const SizedBox(height: 18),
        SizedBox(
          height: 280,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: FlutterMap(
              mapController: mapController,
              options: const MapOptions(
                initialCenter: _canberra,
                initialZoom: _defaultZoom,
                interactionOptions: InteractionOptions(
                  flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag | InteractiveFlag.doubleTapZoom,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.cashback_rewards_points_maximiser',
                ),
                MarkerLayer(
                  markers: [
                    if (userLatLng != null)
                      Marker(
                        point: userLatLng!,
                        width: 22,
                        height: 22,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.accent.withValues(alpha: .55),
                                blurRadius: 12,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      ),
                    for (final store in StoreService.supportedStores)
                      Marker(
                        point: LatLng(store.latitude, store.longitude),
                        width: 100,
                        height: 56,
                        alignment: Alignment.topCenter,
                        child: _StoreMarker(
                          store: store,
                          active: nearestStore?.name == store.name,
                          onTap: () => widget.onManualStoreSelected?.call(store),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppColors.bg2, borderRadius: BorderRadius.circular(18)),
          child: Row(children: [
            const Icon(Icons.my_location_rounded, color: AppColors.accent2),
            const SizedBox(width: 12),
            Expanded(child: Text(status, style: const TextStyle(color: AppColors.text2))),
            FilledButton(
              onPressed: loading ? null : detectLocation,
              style: FilledButton.styleFrom(backgroundColor: AppColors.accent),
              child: loading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Detect'),
            )
          ]),
        ),
        const SizedBox(height: 12),
        _SwitchTile(icon: '📍', title: 'Geofencing', subtitle: 'Auto-detect supported stores', value: geofence, onChanged: (v) => setState(() => geofence = v)),
        _SwitchTile(icon: '🔔', title: 'Smart Notifications', subtitle: 'Alert on store entry only', value: notifications, onChanged: (v) => setState(() => notifications = v)),
        const SizedBox(height: 18),
        const Text('Supported Stores Nearby', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        ...StoreService.supportedStores.map((store) => _Nearby(
              icon: _iconForCategory(store.category),
              name: store.name,
              sub: '${store.category} · active geofence · tap for manual fallback',
              dist: nearestStore?.name == store.name ? 'Active' : 'Select',
              onTap: () => widget.onManualStoreSelected?.call(store),
            )),
      ]);

  String _iconForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'groceries':
        return '🛒';
      case 'fuel':
        return '⛽';
      case 'health':
        return '💊';
      default:
        return '🏪';
    }
  }
}

class _StoreMarker extends StatelessWidget {
  const _StoreMarker({
    required this.store,
    required this.active,
    required this.onTap,
  });

  final SupportedStore store;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = active ? AppColors.green : AppColors.accent2;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.bg2.withValues(alpha: .95),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: accent.withValues(alpha: .6)),
            ),
            child: Text(
              store.name.split(' ').first,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: accent,
                fontWeight: FontWeight.w800,
                fontSize: 10,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Icon(Icons.location_on, color: accent, size: 28),
        ],
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  const _SwitchTile({required this.icon, required this.title, required this.subtitle, required this.value, required this.onChanged});
  final String icon, title, subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppColors.bg3, borderRadius: BorderRadius.circular(18)),
        child: Row(children: [
          Text(icon, style: const TextStyle(fontSize: 26)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
              Text(subtitle, style: const TextStyle(color: AppColors.text2, fontSize: 12)),
            ]),
          ),
          Switch(value: value, activeThumbColor: AppColors.green, onChanged: onChanged),
        ]),
      );
}

class _Nearby extends StatelessWidget {
  const _Nearby({required this.icon, required this.name, required this.sub, required this.dist, required this.onTap});
  final String icon, name, sub, dist;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppColors.bg2, borderRadius: BorderRadius.circular(18)),
          child: Row(children: [
            Text(icon, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w800)),
                Text(sub, style: const TextStyle(color: AppColors.text2, fontSize: 12)),
              ]),
            ),
            Text(dist, style: const TextStyle(color: AppColors.accent2, fontWeight: FontWeight.w800)),
          ]),
        ),
      );
}
