import 'package:flutter/material.dart';

/// Palette de couleurs de l'application.
/// Design sombre, contraste élevé, lisible pendant l'effort.
abstract class AppColors {
  // ── Background ──
  static const Color background = Color(0xFF0D0D0F);
  static const Color surface = Color(0xFF1A1A1E);
  static const Color surfaceVariant = Color(0xFF242428);
  static const Color surfaceElevated = Color(0xFF2C2C32);

  // ── Brand / Accent ──
  static const Color accent = Color(0xFFE8FF47); // Vert-jaune néon
  static const Color accentDim = Color(0xFFB8CC39);
  static const Color accentMuted = Color(0xFF3A3F10);

  // ── Status ──
  static const Color active = Color(0xFF4ADE80); // Vert succès
  static const Color resting = Color(0xFF60A5FA); // Bleu repos
  static const Color countdown = Color(0xFFFBBF24); // Jaune countdown
  static const Color paused = Color(0xFF94A3B8); // Gris pause
  static const Color danger = Color(0xFFF87171); // Rouge stop

  // ── Text ──
  static const Color textPrimary = Color(0xFFF5F5F5);
  static const Color textSecondary = Color(0xFF9CA3AF);
  static const Color textMuted = Color(0xFF4B5563);
  static const Color textOnAccent = Color(0xFF0D0D0F);

  // ── Border ──
  static const Color border = Color(0xFF2D2D33);
  static const Color borderActive = Color(0xFF4A4A54);

  // ── Gradients ──
  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFFE8FF47), Color(0xFF9FE240)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient surfaceGradient = LinearGradient(
    colors: [Color(0xFF1A1A1E), Color(0xFF0D0D0F)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // ── Phase colors ──
  static Color forPhase(String phase) {
    switch (phase) {
      case 'activeSet':
        return active;
      case 'resting':
        return resting;
      case 'countdown':
        return countdown;
      case 'paused':
        return paused;
      case 'preparing':
        return accent;
      default:
        return textSecondary;
    }
  }
}
