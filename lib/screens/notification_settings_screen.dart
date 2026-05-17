import 'package:flutter/material.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  bool smartAlerts = true;
  bool storeEntryAlerts = true;
  bool rewardOfferAlerts = true;
  bool cashbackAlerts = true;
  bool expiryAlerts = true;
  bool sound = false;
  bool vibration = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0F),
        elevation: 0,
        title: const Text(
          'Notification Settings',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Control how RewardMax notifies you about store detection, rewards, cashback, and expiring offers.',
            style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
          ),
          const SizedBox(height: 20),

          _sectionTitle('Smart Alerts'),
          _settingsCard([
            _switchTile(
              icon: Icons.notifications_active,
              title: 'Smart reward alerts',
              subtitle: 'Recommend the best card when you enter a store.',
              value: smartAlerts,
              onChanged: (v) => setState(() => smartAlerts = v),
            ),
            _switchTile(
              icon: Icons.location_on,
              title: 'Store entry alerts',
              subtitle: 'Notify only when entering a supported store.',
              value: storeEntryAlerts,
              onChanged: (v) => setState(() => storeEntryAlerts = v),
            ),
          ]),

          const SizedBox(height: 20),
          _sectionTitle('Reward Updates'),
          _settingsCard([
            _switchTile(
              icon: Icons.local_offer,
              title: 'Reward offers',
              subtitle: 'Get alerts for bonus points and special deals.',
              value: rewardOfferAlerts,
              onChanged: (v) => setState(() => rewardOfferAlerts = v),
            ),
            _switchTile(
              icon: Icons.attach_money,
              title: 'Cashback updates',
              subtitle: 'Notify when cashback value is available.',
              value: cashbackAlerts,
              onChanged: (v) => setState(() => cashbackAlerts = v),
            ),
            _switchTile(
              icon: Icons.access_time,
              title: 'Expiring rewards',
              subtitle: 'Warn before points or offers expire.',
              value: expiryAlerts,
              onChanged: (v) => setState(() => expiryAlerts = v),
            ),
          ]),

          const SizedBox(height: 20),
          _sectionTitle('Alert Preferences'),
          _settingsCard([
            _switchTile(
              icon: Icons.volume_up,
              title: 'Sound',
              subtitle: 'Play sound for important reward alerts.',
              value: sound,
              onChanged: (v) => setState(() => sound = v),
            ),
            _switchTile(
              icon: Icons.vibration,
              title: 'Vibration',
              subtitle: 'Vibrate when a smart alert appears.',
              value: vibration,
              onChanged: (v) => setState(() => vibration = v),
            ),
          ]),

          const SizedBox(height: 24),

          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C63FF),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notification settings saved')),
              );
            },
            icon: const Icon(Icons.save, color: Colors.white),
            label: const Text(
              'Save Settings',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

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

  Widget _settingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF13131A),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(children: children),
    );
  }

  Widget _switchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      activeThumbColor: const Color(0xFF6C63FF),
      secondary: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: const Color(0xFF6C63FF).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: const Color(0xFFA78BFA)),
      ),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
      ),
      value: value,
      onChanged: onChanged,
    );
  }
}
