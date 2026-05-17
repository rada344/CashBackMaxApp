import 'package:flutter/material.dart';

class PrivacySecurityScreen extends StatefulWidget {
  const PrivacySecurityScreen({super.key});

  @override
  State<PrivacySecurityScreen> createState() => _PrivacySecurityScreenState();
}

class _PrivacySecurityScreenState extends State<PrivacySecurityScreen> {
  bool biometricLogin = true;
  bool twoFactorAuth = false;
  bool saveLoginSession = true;
  bool dataEncryption = true;
  bool locationSharing = true;
  bool marketingConsent = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0F),
        elevation: 0,
        title: const Text(
          'Privacy & Security',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 10),

          const Column(
            children: [
              Icon(Icons.shield, size: 64, color: Color(0xFF6C63FF)),
              SizedBox(height: 12),
              Text(
                'Protect Your Account',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Manage login security, data privacy, and permission settings for your reward card wallet.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF9CA3AF), height: 1.5),
              ),
            ],
          ),

          const SizedBox(height: 24),

          _sectionTitle('Account Security'),
          _card([
            _switchTile(
              icon: Icons.fingerprint,
              title: 'Biometric login',
              subtitle: 'Use fingerprint or Face ID to sign in securely.',
              value: biometricLogin,
              onChanged: (v) => setState(() => biometricLogin = v),
            ),
            _switchTile(
              icon: Icons.verified_user,
              title: 'Two-factor authentication',
              subtitle: 'Add an extra verification step during login.',
              value: twoFactorAuth,
              onChanged: (v) => setState(() => twoFactorAuth = v),
            ),
            _switchTile(
              icon: Icons.login,
              title: 'Stay logged in',
              subtitle: 'Keep your session active on this device.',
              value: saveLoginSession,
              onChanged: (v) => setState(() => saveLoginSession = v),
            ),
          ]),

          const SizedBox(height: 20),

          _sectionTitle('Data Protection'),
          _card([
            _switchTile(
              icon: Icons.lock,
              title: 'Data encryption',
              subtitle: 'Encrypt saved cards and personal information.',
              value: dataEncryption,
              onChanged: (v) => setState(() => dataEncryption = v),
            ),
            _infoTile(
              icon: Icons.credit_card,
              title: 'Saved card security',
              subtitle:
                  'Only last 4 digits are shown. Sensitive card data is protected.',
            ),
            _infoTile(
              icon: Icons.cloud_sync,
              title: 'Secure cloud sync',
              subtitle:
                  'Card and profile data can be synced securely when internet is available.',
            ),
          ]),

          const SizedBox(height: 20),

          _sectionTitle('Privacy Controls'),
          _card([
            _switchTile(
              icon: Icons.location_on,
              title: 'Location-based recommendations',
              subtitle:
                  'Allow store detection to recommend the best reward card.',
              value: locationSharing,
              onChanged: (v) => setState(() => locationSharing = v),
            ),
            _switchTile(
              icon: Icons.campaign,
              title: 'Marketing offers',
              subtitle: 'Receive promotional reward offers and updates.',
              value: marketingConsent,
              onChanged: (v) => setState(() => marketingConsent = v),
            ),
            _infoTile(
              icon: Icons.visibility_off,
              title: 'Private by design',
              subtitle:
                  'Your data is used only to improve reward recommendations.',
            ),
          ]),

          const SizedBox(height: 20),

          _sectionTitle('Account Actions'),
          _card([
            _actionTile(
              icon: Icons.password,
              title: 'Change password',
              subtitle: 'Update your account password.',
              onTap: () => _showMessage('Change password selected'),
            ),
            _actionTile(
              icon: Icons.download,
              title: 'Download my data',
              subtitle: 'Export your profile, cards, and reward history.',
              onTap: () => _showMessage('Data export requested'),
            ),
            _actionTile(
              icon: Icons.delete_forever,
              title: 'Delete account',
              subtitle: 'Permanently remove your account and saved data.',
              danger: true,
              onTap: () => _showDeleteDialog(),
            ),
          ]),

          const SizedBox(height: 28),

          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C63FF),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: () => _showMessage('Privacy & security settings saved'),
            icon: const Icon(Icons.save, color: Colors.white),
            label: const Text(
              'Save Settings',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 16),
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

  Widget _switchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      activeThumbColor: const Color(0xFF6C63FF),
      secondary: _iconBox(icon),
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

  Widget _infoTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return ListTile(
      leading: _iconBox(icon),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
      ),
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool danger = false,
  }) {
    return ListTile(
      onTap: onTap,
      leading: _iconBox(icon, danger: danger),
      title: Text(
        title,
        style: TextStyle(
          color: danger ? const Color(0xFFEF4444) : Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
      ),
      trailing: const Icon(Icons.chevron_right, color: Color(0xFF5A5A7A)),
    );
  }

  Widget _iconBox(IconData icon, {bool danger = false}) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: danger
            ? const Color(0xFFEF4444).withValues(alpha: 0.15)
            : const Color(0xFF6C63FF).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        icon,
        color: danger ? const Color(0xFFEF4444) : const Color(0xFFA78BFA),
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF13131A),
        title: const Text(
          'Delete Account?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'This action will permanently remove your profile, saved cards, and reward history.',
          style: TextStyle(color: Color(0xFF9CA3AF)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showMessage('Account deletion cancelled for demo');
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Color(0xFFEF4444)),
            ),
          ),
        ],
      ),
    );
  }
}
