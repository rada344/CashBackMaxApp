import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../utils/app_colors.dart';
import '../utils/app_routes.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_input.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final name = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  final auth = AuthService();

  bool agreeTerms = false;
  bool isLoading = false;
  bool _googleLoading = false;

  @override
  void dispose() {
    name.dispose();
    email.dispose();
    password.dispose();
    super.dispose();
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _createAccount() async {
    final n = name.text.trim();
    final e = email.text.trim();
    final p = password.text;

    if (n.isEmpty) {
      _snack('Please enter your name');
      return;
    }
    if (e.isEmpty) {
      _snack('Please enter your email');
      return;
    }
    if (p.length < 6) {
      _snack('Password must be at least 6 characters');
      return;
    }
    if (!agreeTerms) {
      _snack('Please agree to the Terms & Privacy Policy.');
      return;
    }

    setState(() => isLoading = true);
    try {
      await auth.signup(name: n, email: e, password: p);
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    } on FirebaseAuthException catch (err) {
      debugPrint('Signup error: code=${err.code} message=${err.message}');
      if (!mounted) return;
      _snack(_mapSignupError(err));
    } catch (err) {
      debugPrint('Signup unexpected error: $err');
      if (!mounted) return;
      _snack('Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  String _mapSignupError(FirebaseAuthException err) {
    switch (err.code) {
      case 'email-already-in-use':
        return 'An account already exists for that email. Try signing in.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'operation-not-allowed':
        return 'Email sign-up is not enabled. Contact support.';
      case 'network-request-failed':
        return 'Network error. Check your connection and try again.';
      default:
        return 'Sign-up failed (${err.code}). Please try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _SignupHero(
              onBack: () => Navigator.pop(context),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Create your account',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),

                  const SizedBox(height: 6),

                  const Text(
                    'Join CashBackMax and start finding the best rewards, cashback, and points for every purchase.',
                    style: TextStyle(
                      color: AppColors.text2,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 24),

                  CustomInput(
                    label: 'Full Name',
                    hint: 'Alex Johnson',
                    controller: name,
                  ),

                  CustomInput(
                    label: 'Email',
                    hint: 'you@email.com',
                    controller: email,
                    keyboardType: TextInputType.emailAddress,
                  ),

                  CustomInput(
                    label: 'Password',
                    hint: 'Create a strong password',
                    controller: password,
                    obscureText: true,
                  ),

                  const SizedBox(height: 8),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Checkbox(
                        value: agreeTerms,
                        activeColor: AppColors.accent,
                        onChanged: (value) {
                          setState(() => agreeTerms = value ?? false);
                        },
                      ),
                      const Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(top: 12),
                          child: Text(
                            'I agree to the Terms of Service and Privacy Policy.',
                            style: TextStyle(
                              color: AppColors.text2,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  CustomButton(
                    text: isLoading ? 'Creating account…' : 'Create Account',
                    loading: isLoading,
                    onPressed: _createAccount,
                  ),

                  const SizedBox(height: 22),

                  const Row(
                    children: [
                      Expanded(child: Divider(color: AppColors.bg3)),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'or sign up with',
                          style: TextStyle(color: AppColors.text3),
                        ),
                      ),
                      Expanded(child: Divider(color: AppColors.bg3)),
                    ],
                  ),

                  const SizedBox(height: 18),

                  Row(
  children: [
    Expanded(
      child: _SocialSignupButton(
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
            } else {
              _snack('Google sign-in failed or was cancelled');
            }
          } finally {
            if (mounted) setState(() => _googleLoading = false);
          }
        },
      ),
    ),
  ],
),

                  const SizedBox(height: 22),

                  Center(
                    child: TextButton(
                      onPressed: () {
                        Navigator.pushReplacementNamed(
                          context,
                          AppRoutes.login,
                        );
                      },
                      child: const Text(
                        'Already have an account? Sign in',
                        style: TextStyle(
                          color: AppColors.accent2,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SignupHero extends StatelessWidget {
  const _SignupHero({
    required this.onBack,
  });

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 300,
      child: Stack(
        children: [
          Container(
            height: 250,
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(34),
              ),
            ),
          ),

          Positioned.fill(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(34),
              ),
              child: Image.asset(
                'assets/images/signup_hero.png',
                fit: BoxFit.cover,
                opacity: const AlwaysStoppedAnimation(.20),
              ),
            ),
          ),

          Positioned(
            top: 14,
            left: 16,
            child: IconButton.filled(
              style: IconButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: .18),
              ),
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back, color: Colors.white),
            ),
          ),

          const Positioned(
            left: 24,
            right: 24,
            top: 86,
            child: Text(
              'Start saving smarter',
              style: TextStyle(
                color: Colors.white,
                fontSize: 34,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),

          const Positioned(
            left: 24,
            right: 80,
            top: 136,
            child: Text(
              'Create your rewards wallet and maximise every dollar you spend.',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 15,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          Positioned(
            left: 24,
            right: 24,
            bottom: 0,
            child: Container(
              height: 112,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.bg2,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: .15),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Image.asset(
                    'assets/images/app_logo.png',
                    width: 78,
                    height: 78,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Text(
                      'Manage cards, compare rewards, and track savings in one secure app.',
                      style: TextStyle(
                        color: AppColors.text2,
                        height: 1.4,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SocialSignupButton extends StatelessWidget {
  const _SocialSignupButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.loading = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.bg2,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: loading ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 54,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (loading)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Icon(icon, size: 26),
              const SizedBox(width: 8),
              Text(
                loading ? 'Connecting…' : label,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
