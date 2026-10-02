import 'package:flutter/material.dart';

class AppColors {
  // Primary Brand Colors (From Login Screen: Signature Rose Crimson & Warm Coral)
  static const Color primary = Color(0xFFE11D48); // Login Screen Signature Crimson / Rose
  static const Color primaryDark = Color(0xFF9F1239); // Deep Medical Crimson
  static const Color primaryLight = Color(0xFFFFF0F3); // Soft Rose Blush (from Login Lock badge)
  static const Color primaryAccent = Color(0xFFE84C3D); // Warm Coral (from Login top banner)

  // Secondary & Accents
  static const Color secondary = Color(0xFF0F172A); // Deep Slate from Login Screen Headings
  static const Color accent = Color(0xFFE84C3D); // Warm Coral Accent
  static const Color accentLight = Color(0xFFFFF0F3); // Soft Blush

  // Brand Gradient (From Login Screen Top Banner)
  // Rose-pink brand gradient (no orange) — header, banners and brand CTAs.
  static const Color brandCoral = Color(0xFFF43F5E);
  static const Color brandRed = Color(0xFFE11D48);
  static const Color brandCrimson = Color(0xFFBE123C);

  static const LinearGradient brandGradient = LinearGradient(
    colors: [
      Color(0xFFF43F5E),
      Color(0xFFE11D48),
      Color(0xFFBE123C),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Status Colors
  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFFD1FAE5);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color error = Color(0xFFE11D48);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color info = Color(0xFF3B82F6);
  static const Color infoLight = Color(0xFFDBEAFE);

  // Neutral Colors (Matching Login Screen Card, Surface & Typography)
  static const Color background = Color(0xFFFFF8F9); // Clean Premium Healthcare Blush White
  static const Color surface = Color(0xFFFFFFFF);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF0F172A); // Deep Slate Black (from Login Screen)
  static const Color textSecondary = Color(0xFF475569); // Slate 600 (from Login Screen)
  static const Color textMuted = Color(0xFF94A3B8); // Slate 400 (from Login Screen)
  static const Color border = Color(0xFFF1F5F9); // Crisp Subtle Border
  static const Color borderSubtle = Color(0xFFFECDD3); // Soft Rose Accent Border (from Login Screen)
  static const Color divider = Color(0xFFF1F5F9);
  static const Color lightPink = Color(0xFFFFF0F3);
  static const Color softBlush = Color(0xFFFFE4E8);

  // Diagnostic Category Badges
  static const Color bloodTestBadge = Color(0xFFE11D48);
  static const Color xrayBadge = Color(0xFF4F46E5);
  static const Color ecgBadge = Color(0xFF0284C7);
  static const Color physioBadge = Color(0xFF0D9488);
  static const Color pftBadge = Color(0xFF7C3AED);
  static const Color stressTestBadge = Color(0xFFEA580C);
}
