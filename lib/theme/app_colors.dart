import 'package:flutter/material.dart';

class AppColors {
  // Warna dari Figma
  static const Color primaryGreen = Color(0xFF1B5E37); // 1B5E37
  static const Color accentGold = Color(0xFFC1A248);  // C1A248
  static const Color backgroundLight = Color(0xFFFAFCF8); // FAFCF8

  // Gradasi Linear diagonal persis seperti di Figma
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF1B5E37), // 0%
      Color(0xFFC1A248), // 100%
    ],
  );
}