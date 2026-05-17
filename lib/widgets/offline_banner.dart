import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../services/connectivity_service.dart';
import '../utils/app_colors.dart';

/// Slim status banner that appears at the top of the screen when offline.
/// Defaults to reading from [ConnectivityService.instance] but accepts an
/// override via [isOnline] for tests.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key, this.isOnline});

  final ValueListenable<bool>? isOnline;

  @override
  Widget build(BuildContext context) {
    final source = isOnline ?? ConnectivityService.instance.isOnline;
    return ValueListenableBuilder<bool>(
      valueListenable: source,
      builder: (_, online, __) {
        if (online) return const SizedBox.shrink();
        return Material(
          color: Colors.transparent,
          child: SafeArea(
            bottom: false,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppColors.red.withValues(alpha: .92),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cloud_off_rounded, color: Colors.white, size: 16),
                  SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      "You're offline — changes will sync when you reconnect.",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
