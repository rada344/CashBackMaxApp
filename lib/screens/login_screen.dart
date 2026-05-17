import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../utils/app_colors.dart';
import '../utils/app_routes.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_input.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final email = TextEditingController();
  final password = TextEditingController();
  final auth = AuthService();

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  void _login() {
    auth.login(
      email: email.text.trim(),
      password: password.text,
    );
    Navigator.pushReplacementNamed(context, AppRoutes.home);
  }

  // ================= SOCIAL LOGIN =================

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 40),

            const Text(
              'Sign in',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 20),

            CustomInput(
              label: 'Email',
              hint: 'you@email.com',
              controller: email,
            ),

            CustomInput(
              label: 'Password',
              hint: '••••••••',
              controller: password,
              obscureText: true,
            ),

            const SizedBox(height: 10),

            CustomButton(
              text: 'Sign In',
              onPressed: _login,
            ),

            const SizedBox(height: 20),

            const Row(
              children: [
                Expanded(child: Divider()),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('or'),
                ),
                Expanded(child: Divider()),
              ],
            ),

            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
  child: _SocialButton(
    icon: Icons.g_mobiledata,
    label: 'Google',
    onTap: () async {
      final result = await auth.signInWithGoogle();

      if (result != null && context.mounted) {
        Navigator.pushReplacementNamed(
          context,
          AppRoutes.home,
        );
      }
    },
  ),
),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.label,
    required this.onTap,
    this.icon,
  });

  final String label;
  final IconData? icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(label),
    );
  }
}
