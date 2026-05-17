import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/home_screen.dart';
import 'utils/app_colors.dart';
import 'utils/app_routes.dart';

class CashBackRewardsApp extends StatelessWidget {
  const CashBackRewardsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CashBack Rewards Maximiser',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.bg,
        fontFamily: 'Arial',
        colorScheme: const ColorScheme.dark(primary: AppColors.accent, secondary: AppColors.accent2),
      ),
      routes: {
        AppRoutes.splash: (_) => const SplashScreen(),
        AppRoutes.login: (_) => const LoginScreen(),
        AppRoutes.signup: (_) => const SignupScreen(),
        AppRoutes.home: (_) => const HomeScreen(),
      },
    );
  }
}


