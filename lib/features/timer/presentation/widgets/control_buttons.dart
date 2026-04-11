import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/timer_state.dart';

/// Boutons de contrôle du timer (pause, reprise, skip, précédent, stop).
class ControlButtons extends StatelessWidget {
  final TimerState state;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onSkip;
  final VoidCallback onPrevious;
  final VoidCallback onStop;
  final VoidCallback? onDoneSet; // bouton "Done" pendant activeSet

  const ControlButtons({
    super.key,
    required this.state,
    required this.onPause,
    required this.onResume,
    required this.onSkip,
    required this.onPrevious,
    required this.onStop,
    this.onDoneSet,
  });

  @override
  Widget build(BuildContext context) {
    final phase = state.phase;

    if (phase == TimerPhase.finished) {
      return _FinishedButtons(onStop: onStop);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Bouton principal (Done pendant activeSet) ──
        if (phase == TimerPhase.activeSet && onDoneSet != null) ...[
          _DoneButton(onPressed: onDoneSet!),
          const SizedBox(height: 16),
        ],

        // ── Contrôles secondaires ──
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Précédent
            _CircleButton(
              icon: Icons.skip_previous_rounded,
              onPressed: phase != TimerPhase.paused &&
                      phase != TimerPhase.finished &&
                      state.currentStepIndex > 0
                  ? onPrevious
                  : null,
              size: 52,
              tooltip: 'Série précédente',
            ),

            const SizedBox(width: 20),

            // Pause / Reprise (bouton central grand)
            _PauseResumeButton(
              phase: phase,
              onPause: onPause,
              onResume: onResume,
            ),

            const SizedBox(width: 20),

            // Passer
            _CircleButton(
              icon: Icons.skip_next_rounded,
              onPressed:
                  phase != TimerPhase.finished ? onSkip : null,
              size: 52,
              tooltip: 'Passer',
            ),
          ],
        ),

        const SizedBox(height: 20),

        // ── Stop ──
        TextButton.icon(
          onPressed: onStop,
          icon: const Icon(Icons.stop_circle_outlined,
              color: AppColors.danger, size: 18),
          label: const Text(
            'Arrêter la séance',
            style: TextStyle(color: AppColors.danger),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────

class _DoneButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _DoneButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.active,
          foregroundColor: Colors.black,
          minimumSize: const Size.fromHeight(60),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_rounded, size: 24),
            SizedBox(width: 8),
            Text(
              'Série terminée',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _PauseResumeButton extends StatelessWidget {
  final TimerPhase phase;
  final VoidCallback onPause;
  final VoidCallback onResume;

  const _PauseResumeButton({
    required this.phase,
    required this.onPause,
    required this.onResume,
  });

  @override
  Widget build(BuildContext context) {
    final isPaused = phase == TimerPhase.paused;

    return GestureDetector(
      onTap: isPaused ? onResume : onPause,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: isPaused ? AppColors.active : AppColors.surfaceVariant,
          shape: BoxShape.circle,
          border: Border.all(
            color: isPaused ? AppColors.active : AppColors.border,
            width: 2,
          ),
        ),
        child: Icon(
          isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
          color: isPaused ? Colors.black : AppColors.textPrimary,
          size: 36,
        ),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final double size;
  final String tooltip;

  const _CircleButton({
    required this.icon,
    required this.onPressed,
    required this.size,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: onPressed != null
                ? AppColors.surfaceVariant
                : AppColors.surface,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.border),
          ),
          child: Icon(
            icon,
            color: onPressed != null
                ? AppColors.textPrimary
                : AppColors.textMuted,
            size: size * 0.5,
          ),
        ),
      ),
    );
  }
}

class _FinishedButtons extends StatelessWidget {
  final VoidCallback onStop;

  const _FinishedButtons({required this.onStop});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton.icon(
          onPressed: onStop,
          icon: const Icon(Icons.home_rounded),
          label: const Text('Retour à l\'accueil'),
        ),
      ],
    );
  }
}
