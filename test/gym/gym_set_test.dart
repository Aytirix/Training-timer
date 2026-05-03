import 'package:flutter_test/flutter_test.dart';
import 'package:traction_timer/core/models/gym/gym_exercise.dart';
import 'package:traction_timer/core/models/gym/gym_set.dart';

void main() {
  group('GymSet validation', () {
    test('poids_repetitions : poids et reps obligatoires', () {
      const s = GymSet();
      final errors = s.validate(GymExerciseType.poidsRepetitions, isLast: true);
      expect(errors.length, 2);
    });

    test('poids_repetitions valide', () {
      const s = GymSet(weightKg: 60, repetitions: 10);
      expect(s.isValid(GymExerciseType.poidsRepetitions, isLast: true), true);
    });

    test('repetitions : seules les reps comptent', () {
      const s = GymSet(repetitions: 8);
      expect(s.isValid(GymExerciseType.repetitions, isLast: true), true);
    });

    test('duree : seule la durée compte', () {
      const s = GymSet(durationSeconds: 45);
      expect(s.isValid(GymExerciseType.duree, isLast: true), true);
    });

    test('poids_duree : poids + durée', () {
      const s = GymSet(weightKg: 10, durationSeconds: 45);
      expect(s.isValid(GymExerciseType.poidsDuree, isLast: true), true);
    });

    test('repetitions <= 0 invalide', () {
      const s = GymSet(repetitions: 0);
      expect(s.isValid(GymExerciseType.repetitions, isLast: true), false);
    });

    test('repos négatif invalide quand pas dernière', () {
      const s = GymSet(repetitions: 8, restAfterSetSeconds: -1);
      expect(s.isValid(GymExerciseType.repetitions, isLast: false), false);
    });

    test('repos sur dernière série toléré (ignoré)', () {
      const s = GymSet(repetitions: 8, restAfterSetSeconds: -1);
      expect(s.isValid(GymExerciseType.repetitions, isLast: true), true);
    });
  });
}
