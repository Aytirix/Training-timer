import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/timer_state.dart';

/// Grand affichage central du timer.
class TimerDisplay extends StatelessWidget {
  final TimerState state;

  const TimerDisplay({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return switch (state.phase) {
      TimerPhase.preparing => _PreparingDisplay(state: state),
      TimerPhase.countdown => _CountdownDisplay(state: state),
      TimerPhase.activeSet => _ActiveSetDisplay(state: state),
      TimerPhase.resting => _RestingDisplay(state: state, isTransition: false),
      TimerPhase.transitionRest =>
        _RestingDisplay(state: state, isTransition: true),
      TimerPhase.paused => _PausedDisplay(state: state),
      TimerPhase.finished => _FinishedDisplay(state: state),
      TimerPhase.idle => const SizedBox.shrink(),
    };
  }
}

// ──────────────────────────────────────────
//  Préparation
// ──────────────────────────────────────────
class _PreparingDisplay extends StatelessWidget {
  final TimerState state;

  const _PreparingDisplay({required this.state});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Préparez-vous', style: AppTypography.headingLarge),
        const SizedBox(height: 16),
        Text(
          '${state.phaseRemainingSeconds}',
          style: AppTypography.displayLarge.copyWith(color: AppColors.accent),
        ),
        const SizedBox(height: 8),
        Text(
          'Première série : ${state.currentStep?.reps ?? 0} tractions',
          style: AppTypography.bodyLarge,
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────
//  Countdown
// ──────────────────────────────────────────
class _CountdownDisplay extends StatelessWidget {
  final TimerState state;

  const _CountdownDisplay({required this.state});

  @override
  Widget build(BuildContext context) {
    final reps = state.currentStep?.reps ?? 0;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Nombre de tractions annoncé
        Text(
          '$reps',
          style: AppTypography.displayHero.copyWith(color: AppColors.accent),
        ),
        Text(
          reps == 1 ? 'traction' : 'tractions',
          style: AppTypography.headingMedium.copyWith(
            color: AppColors.accent.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 40),
        // Countdown
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (child, anim) => ScaleTransition(
            scale: anim,
            child: FadeTransition(opacity: anim, child: child),
          ),
          child: Text(
            key: ValueKey(state.countdownValue),
            '${state.countdownValue}',
            style: AppTypography.displayMedium.copyWith(
              color: AppColors.countdown,
            ),
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────
//  Série active
// ──────────────────────────────────────────
class _ActiveSetDisplay extends StatelessWidget {
  final TimerState state;

  const _ActiveSetDisplay({required this.state});

  @override
  Widget build(BuildContext context) {
    final reps = state.currentStep?.reps ?? 0;
    final step = state.currentStep;
    final autoRemaining = state.phaseRemainingSeconds;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'GO !',
          style: AppTypography.headingLarge.copyWith(color: AppColors.active),
        ),
        const SizedBox(height: 16),
        Text(
          '$reps',
          style: AppTypography.displayHero.copyWith(color: AppColors.textPrimary),
        ),
        Text(
          reps == 1 ? 'traction' : 'tractions',
          style: AppTypography.headingMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 16),
        // Chrono auto-enchaînement
        if (autoRemaining > 0)
          Text(
            '${autoRemaining}s',
            style: AppTypography.timerSmall.copyWith(
              color: autoRemaining <= 3 ? AppColors.danger : AppColors.textMuted,
            ),
          ),
        if (step != null) ...[
          const SizedBox(height: 8),
          Text(
            'Série ${step.index + 1} / ${state.totalSteps}',
            style: AppTypography.bodyMedium,
          ),
          if (state.nextStep != null)
            Text(
              'Prochaine : ${state.nextStep!.reps} reps',
              style: AppTypography.bodySmall,
            ),
        ],
      ],
    );
  }
}

// ──────────────────────────────────────────
//  Repos
// ──────────────────────────────────────────
class _RestingDisplay extends StatelessWidget {
  final TimerState state;
  final bool isTransition;

  const _RestingDisplay({required this.state, required this.isTransition});

  @override
  Widget build(BuildContext context) {
    final remaining = state.phaseRemainingSeconds;
    final nextReps = state.nextStep?.reps;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          isTransition ? 'Transition' : 'Repos',
          style: AppTypography.headingLarge.copyWith(color: AppColors.resting),
        ),
        const SizedBox(height: 16),
        // Grand timer de repos
        Text(
          state.phaseRemainingLabel,
          style: AppTypography.timerDisplay.copyWith(color: AppColors.resting),
        ),
        const SizedBox(height: 24),
        if (nextReps != null)
          Column(
            children: [
              Text('Prochaine série', style: AppTypography.bodyMedium),
              const SizedBox(height: 4),
              Text(
                '$nextReps',
                style: AppTypography.displayMedium.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                nextReps == 1 ? 'traction' : 'tractions',
                style: AppTypography.bodyMedium,
              ),
            ],
          ),
        const SizedBox(height: 8),
        // Barre de progression du repos
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 48),
          child: _RestProgressBar(
            remaining: remaining,
            total: state.currentStep?.restAfterSeconds ?? 1,
          ),
        ),
      ],
    );
  }
}

class _RestProgressBar extends StatelessWidget {
  final int remaining;
  final int total;

  const _RestProgressBar({required this.remaining, required this.total});

  @override
  Widget build(BuildContext context) {
    final progress = total == 0 ? 0.0 : 1.0 - (remaining / total);

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            minHeight: 6,
            backgroundColor: AppColors.surfaceElevated,
            valueColor:
                const AlwaysStoppedAnimation<Color>(AppColors.resting),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${(progress * 100).round()}%',
          style: AppTypography.caption,
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────
//  Pause
// ──────────────────────────────────────────
class _PausedDisplay extends StatelessWidget {
  final TimerState state;

  const _PausedDisplay({required this.state});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.pause_circle_outline,
          size: 80,
          color: AppColors.paused,
        ),
        const SizedBox(height: 16),
        Text(
          'Pause',
          style: AppTypography.headingLarge.copyWith(color: AppColors.paused),
        ),
        const SizedBox(height: 8),
        Text(
          'Série ${(state.currentStepIndex + 1)} / ${state.totalSteps}',
          style: AppTypography.bodyMedium,
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────
//  Terminé
// ──────────────────────────────────────────
class _FinishedDisplay extends StatelessWidget {
  final TimerState state;

  const _FinishedDisplay({required this.state});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('🎉', style: TextStyle(fontSize: 72)),
        const SizedBox(height: 16),
        Text(
          'Bravo !',
          style: AppTypography.displayMedium.copyWith(color: AppColors.accent),
        ),
        const SizedBox(height: 8),
        Text(
          'Séance terminée',
          style: AppTypography.headingMedium,
        ),
        const SizedBox(height: 24),
        Text(
          '${state.session.totalReps} tractions',
          style: AppTypography.headingLarge.copyWith(color: AppColors.accent),
        ),
        Text(
          'en ${state.elapsedLabel}',
          style: AppTypography.bodyLarge,
        ),
      ],
    );
  }
}
