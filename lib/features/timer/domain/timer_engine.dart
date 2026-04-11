import 'dart:async';
import '../../../core/audio/tts_service.dart';
import '../../../core/models/set_step.dart';
import '../../../core/models/workout_session.dart';
import '../../../core/services/workout_calculator.dart';
import 'timer_state.dart';

/// Durée du countdown avant chaque série (3, 2, 1, Go)
const int _kCountdownDuration = 3;
const int _kNextSetAnnouncementLeadSeconds = 5;

/// Durée de la phase de préparation initiale, 3-2-1 final inclus.
const int _kPreparingDuration = 5;

/// Moteur du minuteur : machine à états avec un seul Timer.periodic.
/// Règle : le ticker est permanent durant la session.
/// Seules les actions externes (pause/skip/stop) l'arrêtent.
class TimerEngine {
  final TtsService _tts;
  final void Function(TimerState) onStateChanged;

  Timer? _ticker;
  TimerState? _state;
  bool _voiceReady = false;

  TimerEngine({
    required TtsService tts,
    required this.onStateChanged,
  }) : _tts = tts;

  TimerState? get currentState => _state;

  // ═══════════════════════════════════════════════════════════════════
  //  API publique
  // ═══════════════════════════════════════════════════════════════════

  Future<void> start(WorkoutSession session) async {
    _stopTicker();

    final steps = WorkoutCalculator.buildSteps(session);
    if (steps.isEmpty) return;

    // Prépare la voix si activée
    _voiceReady = false;
    if (session.voiceEnabled && session.selectedVoiceId != null) {
      final voices = await _tts.getAvailableVoices();
      try {
        final voice =
            voices.firstWhere((v) => v.key == session.selectedVoiceId);
        _voiceReady = await _tts.setVoice(voice);
      } catch (_) {
        _voiceReady = false;
      }
    }

    _state = TimerState(
      phase: TimerPhase.preparing,
      session: session,
      steps: steps,
      currentStepIndex: 0,
      phaseRemainingSeconds: _kPreparingDuration,
      elapsedSeconds: 0,
    );

    _emit(_state!);
    if (_shouldSpeak() &&
        _kPreparingDuration >= _kNextSetAnnouncementLeadSeconds) {
      await _announceStep(steps.first);
    }
    _startTicker();
  }

  void pause() {
    if (_state == null) return;
    final phase = _state!.phase;
    if (phase == TimerPhase.paused ||
        phase == TimerPhase.finished ||
        phase == TimerPhase.idle) {
      return;
    }

    _stopTicker();
    _state = _state!.copyWith(
      pausedPhase: phase,
      pausedPhaseRemaining: _state!.phaseRemainingSeconds,
      phase: TimerPhase.paused,
    );
    _tts.stop();
    _emit(_state!);
  }

  void resume() {
    if (_state == null || _state!.phase != TimerPhase.paused) return;

    _state = _state!.copyWith(
      phase: _state!.pausedPhase ?? TimerPhase.countdown,
      phaseRemainingSeconds:
          _state!.pausedPhaseRemaining ?? _kCountdownDuration,
      clearPausedPhase: true,
    );
    _emit(_state!);
    _startTicker();
  }

  /// Skip : pendant un set actif → va au repos. Pendant le repos → passe à la suite.
  Future<void> skip() async {
    if (_state == null) return;
    final s = _state!;
    if (s.phase == TimerPhase.paused || s.phase == TimerPhase.finished) return;

    _stopTicker();
    await _tts.stop();

    if (s.phase.isActive ||
        s.phase.isCountdown ||
        s.phase == TimerPhase.preparing) {
      // Simule la fin du set : entre en repos
      await _transitionToRest(s);
    } else if (s.phase.isResting) {
      // Skip repos : passe au set suivant
      await _transitionToNextStep(s);
    }
    // Relance le ticker si la session n'est pas terminée
    if (_state != null && !_state!.phase.isFinished) {
      _startTicker();
    }
  }

  Future<void> previous() async {
    if (_state == null) return;
    final s = _state!;

    _stopTicker();
    await _tts.stop();

    final prevIdx = (s.currentStepIndex - 1).clamp(0, s.steps.length - 1);
    _state = s.copyWith(
      currentStepIndex: prevIdx,
      phase: TimerPhase.countdown,
      phaseRemainingSeconds: _kCountdownDuration,
      countdownValue: _kCountdownDuration,
    );
    await _announceNextSet();
    _emit(_state!);
    _startTicker();
  }

