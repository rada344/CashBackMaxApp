import 'package:flutter/material.dart';
import '../models/user_model.dart';
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
          onTap: () {},
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
          onPressed: () => Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.splash,
            (_) => false,
          ),
        ),
      ],
    );
  }

  void _editProfile() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bg2,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Edit Profile',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 18),
            CustomInput(
              label: 'Full Name',
              hint: 'Alex Johnson',
              controller: name,
            ),
            CustomInput(
              label: 'Email',
              hint: 'you@email.com',
              controller: email,
            ),
            CustomButton(
              text: 'Save Changes',
              onPressed: () {
                setState(() {
                  widget.user.name = name.text;
                  widget.user.email = email.text;
                });
                widget.onUserChanged();
                Navigator.pop(context);
              },
            ),
          ],
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
