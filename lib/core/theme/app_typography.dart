import 'package:flutter/material.dart';
import 'app_colors.dart';

abstract class AppTypography {
  // ── Display : très grandes valeurs (reps, timer) ──
  static const TextStyle displayHero = TextStyle(
    fontSize: 96,
    fontWeight: FontWeight.w900,
    color: AppColors.textPrimary,
    letterSpacing: -4,
    height: 1.0,
  );

  static const TextStyle displayLarge = TextStyle(
    fontSize: 64,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
    letterSpacing: -2,
    height: 1.0,
  );

  static const TextStyle displayMedium = TextStyle(
    fontSize: 48,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -1,
    height: 1.1,
  );

  // ── Timer (police mono pour alignement) ──
  static const TextStyle timerDisplay = TextStyle(
    fontSize: 72,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    fontFeatures: [FontFeature.tabularFigures()],
    letterSpacing: -2,
    height: 1.0,
  );

  static const TextStyle timerSmall = TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
    fontFeatures: [FontFeature.tabularFigures()],
    letterSpacing: -1,
    height: 1.0,
  );

  // ── Headings ──
  static const TextStyle headingLarge = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
  );

  static const TextStyle headingMedium = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle headingSmall = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  // ── Body ──
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.5,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textMuted,
    height: 1.4,
  );

  // ── Labels ──
  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: 0.5,
  );

  static const TextStyle labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
    letterSpacing: 0.8,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: AppColors.textMuted,
    letterSpacing: 1.0,
  );

  // ── Caption / badge ──
  static const TextStyle caption = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: AppColors.textMuted,
    letterSpacing: 0.5,
  );
}
