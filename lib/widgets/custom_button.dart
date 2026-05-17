import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class CustomButton extends StatelessWidget {
  const CustomButton({super.key, required this.text, required this.onPressed, this.ghost = false, this.danger = false});
  final String text;
  final VoidCallback onPressed;
  final bool ghost;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: ghost || danger ? null : AppColors.primaryGradient,
          color: danger ? AppColors.red.withValues(alpha: .10) : ghost ? Colors.transparent : null,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: danger ? AppColors.red.withValues(alpha: .25) : Colors.white.withValues(alpha: .10)),
        ),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: Text(text, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: danger ? AppColors.red : Colors.white)),
        ),
      ),
    );
  }
}

