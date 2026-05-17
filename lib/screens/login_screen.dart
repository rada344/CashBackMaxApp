import 'package:firebase_auth/firebase_auth.dart';
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

  bool _signingIn = false;
  bool _googleLoading = false;

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _login() async {
    final e = email.text.trim();
    final p = password.text;

    if (e.isEmpty) {
      _snack('Please enter your email');
      return;
    }
    if (p.isEmpty) {
      _snack('Please enter your password');
      return;
    }

    setState(() => _signingIn = true);
    try {
      await auth.login(email: e, password: p);
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    } on FirebaseAuthException catch (err) {
      debugPrint('Login error: code=${err.code} message=${err.message}');
      if (!mounted) return;
      _snack(_mapLoginError(err));
    } catch (err) {
      debugPrint('Login unexpected error: $err');
      if (!mounted) return;
      _snack('Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _signingIn = false);
    }
  }

  String _mapLoginError(FirebaseAuthException err) {
    switch (err.code) {
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
        return 'No account found for that email.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'too-many-requests':
        return 'Too many attempts. Try again later.';
      case 'network-request-failed':
        return 'Network error. Check your connection and try again.';
      default:
        return 'Sign-in failed (${err.code}).';
    }
  }

  void _showResetSheet() {
    final resetCtrl = TextEditingController(text: email.text.trim());
    bool sending = false;
    String? errorMsg;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bg2,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 24,
          ),
          child: StatefulBuilder(
            builder: (innerCtx, setSheetState) {
              Future<void> send() async {
                final value = resetCtrl.text.trim();
                if (value.isEmpty) {
                  setSheetState(() => errorMsg = 'Please enter your email');
                  return;
                }
                final navigator = Navigator.of(sheetCtx);
                setSheetState(() {
                  sending = true;
                  errorMsg = null;
                });
                try {
                  await auth.resetPassword(value);
                  if (!mounted) return;
                  navigator.pop();
                  _snack('Reset link sent to $value');
                } on FirebaseAuthException catch (err) {
                  debugPrint('Reset error: code=${err.code} message=${err.message}');
                  String msg;
                  switch (err.code) {
                    case 'invalid-email':
                      msg = 'Please enter a valid email address.';
                      break;
                    case 'user-not-found':
                      msg = 'No account found for that email.';
                      break;
                    default:
                      msg = 'Could not send reset email (${err.code}).';
                  }
                  setSheetState(() {
                    sending = false;
                    errorMsg = msg;
                  });
                } catch (err) {
                  debugPrint('Reset unexpected error: $err');
                  setSheetState(() {
                    sending = false;
                    errorMsg = 'Could not send reset email. Try again.';
                  });
                }
              }

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Reset Password',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Enter the email for your account and we'll send you a reset link.",
                    style: TextStyle(color: AppColors.text2, height: 1.4),
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
                    label: 'Email',
                    hint: 'you@email.com',
                    controller: resetCtrl,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 8),
                  CustomButton(
                    text: sending ? 'Sending…' : 'Send Reset Link',
                    loading: sending,
                    onPressed: send,
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

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

            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _showResetSheet,
                child: const Text(
                  'Forgot password?',
                  style: TextStyle(
                    color: AppColors.accent2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            CustomButton(
              text: _signingIn ? 'Signing in…' : 'Sign In',
              loading: _signingIn,
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
                    loading: _googleLoading,
                    onTap: () async {
                      if (_googleLoading) return;
                      final navigator = Navigator.of(context);
                      setState(() => _googleLoading = true);
                      try {
                        final result = await auth.signInWithGoogle();
                        if (!mounted) return;
                        if (result != null) {
                          navigator.pushReplacementNamed(AppRoutes.home);
                        }
                      } finally {
                        if (mounted) setState(() => _googleLoading = false);
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
    this.loading = false,
  });

  final String label;
  final IconData? icon;
  final VoidCallback onTap;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: loading ? null : onTap,
      icon: loading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(icon),
      label: Text(loading ? 'Signing in…' : label),
    );
  }
}
