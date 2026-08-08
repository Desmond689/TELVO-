import 'package:flutter/material.dart';

/// TELVO modern design system colors.
///
/// The palette moves away from the dated Material Green to a modern
/// emerald-teal brand with sophisticated neutrals and a proper dark theme.
class AppColors {
  // ─── Brand Primary ────────────────────────────────────────────────
  static const Color primary = Color(0xFF00B884);
  static const Color primaryDark = Color(0xFF008F66);
  static const Color primaryLight = Color(0xFF5EE6BE);
  static const Color primaryBackground = Color(0xFFE6FBF4);

  // ─── Brand Accent ─────────────────────────────────────────────────
  static const Color secondary = Color(0xFF00C2C7);
  static const Color secondaryDark = Color(0xFF009A9E);
  static const Color secondaryLight = Color(0xFF6DE8EB);

  // ─── Neutrals (light theme) ───────────────────────────────────────
  static const Color background = Color(0xFFF7F8FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF1F3F5);

  // ─── Text ─────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textHint = Color(0xFF94A3B8);
  static const Color textWhite = Color(0xFFFFFFFF);

  // ─── Borders ──────────────────────────────────────────────────────
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderLight = Color(0xFFF1F5F9);

  // ─── Semantic ─────────────────────────────────────────────────────
  static const Color error = Color(0xFFEF4444);
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);

  // ─── Status ───────────────────────────────────────────────────────
  static const Color online = Color(0xFF22C55E);
  static const Color offline = Color(0xFF94A3B8);
  static const Color busy = Color(0xFFF97316);
  static const Color away = Color(0xFF3B82F6);

  // ─── Gradients ────────────────────────────────────────────────────
  static const List<Color> primaryGradient = [
    Color(0xFF00B884),
    Color(0xFF00C2C7),
  ];

  static const List<Color> primaryGradientDeep = [
    Color(0xFF008F66),
    Color(0xFF00B884),
  ];

  static const List<Color> accentGradient = [
    Color(0xFF6EE7B7),
    Color(0xFF38BDF8),
  ];

  static const List<Color> dangerGradient = [
    Color(0xFFF87171),
    Color(0xFFEF4444),
  ];

  static const List<Color> successGradient = [
    Color(0xFF34D399),
    Color(0xFF10B981),
  ];

  static const List<Color> darkGradient = [
    Color(0xFF0F172A),
    Color(0xFF1E293B),
  ];

  // ─── Social ───────────────────────────────────────────────────────
  static const Color google = Color(0xFFDB4437);
  static const Color apple = Color(0xFF000000);
  static const Color facebook = Color(0xFF1877F2);

  // ─── Category Colors (modern soft palette) ────────────────────────
  static const Color plumbing = Color(0xFF3B82F6);
  static const Color electrical = Color(0xFFF59E0B);
  static const Color cleaning = Color(0xFF10B981);
  static const Color painting = Color(0xFF8B5CF6);
  static const Color carpentry = Color(0xFFB45309);
  static const Color mechanic = Color(0xFF64748B);
  static const Color gardening = Color(0xFF84CC16);
  static const Color tutoring = Color(0xFFEC4899);
  static const Color photography = Color(0xFF06B6D4);
  static const Color chef = Color(0xFFF97316);
  static const Color babysitter = Color(0xFFF43F5E);
}