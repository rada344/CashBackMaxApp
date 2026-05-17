import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class CustomButton extends StatelessWidget {
  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.ghost = false,
    this.danger = false,
    this.loading = false,
  });
  final String text;
  final VoidCallback onPressed;
  final bool ghost;
  final bool danger;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final Color foreground = danger ? AppColors.red : Colors.white;
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: ghost || danger || loading ? null : AppColors.primaryGradient,
          color: danger
              ? AppColors.red.withValues(alpha: .10)
              : ghost
                  ? Colors.transparent
                  : loading
                      ? AppColors.bg3
                      : null,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: danger ? AppColors.red.withValues(alpha: .25) : Colors.white.withValues(alpha: .10)),
        ),
        child: ElevatedButton(
          onPressed: loading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (loading) ...[
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    valueColor: AlwaysStoppedAnimation<Color>(foreground),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Text(
                text,
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: foreground),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
