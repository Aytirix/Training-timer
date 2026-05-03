import 'package:flutter_test/flutter_test.dart';
import 'package:traction_timer/core/models/gym/gym_exercise.dart';
import 'package:traction_timer/core/models/gym/gym_session.dart';
import 'package:traction_timer/core/models/gym/gym_session_item.dart';
import 'package:traction_timer/core/models/gym/gym_set.dart';
import 'package:traction_timer/features/gym_execution/domain/gym_execution_sequence.dart';

void main() {
  group('GymExecutionSequenceBuilder', () {
    test('séquence simple sans repos', () {
      final session = GymSession(name: 'A', items: [
        GymSessionExerciseItem(exerciseId: 'ex1', sets: const [
          GymSet(repetitions: 8),
          GymSet(repetitions: 8),
        ]),
      ]);
      final builder = GymExecutionSequenceBuilder(
        session: session,
        resolveType: (_) => GymExerciseType.repetitions,
      );
      final steps = builder.build();
      // 2 séries, pas de repos (restAfterSet=0/null)
      expect(steps.length, 2);
      expect(
          steps.where((s) => s.kind == GymStepKind.set).length, 2);
    });

    test('repos après série inséré quand non dernière', () {
      final session = GymSession(name: 'A', items: [
        GymSessionExerciseItem(exerciseId: 'ex1', sets: const [
          GymSet(repetitions: 8, restAfterSetSeconds: 30),
          GymSet(repetitions: 8, restAfterSetSeconds: 60),
          GymSet(repetitions: 8, restAfterSetSeconds: 120),
        ]),
      ]);
      final builder = GymExecutionSequenceBuilder(
        session: session,
        resolveType: (_) => GymExerciseType.repetitions,
      );
      final steps = builder.build();
      // 3 séries + 2 repos (repos après dernière ignoré)
      expect(steps.length, 5);
      expect(steps[0].kind, GymStepKind.set);
      expect(steps[1].kind, GymStepKind.restAfterSet);
      expect(steps[1].restSeconds, 30);
      expect(steps[2].kind, GymStepKind.set);
      expect(steps[3].kind, GymStepKind.restAfterSet);
      expect(steps[4].kind, GymStepKind.set);
    });

    test('repos entre exercices', () {
      final session = GymSession(name: 'A', items: [
        GymSessionExerciseItem(exerciseId: 'ex1', sets: const [
          GymSet(repetitions: 8),
        ]),
        GymSessionRestItem(durationSeconds: 60),
        GymSessionExerciseItem(exerciseId: 'ex2', sets: const [
          GymSet(repetitions: 5),
        ]),
      ]);
      final builder = GymExecutionSequenceBuilder(
        session: session,
        resolveType: (_) => GymExerciseType.repetitions,
      );
      final steps = builder.build();
      expect(steps.length, 3);
      expect(steps[1].kind, GymStepKind.restBetweenExercises);
      expect(steps[1].restSeconds, 60);
    });

    test('repos vide ignoré', () {
      final session = GymSession(name: 'A', items: [
        GymSessionExerciseItem(exerciseId: 'ex1', sets: const [
          GymSet(repetitions: 8),
        ]),
        GymSessionRestItem(durationSeconds: 0),
        GymSessionExerciseItem(exerciseId: 'ex2', sets: const [
          GymSet(repetitions: 5),
        ]),
      ]);
      final builder = GymExecutionSequenceBuilder(
        session: session,
        resolveType: (_) => GymExerciseType.repetitions,
      );
      final steps = builder.build();
      expect(steps.length, 2);
      expect(steps.where((s) => s.kind == GymStepKind.restBetweenExercises).length, 0);
    });

    test('série en durée garde son mode', () {
      final session = GymSession(name: 'A', items: [
        GymSessionExerciseItem(
          exerciseId: 'ex1',
          timedSetStartMode: TimedSetStartMode.automatic,
          sets: const [GymSet(durationSeconds: 30)],
        ),
      ]);
      final builder = GymExecutionSequenceBuilder(
        session: session,
        resolveType: (_) => GymExerciseType.duree,
      );
      final steps = builder.build();
      expect(steps.length, 1);
      expect(steps.first.timedSetStartMode, TimedSetStartMode.automatic);
    });

    test('repos entre exercices en fin ignoré (pas d\'exercice après)', () {
      final session = GymSession(name: 'A', items: [
        GymSessionExerciseItem(exerciseId: 'ex1', sets: const [
          GymSet(repetitions: 8),
        ]),
        GymSessionRestItem(durationSeconds: 60),
      ]);
      final builder = GymExecutionSequenceBuilder(
        session: session,
        resolveType: (_) => GymExerciseType.repetitions,
      );
      final steps = builder.build();
      expect(steps.length, 1);
    });
  });
}
