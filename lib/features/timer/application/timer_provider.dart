import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/workout_session.dart';
import '../../../core/audio/tts_service.dart';
import '../../voice/application/voice_provider.dart';
import '../domain/timer_engine.dart';
import '../domain/timer_state.dart';

// ── Provider ──

class TimerNotifier extends StateNotifier<TimerState?> {
  late final TimerEngine _engine;

  TimerNotifier(TtsService tts) : super(null) {
    _engine = TimerEngine(
      tts: tts,
      onStateChanged: (s) {
        if (mounted) state = s;
      },
    );
  }

  Future<void> startSession(WorkoutSession session) async {
    await _engine.start(session);
  }

  void pause() => _engine.pause();
  void resume() => _engine.resume();
  Future<void> skip() => _engine.skip();
  Future<void> previous() => _engine.previous();
  void stop() {
    _engine.stop();
    state = null;
  }

  bool get isActive => state != null && state!.phase != TimerPhase.idle;

  @override
  void dispose() {
    _engine.dispose();
    super.dispose();
  }
}

final timerProvider = StateNotifierProvider<TimerNotifier, TimerState?>((ref) {
  final tts = ref.watch(ttsServiceProvider);
  return TimerNotifier(tts);
});

/// Provider de commodité pour l'état courant du timer (non null quand actif).
final activeTimerProvider = Provider<TimerState?>((ref) {
  return ref.watch(timerProvider);
});
