import '../../../core/models/set_step.dart';
import '../../../core/models/workout_session.dart';

/// États du minuteur (machine à états).
enum TimerPhase {
  idle, // aucune session active
  preparing, // échauffement initial (countdown avant le tout premier set)
  countdown, // compte à rebours 3-2-1 avant une série
  activeSet, // série en cours (user fait ses reps)
  resting, // repos chronométré entre séries
  transitionRest, // repos long entre blocs
  paused, // session en pause
  finished, // session terminée
}

extension TimerPhaseExtension on TimerPhase {
  String get label {
    switch (this) {
      case TimerPhase.idle:
        return 'Prêt';
      case TimerPhase.preparing:
        return 'Préparation';
      case TimerPhase.countdown:
        return 'Prêt ?';
      case TimerPhase.activeSet:
        return 'GO !';
      case TimerPhase.resting:
        return 'Repos';
      case TimerPhase.transitionRest:
        return 'Transition';
      case TimerPhase.paused:
        return 'Pause';
      case TimerPhase.finished:
        return 'Terminé !';
    }
  }

  bool get isActive => this == TimerPhase.activeSet;
  bool get isResting =>
      this == TimerPhase.resting || this == TimerPhase.transitionRest;
  bool get isPaused => this == TimerPhase.paused;
  bool get isCountdown =>
      this == TimerPhase.countdown || this == TimerPhase.preparing;
  bool get isFinished => this == TimerPhase.finished;
  bool get isRunning =>
      this != TimerPhase.idle &&
      this != TimerPhase.paused &&
      this != TimerPhase.finished;
}

/// État complet du minuteur, immutable.
class TimerState {
  final TimerPhase phase;
  final WorkoutSession session;
  final List<SetStep> steps;
  final int currentStepIndex;

  /// Secondes restantes dans la phase courante (countdown, repos, etc.)
  final int phaseRemainingSeconds;

  /// Valeur affichée pendant le countdown : 3, 2, 1
  final int countdownValue;

  /// Phase d'avant la pause (pour reprendre)
  final TimerPhase? pausedPhase;
  final int? pausedPhaseRemaining;

  /// Temps total écoulé depuis le début de la session
  final int elapsedSeconds;

  /// Jalons d'annonce déjà effectués (en secondes restantes)
  final Set<int> announcedMilestones;

  const TimerState({
    required this.phase,
    required this.session,
    required this.steps,
    required this.currentStepIndex,
    required this.phaseRemainingSeconds,
    this.countdownValue = 3,
    this.pausedPhase,
    this.pausedPhaseRemaining,
    required this.elapsedSeconds,
    this.announcedMilestones = const {},
  });

  // ───────── Computed ─────────

  bool get hasSteps => steps.isNotEmpty;

  SetStep? get currentStep =>
      currentStepIndex < steps.length ? steps[currentStepIndex] : null;

  SetStep? get nextStep =>
      currentStepIndex + 1 < steps.length ? steps[currentStepIndex + 1] : null;

  int get totalSteps => steps.length;

  double get globalProgress =>
      totalSteps == 0 ? 0 : currentStepIndex / totalSteps;

  /// Seconds estimés restants pour la session entière
  int get estimatedRemainingSeconds =>
      (session.estimatedDurationSeconds - elapsedSeconds).clamp(0, 999999);

  String get elapsedLabel => _formatDuration(elapsedSeconds);
  String get estimatedRemainingLabel =>
      _formatDuration(estimatedRemainingSeconds);

  String get phaseRemainingLabel => _formatDuration(phaseRemainingSeconds);

  static String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  TimerState copyWith({
    TimerPhase? phase,
    WorkoutSession? session,
    List<SetStep>? steps,
    int? currentStepIndex,
    int? phaseRemainingSeconds,
    int? countdownValue,
    TimerPhase? pausedPhase,
    int? pausedPhaseRemaining,
    int? elapsedSeconds,
    Set<int>? announcedMilestones,
    bool clearPausedPhase = false,
  }) {
    return TimerState(
      phase: phase ?? this.phase,
      session: session ?? this.session,
      steps: steps ?? this.steps,
      currentStepIndex: currentStepIndex ?? this.currentStepIndex,
      phaseRemainingSeconds:
          phaseRemainingSeconds ?? this.phaseRemainingSeconds,
      countdownValue: countdownValue ?? this.countdownValue,
      pausedPhase: clearPausedPhase ? null : (pausedPhase ?? this.pausedPhase),
      pausedPhaseRemaining: clearPausedPhase
          ? null
          : (pausedPhaseRemaining ?? this.pausedPhaseRemaining),
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      announcedMilestones: announcedMilestones ?? this.announcedMilestones,
    );
  }
}
