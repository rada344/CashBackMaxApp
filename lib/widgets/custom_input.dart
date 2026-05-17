import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class CustomInput extends StatelessWidget {
  const CustomInput({super.key, required this.label, required this.hint, required this.controller, this.obscureText = false, this.keyboardType});
  final String label;
  final String hint;
  final TextEditingController controller;
  final bool obscureText;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label.toUpperCase(), style: const TextStyle(color: AppColors.text2, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: .8)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          style: const TextStyle(color: AppColors.text),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.text3),
            filled: true,
            fillColor: AppColors.bg3,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.white.withValues(alpha: .08))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.white.withValues(alpha: .08))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.accent)),
          ),
        ),
      ]),
    );
  }
}

