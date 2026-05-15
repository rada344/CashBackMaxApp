import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../services/location_service.dart';
import '../services/store_service.dart';
import '../utils/app_colors.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({
    super.key,
    this.onManualStoreSelected,
  });

  final ValueChanged<SupportedStore>?
      onManualStoreSelected;

  @override
  State<MapScreen> createState() =>
      _MapScreenState();
}

class _MapScreenState
    extends State<MapScreen> {

  bool geofence = true;
  bool notifications = true;

  String status =
      'Location not checked yet';

  SupportedStore? nearestStore;

  bool loading = false;

  final locationService =
      LocationService();

  final storeService =
      StoreService();

  GoogleMapController? _mapController;

  static const CameraPosition
      _initialPosition =
      CameraPosition(
    target: LatLng(
      -35.2809,
      149.1300,
    ),
    zoom: 12,
  );

  Future<void> detectLocation() async {

  setState(() => loading = true);

  try {

    final position =
        await locationService
            .getCurrentLocation();

    final store =
        storeService
            .detectNearestStore(
      position,
    );

    // MOVE MAP CAMERA
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(
          position.latitude,
          position.longitude,
        ),
        15,
      ),
    );

    setState(() {

      nearestStore = store;

      status = store == null
          ? 'No supported store found within geofence radius.'
          : '${store.name} detected near your current location.';
    });

  } catch (e) {

    setState(() {

      status = e
          .toString()
          .replaceFirst(
            'Exception: ',
            '',
          );
    });

  } finally {

    if (mounted) {

      setState(
        () => loading = false,
      );
    }
  }
}

  @override
  Widget build(BuildContext context) {

    return ListView(

      padding:
          const EdgeInsets.fromLTRB(
        20,
        12,
        20,
        24,
      ),

      children: [

        const Text(
          'Location',
          style: TextStyle(
            fontSize: 26,
            fontWeight:
                FontWeight.w900,
          ),
        ),

        const Text(
          'Real-time detection + manual fallback',
          style: TextStyle(
            color: AppColors.text2,
          ),
        ),

        const SizedBox(height: 18),

        // GOOGLE MAP
        Container(

          height: 230,

          decoration: BoxDecoration(
            borderRadius:
                BorderRadius.circular(
              24,
            ),
          ),

          clipBehavior:
              Clip.hardEdge,

          child: GoogleMap(

            initialCameraPosition:
                _initialPosition,

            myLocationEnabled: true,

            myLocationButtonEnabled:
                true,

            onMapCreated:
                (controller) {

              _mapController =
                  controller;
            },

            markers: {

              Marker(

                markerId:
                    const MarkerId(
                  'canberra',
                ),

                position:
                    const LatLng(
                  -35.2809,
                  149.1300,
                ),

                infoWindow:
                    const InfoWindow(
                  title: 'Canberra',
                ),
              ),
            },
          ),
        ),

        const SizedBox(height: 16),

        Container(

          padding:
              const EdgeInsets.all(
            14,
          ),

          decoration: BoxDecoration(
            color: AppColors.bg2,
            borderRadius:
                BorderRadius.circular(
              18,
            ),
          ),

          child: Row(
            children: [

              const Icon(
                Icons
                    .my_location_rounded,
                color:
                    AppColors.accent2,
              ),

              const SizedBox(
                width: 12,
              ),

              Expanded(
                child: Text(
                  status,
                  style:
                      const TextStyle(
                    color:
                        AppColors
                            .text2,
                  ),
                ),
              ),

              FilledButton(

                onPressed: loading
                    ? null
                    : detectLocation,

                style:
                    FilledButton
                        .styleFrom(
                  backgroundColor:
                      AppColors
                          .accent,
                ),

                child: loading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child:
                            CircularProgressIndicator(
                          strokeWidth:
                              2,
                        ),
                      )
                    : const Text(
                        'Detect',
                      ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        _SwitchTile(
          icon: '📍',
          title: 'Geofencing',
          subtitle:
              'Auto-detect supported stores',
          value: geofence,
          onChanged: (v) {
            setState(
              () => geofence = v,
            );
          },
        ),

        _SwitchTile(
          icon: '🔔',
          title:
              'Smart Notifications',
          subtitle:
              'Alert on store entry only',
          value: notifications,
          onChanged: (v) {
            setState(
              () =>
                  notifications = v,
            );
          },
        ),

        const SizedBox(height: 18),

        const Text(
          'Supported Stores Nearby',
          style: TextStyle(
            fontSize: 17,
            fontWeight:
                FontWeight.w800,
          ),
        ),

        const SizedBox(height: 12),

        ...StoreService
            .supportedStores
            .map(

          (store) => _Nearby(

            icon:
                _iconForCategory(
              store.category,
            ),

            name: store.name,

            sub:
                '${store.category} · active geofence · tap for manual fallback',

            dist:
                nearestStore?.name ==
                        store.name
                    ? 'Active'
                    : 'Select',

            onTap: () {

              widget
                  .onManualStoreSelected
                  ?.call(store);
            },
          ),
        ),
      ],
    );
  }

  String _iconForCategory(
    String category,
  ) {

    switch (
        category.toLowerCase()) {

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

class _SwitchTile
    extends StatelessWidget {

  const _SwitchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String icon;
  final String title;
  final String subtitle;

  final bool value;

  final ValueChanged<bool>
      onChanged;

  @override
  Widget build(
      BuildContext context) {

    return Container(

      margin:
          const EdgeInsets.only(
        bottom: 10,
      ),

      padding:
          const EdgeInsets.all(
        14,
      ),

      decoration: BoxDecoration(
        color: AppColors.bg3,
        borderRadius:
            BorderRadius.circular(
          18,
        ),
      ),

      child: Row(
        children: [

          Text(
            icon,
            style:
                const TextStyle(
              fontSize: 26,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
              children: [

                Text(
                  title,
                  style:
                      const TextStyle(
                    fontWeight:
                        FontWeight
                            .w800,
                  ),
                ),

                Text(
                  subtitle,
                  style:
                      const TextStyle(
                    color:
                        AppColors
                            .text2,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          Switch(
            value: value,
            activeThumbColor:
                AppColors.green,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _Nearby
    extends StatelessWidget {

  const _Nearby({
    required this.icon,
    required this.name,
    required this.sub,
    required this.dist,
    required this.onTap,
  });

  final String icon;
  final String name;
  final String sub;
  final String dist;

  final VoidCallback onTap;

  @override
  Widget build(
      BuildContext context) {

    return GestureDetector(

      onTap: onTap,

      child: Container(

        margin:
            const EdgeInsets.only(
          bottom: 10,
        ),

        padding:
            const EdgeInsets.all(
          14,
        ),

        decoration:
            BoxDecoration(
          color: AppColors.bg2,
          borderRadius:
              BorderRadius.circular(
            18,
          ),
        ),

        child: Row(
          children: [

            Text(
              icon,
              style:
                  const TextStyle(
                fontSize: 28,
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                children: [

                  Text(
                    name,
                    style:
                        const TextStyle(
                      fontWeight:
                          FontWeight
                              .w800,
                    ),
                  ),

                  Text(
                    sub,
                    style:
                        const TextStyle(
                      color:
                          AppColors
                              .text2,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            Text(
              dist,
              style:
                  const TextStyle(
                color:
                    AppColors.accent2,
                fontWeight:
                    FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}