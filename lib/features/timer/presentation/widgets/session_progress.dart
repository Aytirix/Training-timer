import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/timer_state.dart';

/// Barre de progression de la séance et informations contextuelles.
class SessionProgress extends StatelessWidget {
  final TimerState state;

  const SessionProgress({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Infos contextuelles ──
        Row(
          children: [
            // Bloc actuel
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Bloc', style: AppTypography.labelSmall),
                  Text(
                    state.currentStep?.blockName ?? '—',
                    style: AppTypography.labelLarge,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Série actuelle
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text('Série', style: AppTypography.labelSmall),
                Text(
                  '${state.currentStepIndex + 1} / ${state.totalSteps}',
                  style: AppTypography.labelLarge,
                ),
              ],
            ),

            // Temps global
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Écoulé', style: AppTypography.labelSmall),
                  Text(
                    state.elapsedLabel,
                    style: AppTypography.timerSmall.copyWith(fontSize: 18),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // ── Barre de progression globale ──
        _GlobalProgressBar(state: state),

        const SizedBox(height: 8),

        // ── Minimap des séries ──
        _StepsMinimap(state: state),
      ],
    );
  }
}

// ─────────────────────────────────────────────

class _GlobalProgressBar extends StatelessWidget {
  final TimerState state;

  const _GlobalProgressBar({required this.state});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: state.globalProgress.clamp(0.0, 1.0),
            minHeight: 8,
            backgroundColor: AppColors.surfaceElevated,
            valueColor:
                const AlwaysStoppedAnimation<Color>(AppColors.accent),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${(state.globalProgress * 100).round()}%',
          style: AppTypography.caption,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  Minimap : visualise toutes les séries
// ─────────────────────────────────────────────

class _StepsMinimap extends StatelessWidget {
  final TimerState state;

  const _StepsMinimap({required this.state});

  @override
  Widget build(BuildContext context) {
    final steps = state.steps;
    if (steps.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 28,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: steps.length,
        separatorBuilder: (_, __) => const SizedBox(width: 3),
        itemBuilder: (context, index) {
          final step = steps[index];
          final isDone = index < state.currentStepIndex;
          final isCurrent = index == state.currentStepIndex;

          Color color;
          if (isDone) {
            color = AppColors.active.withValues(alpha: 0.6);
          } else if (isCurrent) {
            color = AppColors.accent;
          } else {
            color = AppColors.surfaceElevated;
          }

          return Tooltip(
            message: '${step.reps} reps',
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: isCurrent ? 32 : 20,
              height: 28,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Center(
                child: Text(
                  '${step.reps}',
                  style: AppTypography.labelSmall.copyWith(
                    color: isCurrent
                        ? AppColors.textOnAccent
                        : isDone
                            ? AppColors.textPrimary.withValues(alpha: 0.7)
                            : AppColors.textMuted,
                    fontSize: 9,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
