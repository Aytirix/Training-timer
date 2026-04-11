import 'package:flutter/material.dart';
import '../../../../core/audio/tts_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

class VoiceListTile extends StatelessWidget {
  final VoiceInfo voice;
  final bool isSelected;
  final bool isTesting;
  final VoidCallback onSelect;
  final VoidCallback onTest;

  const VoiceListTile({
    super.key,
    required this.voice,
    required this.isSelected,
    required this.isTesting,
    required this.onSelect,
    required this.onTest,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.accentMuted : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected ? AppColors.accent : AppColors.border,
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        onTap: onSelect,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // ── Sélection indicator ──
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? AppColors.accent : Colors.transparent,
                  border: Border.all(
                    color: isSelected ? AppColors.accent : AppColors.border,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? const Icon(
                        Icons.check,
                        size: 14,
                        color: AppColors.textOnAccent,
                      )
                    : null,
              ),

              const SizedBox(width: 12),

              // ── Infos voix ──
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      voice.name,
                      style: AppTypography.bodyLarge.copyWith(
                        fontWeight: isSelected ? FontWeight.w600 : null,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        _LocaleBadge(locale: voice.locale),
                        if (voice.identifier != null) ...[
                          const SizedBox(width: 6),
                          Text(
                            voice.identifier!.length > 20
                                ? '${voice.identifier!.substring(0, 20)}…'
                                : voice.identifier!,
                            style: AppTypography.caption,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // ── Bouton test ──
              IconButton(
                onPressed: isTesting ? null : onTest,
                icon: isTesting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.volume_up_rounded, size: 20),
                tooltip: 'Tester la voix',
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LocaleBadge extends StatelessWidget {
  final String locale;

  const _LocaleBadge({required this.locale});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        locale,
        style: AppTypography.labelSmall.copyWith(
          color: AppColors.textSecondary,
          fontSize: 10,
        ),
      ),
    );
  }
}
