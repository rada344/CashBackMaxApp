import 'package:flutter/material.dart';
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
  bool geofence = true;
  bool notifications = true;
  String status = 'Location not checked yet';
  SupportedStore? nearestStore;
  bool loading = false;

  final locationService = LocationService();
  final storeService = StoreService();

  Future<void> detectLocation() async {
    setState(() => loading = true);
    try {
      final position = await locationService.getCurrentLocation();
      final store = storeService.detectNearestStore(position);
      setState(() {
        nearestStore = store;
        status = store == null
            ? 'No supported store found within geofence radius.'
            : '${store.name} detected near your current location.';
      });
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
    Container(height: 230, decoration: BoxDecoration(color: AppColors.bg3, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white.withValues(alpha: .06))), child: Stack(alignment: Alignment.center, children: [
      Opacity(opacity: .35, child: GridPaper(color: Colors.white.withValues(alpha: .08), divisions: 1, subdivisions: 1, child: Container())),
      Container(width: 20, height: 20, decoration: BoxDecoration(color: AppColors.accent, shape: BoxShape.circle, boxShadow: [BoxShadow(color: AppColors.accent.withValues(alpha: .45), spreadRadius: 16, blurRadius: 20)])),
      Positioned(bottom: 58, child: Text(nearestStore?.name ?? 'Your current location', style: const TextStyle(color: AppColors.text2))),
    ])),
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
      case 'groceries': return '🛒';
      case 'fuel': return '⛽';
      case 'health': return '💊';
      default: return '🏪';
    }
  }
}

class _SwitchTile extends StatelessWidget { const _SwitchTile({required this.icon, required this.title, required this.subtitle, required this.value, required this.onChanged}); final String icon,title,subtitle; final bool value; final ValueChanged<bool> onChanged; @override Widget build(BuildContext context)=>Container(margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: AppColors.bg3, borderRadius: BorderRadius.circular(18)), child: Row(children:[Text(icon, style: const TextStyle(fontSize: 26)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[Text(title, style: const TextStyle(fontWeight: FontWeight.w800)), Text(subtitle, style: const TextStyle(color: AppColors.text2, fontSize: 12))])), Switch(value: value, activeThumbColor: AppColors.green, onChanged: onChanged)])); }
class _Nearby extends StatelessWidget { const _Nearby({required this.icon, required this.name, required this.sub, required this.dist, required this.onTap}); final String icon,name,sub,dist; final VoidCallback onTap; @override Widget build(BuildContext context)=>GestureDetector(onTap: onTap, child: Container(margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: AppColors.bg2, borderRadius: BorderRadius.circular(18)), child: Row(children:[Text(icon, style: const TextStyle(fontSize: 28)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[Text(name, style: const TextStyle(fontWeight: FontWeight.w800)), Text(sub, style: const TextStyle(color: AppColors.text2, fontSize: 12))])), Text(dist, style: const TextStyle(color: AppColors.accent2, fontWeight: FontWeight.w800))]))); }

