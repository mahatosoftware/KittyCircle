import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary palette (Rich Purple & Deep Pink)
  static const Color primary = Color(0xFF673AB7); // Deep Purple
  static const Color primaryLight = Color(0xFF9575CD);
  static const Color primaryDark = Color(0xFF512DA8);
  static const Color secondary = Color(0xFFE91E63); // Festive Pink
  static const Color secondaryLight = Color(0xFFF48FB1);

  // Accent & Gold (Celebration Theme)
  static const Color gold = Color(0xFFFFD700);
  static const Color goldDark = Color(0xFFFFB300);
  static const Color amber = Color(0xFFFFC107);

  // Backgrounds & Neutrals
  static const Color background = Color(0xFFF8F5FB); // Soft warm neutral
  static const Color surface = Colors.white;
  static const Color cardBackground = Colors.white;
  
  // Dark mode surfaces
  static const Color darkBackground = Color(0xFF120E16);
  static const Color darkSurface = Color(0xFF1E1926);
  static const Color darkCard = Color(0xFF262030);

  // Text colors
  static const Color textPrimary = Color(0xFF21153B);
  static const Color textSecondary = Color(0xFF6C657B);
  static const Color textMuted = Color(0xFF9E98AB);

  // Status colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF673AB7), Color(0xFF9C27B0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFFFD700), Color(0xFFFF9100)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient partyCardGradient = LinearGradient(
    colors: [Color(0xFF7B1FA2), Color(0xFFE91E63)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
