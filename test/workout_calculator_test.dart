import 'package:flutter_test/flutter_test.dart';
import 'package:traction_timer/core/services/workout_calculator.dart';
import 'package:traction_timer/features/workouts/data/default_workouts.dart';

void main() {
  group('WorkoutCalculator', () {
    test('séance par défaut génère 110 reps', () {
      final session = DefaultWorkouts.tractions110;
      expect(session.totalReps, 110);
    });

    test('buildSteps génère le bon nombre de séries', () {
      final session = DefaultWorkouts.tractions110;
      final steps = WorkoutCalculator.buildSteps(session);
      expect(steps.length, session.totalSets);
    });

    test('dernière étape n\'a pas de repos', () {
      final session = DefaultWorkouts.tractions110;
      final steps = WorkoutCalculator.buildSteps(session);
      expect(steps.last.restAfterSeconds, 0);
      expect(steps.last.isLastInSession, isTrue);
    });

    test('transition entre blocs utilise transitionRestSeconds', () {
      final session = DefaultWorkouts.tractions110;
      final steps = WorkoutCalculator.buildSteps(session);

      // Trouve la dernière étape du bloc A
      final lastOfBlockA = steps.firstWhere(
        (s) => s.isLastInBlock && s.blockIndex == 0,
      );
      expect(
        lastOfBlockA.restAfterSeconds,
        session.blocks[0].transitionRestSeconds,
      );
    });

    test('computeStats retourne les bonnes valeurs', () {
      final session = DefaultWorkouts.tractions110;
      final stats = WorkoutCalculator.computeStats(session);
      expect(stats.totalReps, 110);
      expect(stats.totalSets, session.totalSets);
      expect(stats.estimatedDurationSeconds, greaterThan(0));
    });

    test('le temps par traction ajuste la durée estimée', () {
      final fastSession =
          DefaultWorkouts.tractions110.copyWith(secondsPerRep: 2);
      final slowSession =
          DefaultWorkouts.tractions110.copyWith(secondsPerRep: 4);

      expect(slowSession.estimatedDurationSeconds,
          greaterThan(fastSession.estimatedDurationSeconds));

      final stats = WorkoutCalculator.computeStats(slowSession);
      expect(
          stats.estimatedDurationSeconds, slowSession.estimatedDurationSeconds);
    });

    test('les repos précis restPerSet sont prioritaires quand définis', () {
      final session = DefaultWorkouts.tractions110;
      final steps = WorkoutCalculator.buildSteps(session);

      // Bloc 1 : la première série de 1 rep utilise le repos précis configuré.
      final smallStep =
          steps.firstWhere((s) => s.reps == 1 && !s.isLastInSession);
      expect(smallStep.restAfterSeconds, 10);

      // Bloc 2 : la série de 8 reps utilise aussi la valeur précise.
      final largeStep = steps.firstWhere(
        (s) => s.reps == 8 && !s.isLastInSession && !s.isLastInBlock,
      );
      expect(largeStep.restAfterSeconds, 105);
    });
  });
}
