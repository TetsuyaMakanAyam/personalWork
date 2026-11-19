import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Dark Futuristic Palette (Primary Identity)
  static const Color darkBackground = Color(0xFF080D18);
  static const Color darkSecondarySurface = Color(0xFF121B2B);
  static const Color darkElevatedCard = Color(0xFF192538);
  static const Color darkGlassBorder = Color(0x289AAABD);
  static const Color darkHighlightBorder = Color(0x455CE1E6);

  // Light Technical Palette (Optional High-Contrast Lab View)
  static const Color lightBackground = Color(0xFFF3F6FA);
  static const Color lightSecondarySurface = Color(0xFFFFFFFF);
  static const Color lightElevatedCard = Color(0xFFE8EEF6);
  static const Color lightGlassBorder = Color(0x1F121B2B);

  // Core Brand Accents
  static const Color primaryAccent = Color(0xFF5CE1E6);
  static const Color secondaryAccent = Color(0xFF8B7CF6);
  static const Color cyanGlow = Color(0xFF38BDF8);

  // Semantic Telemetry Status Colors
  static const Color success = Color(0xFF34D399);
  static const Color warning = Color(0xFFFBBF24);
  static const Color criticalDanger = Color(0xFFFF647C);
  static const Color offlineNeutral = Color(0xFF64748B);

  // Typography Colors
  static const Color darkMainText = Color(0xFFF7FAFC);
  static const Color darkSecondaryText = Color(0xFF9AAABD);
  static const Color darkMutedText = Color(0xFF64748B);

  static const Color lightMainText = Color(0xFF0F172A);
  static const Color lightSecondaryText = Color(0xFF475569);

  // Curated Gradients
  static const LinearGradient heroSecureGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF132A3A),
      Color(0xFF121B2B),
      Color(0xFF0E1726),
    ],
  );

  static const LinearGradient heroWarningGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF382814),
      Color(0xFF1F1924),
      Color(0xFF121B2B),
    ],
  );

  static const LinearGradient heroCriticalGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF3B1525),
      Color(0xFF221528),
      Color(0xFF121B2B),
    ],
  );

  static const LinearGradient heroOfflineGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF1C2536),
      Color(0xFF121B2B),
      Color(0xFF0B111E),
    ],
  );
}
