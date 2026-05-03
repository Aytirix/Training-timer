import '../../../core/models/gym/gym_session.dart';
import 'gym_execution_sequence.dart';

enum GymRunStatus {
  idle,
  running,
  paused,
  resting,
  finished,
}

class GymExecutionState {
  final GymSession session;
  final List<GymExecutionStep> steps;
  final int currentIndex;
  final int? remainingSeconds; // pour repos ou série en durée
  final bool timerRunning;
  final GymRunStatus status;

  const GymExecutionState({
    required this.session,
    required this.steps,
    this.currentIndex = 0,
    this.remainingSeconds,
    this.timerRunning = false,
    this.status = GymRunStatus.idle,
  });

  GymExecutionStep? get currentStep =>
      currentIndex < steps.length ? steps[currentIndex] : null;

  bool get isFinished =>
      status == GymRunStatus.finished || currentIndex >= steps.length;

  GymExecutionState copyWith({
    int? currentIndex,
    int? remainingSeconds,
    bool? timerRunning,
    GymRunStatus? status,
    bool clearRemaining = false,
  }) =>
      GymExecutionState(
        session: session,
        steps: steps,
        currentIndex: currentIndex ?? this.currentIndex,
        remainingSeconds:
            clearRemaining ? null : (remainingSeconds ?? this.remainingSeconds),
        timerRunning: timerRunning ?? this.timerRunning,
        status: status ?? this.status,
      );
}
