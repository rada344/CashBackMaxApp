import 'package:flutter/material.dart';

import '../services/native_notification_service.dart';
import '../services/notification_preferences.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  final _prefs = NotificationPreferences.instance;
  final _native = NativeNotificationService.instance;
  late String _nativePermission = _native.permission;

  late bool smartAlerts = _prefs.smartAlerts;
  late bool storeEntryAlerts = _prefs.storeEntryAlerts;
  late bool rewardOfferAlerts = _prefs.rewardOfferAlerts;
  late bool cashbackAlerts = _prefs.cashbackAlerts;
  late bool expiryAlerts = _prefs.expiryAlerts;
  late bool sound = _prefs.soundEnabled;
  late bool vibration = _prefs.vibrationEnabled;

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
              onChanged: (v) {
                setState(() => smartAlerts = v);
                _prefs.setSmartAlerts(v);
              },
            ),
            _switchTile(
              icon: Icons.location_on,
              title: 'Store entry alerts',
              subtitle: 'Notify only when entering a supported store.',
              value: storeEntryAlerts,
              onChanged: (v) {
                setState(() => storeEntryAlerts = v);
                _prefs.setStoreEntryAlerts(v);
              },
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
              onChanged: (v) {
                setState(() => rewardOfferAlerts = v);
                _prefs.setRewardOfferAlerts(v);
              },
            ),
            _switchTile(
              icon: Icons.attach_money,
              title: 'Cashback updates',
              subtitle: 'Notify when cashback value is available.',
              value: cashbackAlerts,
              onChanged: (v) {
                setState(() => cashbackAlerts = v);
                _prefs.setCashbackAlerts(v);
              },
            ),
            _switchTile(
              icon: Icons.access_time,
              title: 'Expiring rewards',
              subtitle: 'Warn before points or offers expire.',
              value: expiryAlerts,
              onChanged: (v) {
                setState(() => expiryAlerts = v);
                _prefs.setExpiryAlerts(v);
              },
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
              onChanged: (v) {
                setState(() => sound = v);
                _prefs.setSoundEnabled(v);
              },
            ),
            _switchTile(
              icon: Icons.vibration,
              title: 'Vibration',
              subtitle: 'Vibrate when a smart alert appears.',
              value: vibration,
              onChanged: (v) {
                setState(() => vibration = v);
                _prefs.setVibrationEnabled(v);
              },
            ),
          ]),

          const SizedBox(height: 20),
          _sectionTitle('System Notifications'),
          _settingsCard([_systemNotificationTile()]),

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

  Widget _systemNotificationTile() {
    final supported = _native.isSupported;
    final perm = _nativePermission;

    String subtitle;
    String actionLabel;
    Color actionColor = const Color(0xFF6C63FF);
    VoidCallback? onTap;

    if (!supported) {
      subtitle = 'Your browser does not support system notifications.';
      actionLabel = 'Unavailable';
      actionColor = const Color(0xFF5A5A7A);
      onTap = null;
    } else if (perm == 'granted') {
      subtitle = 'Allowed — you\'ll get a system notification when a store is detected.';
      actionLabel = 'Enabled';
      actionColor = const Color(0xFF22C55E);
      onTap = null;
    } else if (perm == 'denied') {
      subtitle = 'Blocked. Change this in your browser site settings.';
      actionLabel = 'Blocked';
      actionColor = const Color(0xFFEF4444);
      onTap = null;
    } else {
      subtitle = 'Show alerts in your system tray when you enter a supported store.';
      actionLabel = 'Enable';
      onTap = () async {
        final result = await _native.requestPermission();
        if (!mounted) return;
        setState(() => _nativePermission = result);
      };
    }

    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: const Color(0xFF6C63FF).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.notifications_active, color: Color(0xFFA78BFA)),
      ),
      title: const Text(
        'System notifications',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: actionColor.withValues(alpha: .15),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: actionColor.withValues(alpha: .35)),
        ),
        child: Text(
          actionLabel,
          style: TextStyle(
            color: actionColor,
            fontWeight: FontWeight.w800,
            fontSize: 11,
          ),
        ),
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
