import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/gym/gym_exercise.dart';
import '../../../core/models/gym/gym_session.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../gym/domain/gym_provider.dart';
import '../../gym/presentation/gym_video_player_screen.dart';
import '../application/gym_execution_provider.dart';
import '../domain/gym_execution_sequence.dart';
import '../domain/gym_execution_state.dart';

class ActiveGymSessionScreen extends ConsumerStatefulWidget {
  final String sessionId;
  const ActiveGymSessionScreen({super.key, required this.sessionId});

  @override
  ConsumerState<ActiveGymSessionScreen> createState() =>
      _ActiveGymSessionScreenState();
}

class _ActiveGymSessionScreenState
    extends ConsumerState<ActiveGymSessionScreen> {
  GymSession? _session;
  List<GymSessionValidationError>? _errors;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _validateAndStart());
  }

  void _validateAndStart() {
    final session =
        ref.read(gymSessionsProvider.notifier).findById(widget.sessionId);
    if (session == null) {
      setState(() {
        _errors = [
          const GymSessionValidationError('session', 'Séance introuvable'),
        ];
      });
      return;
    }
    final exerciseNotifier = ref.read(gymExercisesProvider.notifier);
    final errors = session.validate(
      (id) => exerciseNotifier.findById(id)?.type,
    );
    if (errors.isNotEmpty) {
      setState(() {
        _session = session;
        _errors = errors;
      });
      return;
    }
    setState(() {
      _session = session;
      _errors = [];
    });
    ref.read(gymExecutionProvider.notifier).start(session);
  }

  @override
  void dispose() {
    Future.microtask(() => ref.read(gymExecutionProvider.notifier).stop());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final errors = _errors;
    if (errors == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (errors.isNotEmpty) {
      return _ValidationBlocker(
        sessionName: _session?.name ?? 'Séance',
        errors: errors,
        onClose: () => Navigator.of(context).maybePop(),
      );
    }
    return _RunningScreen(sessionId: widget.sessionId);
  }
}

class _ValidationBlocker extends StatelessWidget {
  final String sessionName;
  final List<GymSessionValidationError> errors;
  final VoidCallback onClose;

  const _ValidationBlocker({
    required this.sessionName,
    required this.errors,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Séance non lançable'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(sessionName, style: AppTypography.headingMedium),
          const SizedBox(height: 8),
          const Text(
            'Cette séance contient des erreurs bloquantes. Corrige-les avant de la lancer.',
            style: AppTypography.bodyMedium,
          ),
          const SizedBox(height: 16),
          for (final e in errors)
            ListTile(
              leading: const Icon(Icons.error_outline, color: AppColors.danger),
              title: Text(e.message),
              subtitle: Text(e.code, style: AppTypography.bodySmall),
            ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: onClose,
            child: const Text('Retour'),
          ),
        ],
      ),
    );
  }
}

class _RunningScreen extends ConsumerWidget {
  final String sessionId;
  const _RunningScreen({required this.sessionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gymExecutionProvider);
    final ctrl = ref.read(gymExecutionProvider.notifier);

    if (state == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (state.isFinished) {
      return _FinishedView(
        sessionName: state.session.name,
        onClose: () => Navigator.of(context).pop(),
      );
    }
    final step = state.currentStep!;
    final exercise =
        step.exerciseId != null ? ctrl.exerciseFor(step.exerciseId) : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text(state.session.name),
        actions: [
          IconButton(
            tooltip: 'Arrêter',
            icon: const Icon(Icons.stop),
            onPressed: () {
              ctrl.stop();
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _ProgressIndicator(
              current: state.currentIndex,
              total: state.steps.length,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _StepView(
                step: step,
                exercise: exercise,
                state: state,
              ),
            ),
            _Controls(state: state, ctrl: ctrl),
          ],
        ),
      ),
    );
  }
}

class _ProgressIndicator extends StatelessWidget {
  final int current;
  final int total;
  const _ProgressIndicator({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    final value = total == 0 ? 0.0 : (current + 1) / total;
    return Column(
      children: [
        Text('Étape ${current + 1} / $total', style: AppTypography.labelMedium),
        const SizedBox(height: 6),
        LinearProgressIndicator(value: value.clamp(0, 1)),
      ],
    );
  }
}

class _StepView extends StatelessWidget {
  final GymExecutionStep step;
  final GymExercise? exercise;
  final GymExecutionState state;

  const _StepView({
    required this.step,
    required this.exercise,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    if (step.kind == GymStepKind.restAfterSet ||
        step.kind == GymStepKind.restBetweenExercises) {
      final label = step.kind == GymStepKind.restBetweenExercises
          ? 'Repos entre exercices'
          : 'Repos entre séries';
      return _RestView(
        title: label,
        remainingSeconds: state.remainingSeconds ?? 0,
      );
    }
    return _SetView(
      step: step,
      exercise: exercise,
      remainingSeconds: state.remainingSeconds,
      timerRunning: state.timerRunning,
    );
  }
}

class _SetView extends StatelessWidget {
  final GymExecutionStep step;
  final GymExercise? exercise;
  final int? remainingSeconds;
  final bool timerRunning;

