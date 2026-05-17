import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../services/notification_log_service.dart';
import '../services/notification_preferences.dart';
import '../services/privacy_preferences.dart';
import '../utils/app_colors.dart';
import '../utils/app_routes.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_input.dart';

class PrivacySecurityScreen extends StatefulWidget {
  const PrivacySecurityScreen({super.key});

  @override
  State<PrivacySecurityScreen> createState() => _PrivacySecurityScreenState();
}

class _PrivacySecurityScreenState extends State<PrivacySecurityScreen> {
  final _prefs = PrivacyPreferences.instance;
  final _auth = AuthService();

  late bool locationBasedRecs = _prefs.locationBasedRecommendations;
  late bool marketingConsent = _prefs.marketingConsent;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
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
              Icon(Icons.shield, size: 64, color: AppColors.accent),
              SizedBox(height: 12),
              Text(
                'Protect Your Account',
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Control how CashBackMax uses your location and reaches you, and manage your account data.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.text2, height: 1.5),
              ),
            ],
          ),
          const SizedBox(height: 24),

          _sectionTitle('How Your Data Is Protected'),
          _card([
            _infoTile(
              icon: Icons.credit_card,
              title: 'Saved card security',
              subtitle:
                  'Only the last 4 digits are ever stored. Full card numbers are never collected.',
            ),
            _infoTile(
              icon: Icons.lock_outline,
              title: 'Encrypted in transit',
              subtitle:
                  'All communication with Firebase uses TLS. Cloud data is restricted to your account.',
            ),
            _infoTile(
              icon: Icons.cloud_sync,
              title: 'Secure cloud sync',
              subtitle:
                  'Your wallet, alerts, and preferences sync to your private Firestore collection.',
            ),
          ]),

          const SizedBox(height: 20),

          _sectionTitle('Privacy Controls'),
          _card([
            _switchTile(
              icon: Icons.location_on,
              title: 'Location-based recommendations',
              subtitle:
                  'Use device location to detect supported stores and suggest the best card.',
              value: locationBasedRecs,
              onChanged: (v) {
                setState(() => locationBasedRecs = v);
                _prefs.setLocationBasedRecommendations(v);
              },
            ),
            _switchTile(
              icon: Icons.campaign,
              title: 'Marketing offers',
              subtitle: 'Allow promotional reward offers and announcements.',
              value: marketingConsent,
              onChanged: (v) {
                setState(() => marketingConsent = v);
                _prefs.setMarketingConsent(v);
              },
            ),
          ]),

          const SizedBox(height: 20),

          _sectionTitle('Account Actions'),
          _card([
            _actionTile(
              icon: Icons.download,
              title: 'Download my data',
              subtitle: 'Export your profile, cards, and notifications as JSON.',
              onTap: _downloadData,
            ),
            _actionTile(
              icon: Icons.delete_forever,
              title: 'Delete account',
              subtitle: 'Permanently remove your account and all saved data.',
              danger: true,
              onTap: _confirmDelete,
            ),
          ]),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ─── Download my data ────────────────────────────────────────────

  Future<void> _downloadData() async {
    final messenger = ScaffoldMessenger.of(context);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      messenger.showSnackBar(const SnackBar(content: Text('Not signed in')));
      return;
    }

    final cards = DatabaseService.instance.getCards(user.uid);
    final notifications = NotificationLog.instance.entries.value;
    final notifPrefs = NotificationPreferences.instance;
    final privacyPrefs = PrivacyPreferences.instance;

    final payload = <String, dynamic>{
      'exportedAt': DateTime.now().toIso8601String(),
      'user': {
        'uid': user.uid,
        'email': user.email,
        'displayName': user.displayName,
      },
      'cards': cards.map((c) => c.toJson()).toList(),
      'notifications': notifications.map((n) => n.toJson()).toList(),
      'preferences': {
        'notifications': {
          'smartAlerts': notifPrefs.smartAlerts,
          'storeEntryAlerts': notifPrefs.storeEntryAlerts,
          'rewardOfferAlerts': notifPrefs.rewardOfferAlerts,
          'cashbackAlerts': notifPrefs.cashbackAlerts,
          'expiryAlerts': notifPrefs.expiryAlerts,
          'soundEnabled': notifPrefs.soundEnabled,
          'vibrationEnabled': notifPrefs.vibrationEnabled,
        },
        'privacy': {
          'locationBasedRecommendations': privacyPrefs.locationBasedRecommendations,
          'marketingConsent': privacyPrefs.marketingConsent,
        },
      },
    };

    final pretty = const JsonEncoder.withIndent('  ').convert(payload);

    if (!mounted) return;
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.bg2,
        title: const Text(
          'Your data',
          style: TextStyle(color: AppColors.text),
        ),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: SelectableText(
              pretty,
              style: const TextStyle(
                color: AppColors.text2,
                fontFamily: 'monospace',
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: pretty));
              if (!dialogCtx.mounted) return;
              Navigator.pop(dialogCtx);
              messenger.showSnackBar(const SnackBar(
                content: Text('Copied to clipboard'),
              ));
            },
            child: const Text(
              'Copy',
              style: TextStyle(color: AppColors.accent2, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Delete account ───────────────────────────────────────────────

  void _confirmDelete() {
    if (!_auth.hasEmailPasswordProvider) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text(
          "Sign in with email & password to confirm account deletion.",
        ),
      ));
      return;
    }

    final passwordCtrl = TextEditingController();
    bool deleting = false;
    String? errorMsg;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (innerCtx, setDialogState) {
          Future<void> proceed() async {
            final rootNavigator = Navigator.of(context, rootNavigator: true);
            if (passwordCtrl.text.isEmpty) {
              setDialogState(() => errorMsg = 'Enter your password to confirm.');
              return;
            }
            setDialogState(() {
              deleting = true;
              errorMsg = null;
            });
            try {
              await _auth.deleteAccount(currentPassword: passwordCtrl.text);
              // Wipe ALL local caches so next sign-up starts clean.
              await Future.wait([
                NotificationLog.instance.clearLocal(),
                NotificationPreferences.instance.clearLocal(),
                PrivacyPreferences.instance.clearLocal(),
                DatabaseService.instance.clearLocal(),
              ]);
              if (!mounted) return;
              rootNavigator.pushNamedAndRemoveUntil(
                AppRoutes.splash,
                (_) => false,
              );
            } on FirebaseAuthException catch (err) {
              String msg;
              switch (err.code) {
                case 'wrong-password':
                case 'invalid-credential':
                  msg = 'Password is incorrect.';
                  break;
                case 'requires-recent-login':
                  msg = 'Please sign in again, then retry.';
                  break;
                case 'too-many-requests':
                  msg = 'Too many attempts. Try again later.';
                  break;
                case 'network-request-failed':
                  msg = 'Network error. Check your connection.';
                  break;
                default:
                  msg = 'Could not delete account (${err.code}).';
              }
              setDialogState(() {
                deleting = false;
                errorMsg = msg;
              });
            } catch (e) {
              setDialogState(() {
                deleting = false;
                errorMsg = 'Could not delete account: $e';
              });
            }
          }

          return AlertDialog(
            backgroundColor: AppColors.bg2,
            title: const Text(
              'Delete account?',
              style: TextStyle(color: AppColors.text),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'This permanently removes your profile, saved cards, notifications, and preferences. It cannot be undone.',
                  style: TextStyle(color: AppColors.text2, height: 1.5),
                ),
                const SizedBox(height: 14),
                if (errorMsg != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.red.withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.red.withValues(alpha: .35)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: AppColors.red, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            errorMsg!,
                            style: const TextStyle(
                              color: AppColors.red,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                CustomInput(
                  label: 'Confirm password',
                  hint: '••••••••',
                  controller: passwordCtrl,
                  obscureText: true,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: deleting ? null : () => Navigator.pop(dialogCtx),
                child: const Text('Cancel'),
              ),
              SizedBox(
                width: 180,
                child: CustomButton(
                  text: deleting ? 'Deleting…' : 'Delete account',
                  danger: true,
                  loading: deleting,
                  onPressed: proceed,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ─── UI helpers ──────────────────────────────────────────────────

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: AppColors.accent,
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
        color: AppColors.bg2,
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
      activeThumbColor: AppColors.accent,
      secondary: _iconBox(icon),
      title: Text(
        title,
        style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: AppColors.text2, fontSize: 12),
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
        style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: AppColors.text2, fontSize: 12),
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
          color: danger ? AppColors.red : AppColors.text,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: AppColors.text2, fontSize: 12),
      ),
      trailing: const Icon(Icons.chevron_right, color: AppColors.text3),
    );
  }

  Widget _iconBox(IconData icon, {bool danger = false}) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: danger
            ? AppColors.red.withValues(alpha: 0.15)
            : AppColors.accent.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        icon,
        color: danger ? AppColors.red : AppColors.accent2,
      ),
    );
  }
}
