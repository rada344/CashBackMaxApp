import 'package:flutter/material.dart';

class LocationPermissionScreen extends StatefulWidget {
  const LocationPermissionScreen({super.key});

  @override
  State<LocationPermissionScreen> createState() =>
      _LocationPermissionScreenState();
}

class _LocationPermissionScreenState
    extends State<LocationPermissionScreen> {
  bool allowWhileUsing = true;
  bool allowAlways = false;
  bool preciseLocation = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0F),
        elevation: 0,
        title: const Text(
          'Location Permissions',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 10),

          /// 🔹 Header
          const Column(
            children: [
              Icon(Icons.location_on, size: 60, color: Color(0xFF6C63FF)),
              SizedBox(height: 12),
              Text(
                'Enable Location Access',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 6),
              Text(
                'We use your location to detect nearby stores and recommend the best reward card in real-time.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF9CA3AF)),
              ),
            ],
          ),

          const SizedBox(height: 24),

          /// 🔹 Permission Options
          _sectionTitle('Permission Level'),
          _card([
            _radioTile(
              title: 'Allow while using app',
              subtitle: 'Recommended for best experience',
              value: allowWhileUsing,
              onTap: () {
                setState(() {
                  allowWhileUsing = true;
                  allowAlways = false;
                });
              },
            ),
            _radioTile(
              title: 'Allow all the time',
              subtitle: 'Enable background recommendations',
              value: allowAlways,
              onTap: () {
                setState(() {
                  allowAlways = true;
                  allowWhileUsing = false;
                });
              },
            ),
          ]),

          const SizedBox(height: 20),

          /// 🔹 Precision
          _sectionTitle('Location Accuracy'),
          _card([
            SwitchListTile(
              activeThumbColor: const Color(0xFF6C63FF),
              title: const Text(
                'Precise Location',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: const Text(
                'Improves store detection accuracy',
                style: TextStyle(color: Color(0xFF9CA3AF)),
              ),
              value: preciseLocation,
              onChanged: (v) => setState(() => preciseLocation = v),
            ),
          ]),

          const SizedBox(height: 20),

          /// 🔹 Info
          _sectionTitle('Why We Need Location'),
          _card([
            const ListTile(
              leading: Icon(Icons.store, color: Color(0xFFA78BFA)),
              title: Text('Detect nearby stores',
                  style: TextStyle(color: Colors.white)),
            ),
            const ListTile(
              leading: Icon(Icons.credit_card, color: Color(0xFFA78BFA)),
              title: Text('Recommend best reward card',
                  style: TextStyle(color: Colors.white)),
            ),
            const ListTile(
              leading: Icon(Icons.notifications, color: Color(0xFFA78BFA)),
              title: Text('Send smart alerts',
                  style: TextStyle(color: Colors.white)),
            ),
          ]),

          const SizedBox(height: 30),

          /// 🔹 Button
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C63FF),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(Icons.check, color: Colors.white),
            label: const Text(
              'Allow Location Access',
              style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  /// 🔹 Section Title
  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: Color(0xFF6C63FF),
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
    );
  }

  /// 🔹 Card Container
  Widget _card(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF13131A),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(children: children),
    );
  }

  /// 🔹 Custom Radio Tile
  Widget _radioTile({
    required String title,
    required String subtitle,
    required bool value,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Icon(
        value ? Icons.radio_button_checked : Icons.radio_button_off,
        color: const Color(0xFF6C63FF),
      ),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      subtitle: Text(subtitle,
          style: const TextStyle(color: Color(0xFF9CA3AF))),
    );
  }
}