  void stop() {
    _stopTicker();
    _tts.stop();
    if (_state != null) {
      _state = _state!.copyWith(phase: TimerPhase.finished);
      _emit(_state!);
    }
    _state = null;
  }

  void dispose() {
    _stopTicker();
    _tts.dispose();
  }

  // ═══════════════════════════════════════════════════════════════════
  //  Ticker interne (un seul timer, continu)
  // ═══════════════════════════════════════════════════════════════════

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  Future<void> _tick() async {
    if (_state == null) return;
    final s = _state!;

    // Temps global
    _state = s.copyWith(elapsedSeconds: s.elapsedSeconds + 1);
    await _checkMilestoneAnnouncements();

    switch (s.phase) {
      case TimerPhase.preparing:
        await _tickPreparing();
      case TimerPhase.countdown:
        await _tickCountdown();
      case TimerPhase.activeSet:
        await _tickActiveSet();
      case TimerPhase.resting:
      case TimerPhase.transitionRest:
        await _tickResting();
      case TimerPhase.paused:
      case TimerPhase.finished:
      case TimerPhase.idle:
        break;
    }
  }

  Future<void> _tickPreparing() async {
    final s = _state!;
    final remaining = s.phaseRemainingSeconds - 1;

    if (remaining <= 0) {
      await _enterActiveSet(s, stepIndex: s.currentStepIndex);
    } else {
      _state = s.copyWith(phaseRemainingSeconds: remaining);
      _emit(_state!);
      if (_shouldSpeak() && remaining <= _kCountdownDuration) {
        await _tts.speak(remaining.toString());
      }
    }
  }

  Future<void> _tickActiveSet() async {
    final s = _state!;
    // Mode auto-enchaînement : le chrono de série tourne automatiquement.
    if (s.session.autoChain && s.phaseRemainingSeconds > 0) {
      final remaining = s.phaseRemainingSeconds - 1;
      if (remaining <= 0) {
        _state = s.copyWith(phaseRemainingSeconds: 0);
        await _transitionToRest(_state!);
      } else {
        _state = s.copyWith(phaseRemainingSeconds: remaining);
        _emit(_state!);
      }
    } else {
      // Mode manuel : attend "Série terminée".
      _emit(_state!);
    }
  }

  Future<void> _tickCountdown() async {
    final s = _state!;
    final remaining = s.phaseRemainingSeconds - 1;

    if (remaining <= 0) {
      await _enterActiveSet(s, stepIndex: s.currentStepIndex);
    } else {
      _state = s.copyWith(
        phaseRemainingSeconds: remaining,
        countdownValue: remaining,
      );
      _emit(_state!);
      if (_shouldSpeak()) await _tts.speak(remaining.toString());
    }
  }