  const _SetView({
    required this.step,
    required this.exercise,
    required this.remainingSeconds,
    required this.timerRunning,
  });

  @override
  Widget build(BuildContext context) {
    final set = step.set!;
    final type = step.exerciseType;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(exercise?.name ?? 'Exercice', style: AppTypography.headingLarge),
          const SizedBox(height: 4),
          Text(
            [
              'Série ${(step.setIndex ?? 0) + 1} / ${step.totalSets}',
              if (type?.label.isNotEmpty == true) type!.label,
              if (set.durationSeconds != null)
                'Durée ${_formatDurationLabel(set.durationSeconds!)}',
            ].join(' • '),
            style: AppTypography.bodyMedium,
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 16,
            children: [
              if (set.weightKg != null)
                _Stat(label: 'Poids', value: '${set.weightKg} kg'),
              if (set.repetitions != null)
                _Stat(label: 'Reps', value: '${set.repetitions}'),
            ],
          ),
          const SizedBox(height: 24),
          if (type != null && type.hasDuration)
            _CountdownDisplay(
                remaining: remainingSeconds ?? set.durationSeconds ?? 0,
                running: timerRunning),
          if (exercise?.instructions.isNotEmpty == true) ...[
            const SizedBox(height: 24),
            const Text('Instructions', style: AppTypography.labelMedium),
            const SizedBox(height: 4),
            Text(exercise!.instructions, style: AppTypography.bodyMedium),
          ],
          if (exercise?.video != null && exercise!.video!.hasContent) ...[
            const SizedBox(height: 16),
            GymVideoLauncher(
              video: exercise!.video!,
              title: exercise!.name,
            ),
          ],
        ],
      ),
    );
  }
}

class _RestView extends StatelessWidget {
  final String title;
  final int remainingSeconds;
  const _RestView({required this.title, required this.remainingSeconds});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: AppTypography.headingMedium),
          const SizedBox(height: 16),
          _CountdownDisplay(remaining: remainingSeconds, running: true),
        ],
      ),
    );
  }
}

String _formatDurationLabel(int seconds) {
  final m = seconds ~/ 60;
  final s = seconds % 60;
  return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
}

class _CountdownDisplay extends StatelessWidget {
  final int remaining;
  final bool running;
  const _CountdownDisplay({required this.remaining, required this.running});

  String _format(int seconds) => _formatDurationLabel(seconds);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: running ? AppColors.resting : AppColors.border,
        ),
      ),
      child: Text(_format(remaining),
          style: AppTypography.timerDisplay.copyWith(
            color: running ? AppColors.resting : AppColors.textPrimary,
          )),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: AppTypography.labelMedium),
          const SizedBox(height: 2),
          Text(value, style: AppTypography.headingMedium),
        ],
      ),
    );
  }
}

class _Controls extends StatelessWidget {
  final GymExecutionState state;
  final GymExecutionController ctrl;

  const _Controls({required this.state, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final step = state.currentStep!;
    final isSet = step.kind == GymStepKind.set;
    final isTimed = isSet && (step.exerciseType?.hasDuration ?? false);
    final isPaused = state.status == GymRunStatus.paused;

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        children: [
          IconButton(
            iconSize: 32,
            tooltip: 'Précédent',
            icon: const Icon(Icons.skip_previous),
            onPressed: state.currentIndex > 0 ? ctrl.previous : null,
          ),
          if (isTimed && !state.timerRunning && !isPaused)
            Expanded(
              child: ElevatedButton.icon(
                onPressed: ctrl.startTimedSet,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Démarrer chrono'),
              ),
            )
          else if (isPaused)
            Expanded(
              child: ElevatedButton.icon(
                onPressed: ctrl.resume,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Reprendre'),
              ),
            )
          else if (isSet)
            Expanded(
              child: ElevatedButton.icon(
                onPressed: ctrl.validateSet,
                icon: const Icon(Icons.check),
                label: const Text('Valider la série'),
              ),
            )
          else
            Expanded(
              child: ElevatedButton.icon(
                onPressed: ctrl.next,
                icon: const Icon(Icons.skip_next),
                label: const Text('Passer le repos'),
              ),
            ),
          const SizedBox(width: 8),
          IconButton(
            iconSize: 32,
            tooltip: isPaused ? 'Reprendre' : 'Pause',
            icon: Icon(isPaused ? Icons.play_arrow : Icons.pause),
            onPressed: isPaused ? ctrl.resume : ctrl.pause,
          ),
          IconButton(
            iconSize: 32,
            tooltip: 'Passer',
            icon: const Icon(Icons.skip_next),
            onPressed: ctrl.skip,
          ),
        ],
      ),
    );
  }
}

class _FinishedView extends StatelessWidget {
  final String sessionName;
  final VoidCallback onClose;
  const _FinishedView({required this.sessionName, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.celebration, size: 96, color: AppColors.accent),
            const SizedBox(height: 24),
            const Text('Séance terminée', style: AppTypography.headingLarge),
            const SizedBox(height: 8),
            Text(sessionName, style: AppTypography.bodyMedium),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: onClose,
              child: const Text('Retour'),
            ),
          ],
        ),
      ),
    );
  }
}
