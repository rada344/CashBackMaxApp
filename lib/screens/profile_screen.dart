import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../services/notification_log_service.dart';
import '../services/notification_preferences.dart';
import '../services/privacy_preferences.dart';
import '../utils/app_colors.dart';
import '../utils/app_routes.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_input.dart';
import 'notification_settings_screen.dart';
import 'location_permission_screen.dart';
import 'privacy_security_screen.dart';
import 'users_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    required this.user,
    required this.cardCount,
    required this.onUserChanged,
  });

  final UserModel user;
  final int cardCount;
  final VoidCallback onUserChanged;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final TextEditingController name =
      TextEditingController(text: widget.user.name);
  late final TextEditingController email =
      TextEditingController(text: widget.user.email);

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        Column(
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.primaryGradient,
              ),
              child: Center(
                child: Text(
                  widget.user.initials,
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              widget.user.name,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
            Text(
              widget.user.email,
              style: const TextStyle(color: AppColors.text2),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            _Stat(value: widget.cardCount.toString(), label: 'Saved Cards'),
          ],
        ),
        const SizedBox(height: 22),
        const _Section(label: 'Account'),
        _Setting(
          icon: '👤',
          label: 'Edit Profile',
          onTap: _editProfile,
        ),
        _Setting(
          icon: '🔑',
          label: 'Change Password',
          onTap: _changePassword,
        ),
        const SizedBox(height: 18),
        const _Section(label: 'Preferences'),
        _Setting(
          icon: '🔔',
          label: 'Notification Settings',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const NotificationSettingsScreen(),
              ),
            );
          },
        ),
        _Setting(
          icon: '📍',
          label: 'Location Permissions',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const LocationPermissionScreen(),
              ),
            );
          },
        ),
        _Setting(
          icon: '🔐',
          label: 'Privacy & Security',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const PrivacySecurityScreen(),
              ),
            );
          },
        ),
        _Setting(
          icon: '👥',
          label: 'View Firebase Users',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const UsersScreen(),
              ),
            );
          },
        ),
        const SizedBox(height: 18),
        CustomButton(
          text: 'Log Out',
          danger: true,
          onPressed: () async {
            final navigator = Navigator.of(context);
            await AuthService().logout();
            await Future.wait([
              NotificationLog.instance.clearLocal(),
              NotificationPreferences.instance.clearLocal(),
              PrivacyPreferences.instance.clearLocal(),
              DatabaseService.instance.clearLocal(),
            ]);
            if (!mounted) return;
            navigator.pushNamedAndRemoveUntil(AppRoutes.splash, (_) => false);
          },
        ),
      ],
    );
  }

  void _editProfile() {
    bool saving = false;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bg2,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetCtx) => Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          MediaQuery.of(sheetCtx).viewInsets.bottom + 24,
        ),
        child: StatefulBuilder(
          builder: (innerCtx, setSheetState) {
            Future<void> save() async {
              final navigator = Navigator.of(sheetCtx);
              final messenger = ScaffoldMessenger.of(innerCtx);
              final outerMessenger = ScaffoldMessenger.of(context);
              final n = name.text.trim();
              if (n.isEmpty) {
                messenger
                  ..hideCurrentSnackBar()
                  ..showSnackBar(const SnackBar(content: Text('Name cannot be empty')));
                return;
              }

              setSheetState(() => saving = true);
              try {
                await AuthService().updateDisplayName(n);
                if (!mounted) return;
                setState(() => widget.user.name = n);
                widget.onUserChanged();
                navigator.pop();
                outerMessenger
                  ..hideCurrentSnackBar()
                  ..showSnackBar(SnackBar(
                    content: const Text('Profile updated'),
                    backgroundColor: AppColors.green.withValues(alpha: .9),
                  ));
              } catch (e) {
                setSheetState(() => saving = false);
                if (!mounted) return;
                messenger
                  ..hideCurrentSnackBar()
                  ..showSnackBar(SnackBar(content: Text('Save failed: $e')));
              }
            }

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Edit Profile',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Email is your sign-in identifier and can\'t be changed here.',
                  style: TextStyle(color: AppColors.text2, fontSize: 13),
                ),
                const SizedBox(height: 18),
                CustomInput(
                  label: 'Full Name',
                  hint: 'Alex Johnson',
                  controller: name,
                ),
                IgnorePointer(
                  child: Opacity(
                    opacity: .55,
                    child: CustomInput(
                      label: 'Email',
                      hint: 'you@email.com',
                      controller: email,
                    ),
                  ),
                ),
                CustomButton(
                  text: saving ? 'Saving…' : 'Save Changes',
                  loading: saving,
                  onPressed: save,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _changePassword() {
    final auth = AuthService();
    if (!auth.hasEmailPasswordProvider) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(
          content: Text(
            "You signed in with Google. Manage your password through Google.",
          ),
        ));
      return;
    }

    final current = TextEditingController();
    final newPwd = TextEditingController();
    final confirmPwd = TextEditingController();
    bool saving = false;
    String? errorMsg;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bg2,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetCtx) => Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          MediaQuery.of(sheetCtx).viewInsets.bottom + 24,
        ),
        child: StatefulBuilder(
          builder: (innerCtx, setSheetState) {
            Future<void> submit() async {
              final navigator = Navigator.of(sheetCtx);
              final outerMessenger = ScaffoldMessenger.of(context);

              if (current.text.isEmpty) {
                setSheetState(() => errorMsg = 'Enter your current password');
                return;
              }
              if (newPwd.text.length < 6) {
                setSheetState(() => errorMsg = 'New password must be at least 6 characters');
                return;
              }
              if (newPwd.text != confirmPwd.text) {
                setSheetState(() => errorMsg = 'New password and confirmation do not match');
                return;
              }
              if (newPwd.text == current.text) {
                setSheetState(() => errorMsg = 'New password must be different from current');
                return;
              }

              setSheetState(() {
                saving = true;
                errorMsg = null;
              });
              try {
                await auth.changePassword(
                  currentPassword: current.text,
                  newPassword: newPwd.text,
                );
                if (!mounted) return;
                navigator.pop();
                outerMessenger
                  ..hideCurrentSnackBar()
                  ..showSnackBar(SnackBar(
                    content: const Text('Password updated'),
                    backgroundColor: AppColors.green.withValues(alpha: .9),
                  ));
              } on FirebaseAuthException catch (err) {
                String msg;
                switch (err.code) {
                  case 'wrong-password':
                  case 'invalid-credential':
                    msg = 'Current password is incorrect.';
                    break;
                  case 'weak-password':
                    msg = 'New password is too weak.';
                    break;
                  case 'requires-recent-login':
                    msg = 'Please sign in again before changing your password.';
                    break;
                  case 'too-many-requests':
                    msg = 'Too many attempts. Try again later.';
                    break;
                  case 'network-request-failed':
                    msg = 'Network error. Check your connection.';
                    break;
                  default:
                    msg = 'Could not update password (${err.code}).';
                }
                setSheetState(() {
                  saving = false;
                  errorMsg = msg;
                });
              } catch (e) {
                setSheetState(() {
                  saving = false;
                  errorMsg = 'Could not update password: $e';
                });
              }
            }

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Change Password',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 6),
                const Text(
                  'For your security, enter your current password first.',
                  style: TextStyle(color: AppColors.text2, fontSize: 13),
                ),
                const SizedBox(height: 18),
                if (errorMsg != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                  const SizedBox(height: 14),
                ],
                CustomInput(
                  label: 'Current Password',
                  hint: '••••••••',
                  controller: current,
                  obscureText: true,
                ),
                CustomInput(
                  label: 'New Password',
                  hint: 'At least 6 characters',
                  controller: newPwd,
                  obscureText: true,
                ),
                CustomInput(
                  label: 'Confirm New Password',
                  hint: 'Repeat new password',
                  controller: confirmPwd,
                  obscureText: true,
                ),
                CustomButton(
                  text: saving ? 'Updating…' : 'Update Password',
                  loading: saving,
                  onPressed: submit,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.bg2,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
            ),
            Text(
              label,
              style: const TextStyle(color: AppColors.text2, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          color: AppColors.text3,
          fontSize: 12,
          fontWeight: FontWeight.w900,
          letterSpacing: .8,
        ),
      ),
    );
  }
}

class _Setting extends StatelessWidget {
  const _Setting({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final String icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      child: ListTile(
        onTap: onTap,
        tileColor: AppColors.bg2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        leading: Text(icon, style: const TextStyle(fontSize: 24)),
        title: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        trailing: const Icon(Icons.chevron_right, color: AppColors.text3),
      ),
    );
  }
}
