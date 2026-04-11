import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traction_timer/core/audio/tts_service.dart';
import 'package:traction_timer/core/models/workout_block.dart';
import 'package:traction_timer/core/models/workout_session.dart';
import 'package:traction_timer/features/timer/domain/timer_engine.dart';
import 'package:traction_timer/features/timer/domain/timer_state.dart';

class _FakeTtsService extends TtsService {
  @override
  Future<void> dispose() async {}

  @override
  Future<List<VoiceInfo>> getAvailableVoices() async => const [];

  @override
  Future<void> init() async {}

  @override
  Future<bool> setVoice(VoiceInfo voice) async => true;

  @override
  Future<void> speak(String text) async {}

  @override
  Future<void> stop() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'la première série démarre après 5 secondes sans relancer un countdown de 3 secondes',
    () {
      fakeAsync((async) {
        final emittedStates = <TimerState>[];
        final engine = TimerEngine(
          tts: _FakeTtsService(),
          onStateChanged: emittedStates.add,
        );

        final session = WorkoutSession(
          name: 'Test',
          autoChain: false,
          blocks: [
            WorkoutBlock(name: 'Bloc', sequence: const [5]),
          ],
        );

        engine.start(session);
        async.flushMicrotasks();

        expect(engine.currentState?.phase, TimerPhase.preparing);
        expect(engine.currentState?.phaseRemainingSeconds, 5);

        async.elapse(const Duration(seconds: 4));
        expect(engine.currentState?.phase, TimerPhase.preparing);
        expect(engine.currentState?.phaseRemainingSeconds, 1);

        async.elapse(const Duration(seconds: 1));
        expect(engine.currentState?.phase, TimerPhase.activeSet);
        expect(
          emittedStates.where((state) => state.phase == TimerPhase.countdown),
          isEmpty,
        );

        engine.dispose();
      });
    },
  );
}
