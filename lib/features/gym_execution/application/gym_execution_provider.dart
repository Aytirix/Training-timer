import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/gym/gym_exercise.dart';
import '../../../core/models/gym/gym_session.dart';
import '../../../core/models/gym/gym_session_item.dart';
import '../../gym/domain/gym_provider.dart';
import '../domain/gym_execution_sequence.dart';
import '../domain/gym_execution_state.dart';

class GymExecutionController extends StateNotifier<GymExecutionState?> {
  final Ref _ref;
  Timer? _timer;

  GymExecutionController(this._ref) : super(null);

  void start(GymSession session) {
    _timer?.cancel();
    final exercises = _ref.read(gymExercisesProvider).exercises;
    final byId = {for (final e in exercises) e.id: e};
    final builder = GymExecutionSequenceBuilder(
      session: session,
      resolveType: (id) => byId[id]?.type,
    );
    final steps = builder.build();
    state = GymExecutionState(
      session: session,
      steps: steps,
      currentIndex: 0,
      status: GymRunStatus.running,
    );
    _onEnterStep();
  }

  GymExercise? exerciseFor(String? id) {
    if (id == null) return null;
    final exercises = _ref.read(gymExercisesProvider).exercises;
    for (final e in exercises) {
      if (e.id == id) return e;
    }
    return null;
  }

  void _onEnterStep() {
    final s = state;
    if (s == null) return;
    final step = s.currentStep;
    if (step == null) {
      state = s.copyWith(status: GymRunStatus.finished, timerRunning: false);
      _timer?.cancel();
      return;
    }
    switch (step.kind) {
      case GymStepKind.set:
        if (step.exerciseType != null && step.exerciseType!.hasDuration) {
          // Série en durée
          state = s.copyWith(
            remainingSeconds: step.set?.durationSeconds ?? 0,
            timerRunning: step.timedSetStartMode == TimedSetStartMode.automatic,
            status: GymRunStatus.running,
          );
          _scheduleTickIfRunning();
        } else {
          // Série en répétitions
          state = s.copyWith(
            clearRemaining: true,
            timerRunning: false,
            status: GymRunStatus.running,
          );
        }
        break;
      case GymStepKind.restAfterSet:
      case GymStepKind.restBetweenExercises:
        state = s.copyWith(
          remainingSeconds: step.restSeconds ?? 0,
          timerRunning: true,
          status: GymRunStatus.resting,
        );
        _scheduleTickIfRunning();
        break;
    }
  }

  void _scheduleTickIfRunning() {
    _timer?.cancel();
    final s = state;
    if (s == null || !s.timerRunning) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final cur = state;
      if (cur == null || !cur.timerRunning) return;
      final remaining = (cur.remainingSeconds ?? 0) - 1;
      if (remaining <= 0) {
        _timer?.cancel();
        state = cur.copyWith(remainingSeconds: 0, timerRunning: false);
        // Ne passe pas automatiquement : laisse l'utilisateur valider/passer
      } else {
        state = cur.copyWith(remainingSeconds: remaining);
      }
    });
  }

  void next() {
    final s = state;
    if (s == null) return;
    _timer?.cancel();
    final nextIdx = s.currentIndex + 1;
    if (nextIdx >= s.steps.length) {
      state = s.copyWith(
        currentIndex: nextIdx,
        status: GymRunStatus.finished,
        timerRunning: false,
        clearRemaining: true,
      );
      return;
    }
    state = s.copyWith(currentIndex: nextIdx, clearRemaining: true);
    _onEnterStep();
  }

  void previous() {
    final s = state;
    if (s == null) return;
    _timer?.cancel();
    final prevIdx = s.currentIndex - 1;
    if (prevIdx < 0) return;
    state = s.copyWith(currentIndex: prevIdx, clearRemaining: true);
    _onEnterStep();
  }

  /// Validation explicite de la série courante.
  void validateSet() => next();

  /// L'utilisateur passe sans valider.
  void skip() => next();

  void pause() {
    final s = state;
    if (s == null) return;
    _timer?.cancel();
    state = s.copyWith(timerRunning: false, status: GymRunStatus.paused);
  }

  void resume() {
    final s = state;
    if (s == null) return;
    state = s.copyWith(
      timerRunning: true,
      status: s.currentStep?.kind == GymStepKind.set
          ? GymRunStatus.running
          : GymRunStatus.resting,
    );
    _scheduleTickIfRunning();
  }

  /// Démarre manuellement le chrono d'une série en durée.
  void startTimedSet() {
    final s = state;
    if (s == null) return;
    final step = s.currentStep;
    if (step == null || step.kind != GymStepKind.set) return;
    state = s.copyWith(
      remainingSeconds: s.remainingSeconds ?? step.set?.durationSeconds ?? 0,
      timerRunning: true,
    );
    _scheduleTickIfRunning();
  }

  void stop() {
    _timer?.cancel();
    state = null;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final gymExecutionProvider =
    StateNotifierProvider<GymExecutionController, GymExecutionState?>((ref) {
  return GymExecutionController(ref);
});