  Future<void> _tickResting() async {
    final s = _state!;
    final remaining = s.phaseRemainingSeconds - 1;
    final totalRest = s.currentStep?.restAfterSeconds ?? 0;
    final halfRestRemaining = totalRest ~/ 2;

    if (_shouldSpeak()) {
      // Annonce à la moitié du repos seulement si elle ne tombe pas trop près
      // du countdown final.
      if (halfRestRemaining > 7 && remaining == halfRestRemaining) {
        await _tts.speak('$remaining secondes');
      }
    }

    if (_shouldSpeak() && remaining == _kNextSetAnnouncementLeadSeconds) {
      await _announceStep(s.nextStep);
    }

    if (remaining <= 0) {
      await _transitionToNextStep(s, countdownSeconds: 0);
    } else if (remaining <= _kCountdownDuration) {
      await _transitionToNextStep(s, countdownSeconds: remaining);
    } else {
      _state = s.copyWith(phaseRemainingSeconds: remaining);
      _emit(_state!);
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  //  Transitions (n'arrêtent PAS le ticker si appelées depuis _tick)
  // ═══════════════════════════════════════════════════════════════════

  Future<void> _transitionToRest(TimerState s) async {
    final step = s.currentStep;
    if (step == null) return;

    if (step.isLastInSession) {
      _state = s.copyWith(phase: TimerPhase.finished, phaseRemainingSeconds: 0);
      if (_shouldSpeak()) await _tts.speak('Bravo ! Séance terminée !');
      _stopTicker();
      _emit(_state!);
      return;
    }

    final restSeconds = step.restAfterSeconds;
    final isTransition = step.isLastInBlock;

    if (restSeconds <= _kCountdownDuration) {
      await _transitionToNextStep(s, countdownSeconds: restSeconds);
      return;
    }

    _state = s.copyWith(
      phase: isTransition ? TimerPhase.transitionRest : TimerPhase.resting,
      phaseRemainingSeconds: restSeconds,
    );

    if (_shouldSpeak() && isTransition) {
      if (restSeconds < 60) {
        await _tts.speak('Bloc suivant dans $restSeconds secondes.');
      } else {
        final m = restSeconds ~/ 60;
        await _tts.speak('Bloc suivant dans $m minute${m > 1 ? 's' : ''}.');
      }
    }
    _emit(_state!);
  }

  Future<void> _transitionToNextStep(
    TimerState s, {
    int countdownSeconds = _kCountdownDuration,
  }) async {
    final nextIdx = s.currentStepIndex + 1;

    if (nextIdx >= s.steps.length) {
      _state = s.copyWith(phase: TimerPhase.finished, phaseRemainingSeconds: 0);
      if (_shouldSpeak()) await _tts.speak('Bravo ! Séance terminée !');
      _stopTicker();
      _emit(_state!);
      return;
    }

    if (countdownSeconds > 0) {
      await _enterCountdown(
        s,
        stepIndex: nextIdx,
        countdownSeconds: countdownSeconds,
      );
      return;
    }

    await _enterActiveSet(
      s,
      stepIndex: nextIdx,
      announceStepBeforeGo: true,
    );
  }

  Future<void> _enterCountdown(
    TimerState s, {
    required int stepIndex,
    required int countdownSeconds,
  }) async {
    _state = s.copyWith(
      currentStepIndex: stepIndex,
      phase: TimerPhase.countdown,
      phaseRemainingSeconds: countdownSeconds,
      countdownValue: countdownSeconds,
    );
    _emit(_state!);
    if (_shouldSpeak() && countdownSeconds > 0) {
      await _tts.speak(countdownSeconds.toString());
    }
  }

  Future<void> _enterActiveSet(
    TimerState s, {
    required int stepIndex,
    bool announceStepBeforeGo = false,
  }) async {
    final step = s.steps[stepIndex];
    final autoTime =
        s.session.autoChain ? s.session.activeSetDurationSeconds(step.reps) : 0;

    _state = s.copyWith(
      currentStepIndex: stepIndex,
      phase: TimerPhase.activeSet,
      phaseRemainingSeconds: autoTime,
      countdownValue: 0,
    );
    _emit(_state!);

    if (_shouldSpeak()) {
      if (announceStepBeforeGo) {
        await _announceStep(step);
      }
      await _tts.speak('Go');
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  //  Annonces vocales
  // ═══════════════════════════════════════════════════════════════════

  Future<void> _announceNextSet() async {
    await _announceStep(_state?.currentStep);
  }

  Future<void> _announceStep(SetStep? step) async {
    if (!_shouldSpeak()) return;
    if (step == null) return;

    final reps = step.reps;
    final word = reps == 1 ? 'traction' : 'tractions';
    await _tts.speak('$reps $word');
  }

  Future<void> _checkMilestoneAnnouncements() async {
    if (!_shouldSpeak()) return;
    final s = _state!;
    final remaining = s.estimatedRemainingSeconds;
    final milestones = s.session.remainingTimeAnnouncements;
    final announced = Set<int>.from(s.announcedMilestones);

    for (final milestone in milestones) {
      if (!announced.contains(milestone) &&
          remaining <= milestone &&
          remaining > 0) {
        announced.add(milestone);
        _state = _state!.copyWith(announcedMilestones: announced);

        final minutes = milestone ~/ 60;
        final word = minutes > 1 ? 'minutes' : 'minute';
        if (minutes > 0) {
          await _tts.speak('Il reste $minutes $word');
        } else {
          await _tts.speak('Il reste $milestone secondes');
        }
        break;
      }
    }
  }

  bool _shouldSpeak() => _voiceReady && (_state?.session.voiceEnabled ?? false);

  void _emit(TimerState state) => onStateChanged(state);
}
