import 'package:flutter/material.dart';

class AppColors {
  static const bg = Color(0xFF0A0A0F);
  static const bg2 = Color(0xFF13131A);
  static const bg3 = Color(0xFF1C1C27);
  static const bg4 = Color(0xFF252535);
  static const accent = Color(0xFF6C63FF);
  static const accent2 = Color(0xFFA78BFA);
  static const green = Color(0xFF22C55E);
  static const amber = Color(0xFFF59E0B);
  static const red = Color(0xFFEF4444);
  static const text = Color(0xFFF0F0FF);
  static const text2 = Color(0xFF9090B0);
  static const text3 = Color(0xFF5A5A7A);

  static const primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accent, accent2],
  );

  static const cardGreen = LinearGradient(colors: [Color(0xFF1A7A4A), green]);
  static const cardPurple = LinearGradient(colors: [Color(0xFF7C3AED), accent2]);
  static const cardAmber = LinearGradient(colors: [Color(0xFFB45309), amber]);
  static const cardBlue = LinearGradient(colors: [Color(0xFF1D4ED8), Color(0xFF60A5FA)]);
}

