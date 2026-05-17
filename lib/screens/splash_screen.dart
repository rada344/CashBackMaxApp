import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../utils/app_routes.dart';
import '../widgets/custom_button.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(children: [
            Expanded(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Container(
                  width: 132,
                  height: 132,
                  decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(34), boxShadow: [BoxShadow(color: AppColors.accent.withValues(alpha: .38), blurRadius: 42, offset: const Offset(0, 14))]),
                  child: const Icon(Icons.credit_card_rounded, size: 68, color: Colors.white),
                ),
                const SizedBox(height: 30),
                const Text('CashBackMax', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -.5)),
                const SizedBox(height: 10),
                const Text('Maximise cashback, points, and discounts with the smartest reward card recommendation.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.text2, height: 1.6, fontSize: 15)),
              ]),
            ),
            CustomButton(text: 'Sign In', onPressed: () => Navigator.pushNamed(context, AppRoutes.login)),
            const SizedBox(height: 12),
            CustomButton(text: 'Create Account', ghost: true, onPressed: () => Navigator.pushNamed(context, AppRoutes.signup)),
            const SizedBox(height: 40),
          ]),
        ),
      ),
    );
  }
}

