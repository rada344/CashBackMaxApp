import 'package:geolocator/geolocator.dart';

class SupportedStore {
  const SupportedStore({required this.name, required this.category, required this.latitude, required this.longitude});

  final String name;
  final String category;
  final double latitude;
  final double longitude;
}

class StoreService {
  // Demo store coordinates. Replace/add real store coordinates for final deployment.
  static const List<SupportedStore> supportedStores = [
    SupportedStore(name: 'Woolworths Canberra Centre', category: 'Groceries', latitude: -35.2809, longitude: 149.1300),
    SupportedStore(name: 'Coles Canberra Centre', category: 'Groceries', latitude: -35.2798, longitude: 149.1320),
    SupportedStore(name: 'Caltex Braddon', category: 'Fuel', latitude: -35.2719, longitude: 149.1342),
    SupportedStore(name: 'Chemist Warehouse Canberra', category: 'Health', latitude: -35.2818, longitude: 149.1285),
  ];

  SupportedStore? detectNearestStore(Position position, {double radiusMeters = 250}) {
    SupportedStore? nearest;
    double nearestDistance = double.infinity;

    for (final store in supportedStores) {
      final distance = Geolocator.distanceBetween(position.latitude, position.longitude, store.latitude, store.longitude);
      if (distance < nearestDistance) {
        nearestDistance = distance;
        nearest = store;
      }
    }

    if (nearest != null && nearestDistance <= radiusMeters) {
      return nearest;
    }
    return null;
  }

  double distanceToStore(Position position, SupportedStore store) {
    return Geolocator.distanceBetween(position.latitude, position.longitude, store.latitude, store.longitude);
  }
}

