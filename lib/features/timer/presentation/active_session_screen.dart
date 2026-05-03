import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../application/timer_provider.dart';
import '../domain/timer_state.dart';
import 'widgets/timer_display.dart';
import 'widgets/control_buttons.dart';
import 'widgets/session_progress.dart';

class ActiveSessionScreen extends ConsumerWidget {
  const ActiveSessionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timerState = ref.watch(timerProvider);

    if (timerState == null) {
      return _NoSession(onBack: () => context.go('/'));
    }

    return _SessionView(state: timerState, ref: ref);
  }
}

// ──────────────────────────────────────────────────────
//  Vue principale de la séance
// ──────────────────────────────────────────────────────

class _SessionView extends StatelessWidget {
  final TimerState state;
  final WidgetRef ref;

  const _SessionView({required this.state, required this.ref});

  void _stop(BuildContext context) async {
    final ok = await _confirmStop(context);
    if (ok) {
      ref.read(timerProvider.notifier).stop();
      if (context.mounted) context.go('/');
    }
  }

  Future<bool> _confirmStop(BuildContext context) async {
    if (state.phase == TimerPhase.finished) return true;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        title: const Text('Arrêter la séance ?'),
        content: const Text(
            'La progression de cette séance sera perdue.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Continuer'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Arrêter',
              style: TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _doneSet() async {
    await ref.read(timerProvider.notifier).skip();
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(timerProvider.notifier);
    final phase = state.phase;
    final phaseColor = _phaseColor(phase);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (phase == TimerPhase.finished) {
          ref.read(timerProvider.notifier).stop();
          if (context.mounted) context.go('/');
          return;
        }
        final ok = await _confirmStop(context);
        if (ok && context.mounted) context.go('/');
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle.light,
          child: SafeArea(
            child: Column(
              children: [
                // ── Header ──
                _SessionHeader(state: state, phaseColor: phaseColor),

                // ── Display central ──
                Expanded(
                  flex: 3,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        transitionBuilder: (child, anim) =>
                            FadeTransition(
                          opacity: anim,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.08),
                              end: Offset.zero,
                            ).animate(anim),
                            child: child,
                          ),
                        ),
                        child: KeyedSubtree(
                          key: ValueKey(phase),
                          child: TimerDisplay(state: state),
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Progression ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: SessionProgress(state: state),
                ),

                const SizedBox(height: 24),

                // ── Contrôles ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: ControlButtons(
                    state: state,
                    onPause: notifier.pause,
                    onResume: notifier.resume,
                    onSkip: () => notifier.skip(),
                    onPrevious: () => notifier.previous(),
                    onStop: () => _stop(context),
                    onDoneSet:
                        phase == TimerPhase.activeSet ? _doneSet : null,
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _phaseColor(TimerPhase phase) {
    switch (phase) {
      case TimerPhase.activeSet:
        return AppColors.active;
      case TimerPhase.resting:
      case TimerPhase.transitionRest:
        return AppColors.resting;
      case TimerPhase.countdown:
      case TimerPhase.preparing:
        return AppColors.countdown;
      case TimerPhase.paused:
        return AppColors.paused;
      case TimerPhase.finished:
        return AppColors.accent;
      case TimerPhase.idle:
        return AppColors.textMuted;
    }
  }
}

// ──────────────────────────────────────────────────────
//  Header de la séance active
// ──────────────────────────────────────────────────────

class _SessionHeader extends StatelessWidget {
  final TimerState state;
  final Color phaseColor;

  const _SessionHeader({required this.state, required this.phaseColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Row(
        children: [
          // Nom de la séance
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  state.session.name,
                  style: AppTypography.headingSmall,
                  overflow: TextOverflow.ellipsis,
                ),
                Row(
                  children: [
                    // Indicateur de phase
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: phaseColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      state.phase.label,
                      style: AppTypography.labelSmall.copyWith(
                        color: phaseColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Temps restant estimé
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('Reste', style: AppTypography.labelSmall),
              Text(
                state.estimatedRemainingLabel,
                style: AppTypography.timerSmall.copyWith(
                  fontSize: 20,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────
//  Écran si pas de session active
// ──────────────────────────────────────────────────────

class _NoSession extends StatelessWidget {
  final VoidCallback onBack;

  const _NoSession({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.timer_off_outlined, size: 64, color: AppColors.textMuted),
            const SizedBox(height: 16),
            const Text('Aucune séance active', style: AppTypography.headingMedium),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onBack,
              child: const Text('Retour'),
            ),
          ],
        ),
      ),
    );
  }
}
