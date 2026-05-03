import 'package:flutter_test/flutter_test.dart';
import 'package:traction_timer/core/models/gym/gym_exercise.dart';
import 'package:traction_timer/core/models/gym/gym_session.dart';
import 'package:traction_timer/core/models/gym/gym_session_item.dart';
import 'package:traction_timer/core/models/gym/gym_set.dart';

GymExerciseType? _resolverFor(Map<String, GymExerciseType> map) =>
    null; // placeholder

void main() {
  group('GymSession.validate', () {
    test('séance sans nom => erreur', () {
      final s = GymSession(name: '', items: []);
      final errors = s.validate((id) => null);
      expect(errors.any((e) => e.code == 'session.name'), true);
    });

    test('séance vide => erreur', () {
      final s = GymSession(name: 'Test', items: []);
      final errors = s.validate((id) => null);
      expect(errors.any((e) => e.code == 'session.items'), true);
    });

    test('exercice référence introuvable', () {
      final s = GymSession(
        name: 'Test',
        items: [
          GymSessionExerciseItem(
            exerciseId: 'absent',
            sets: const [GymSet(repetitions: 8)],
          )
        ],
      );
      final errors = s.validate((id) => null);
      expect(errors.any((e) => e.message.contains('introuvable')), true);
    });

    test('exercice sans série => erreur', () {
      final s = GymSession(
        name: 'Test',
        items: [
          GymSessionExerciseItem(exerciseId: 'ex1', sets: const []),
        ],
      );
      final errors =
          s.validate((id) => GymExerciseType.repetitions);
      expect(errors.any((e) => e.message.contains('série')), true);
    });

    test('série incomplète => erreur', () {
      final s = GymSession(
        name: 'Test',
        items: [
          GymSessionExerciseItem(
              exerciseId: 'ex1', sets: const [GymSet()]),
        ],
      );
      final errors =
          s.validate((id) => GymExerciseType.poidsRepetitions);
      expect(errors.isNotEmpty, true);
    });

    test('série en durée sans mode => erreur', () {
      final s = GymSession(
        name: 'Test',
        items: [
          GymSessionExerciseItem(
            exerciseId: 'ex1',
            sets: const [GymSet(durationSeconds: 30)],
          ),
        ],
      );
      final errors = s.validate((id) => GymExerciseType.duree);
      expect(errors.any((e) => e.code.contains('timedSetStartMode')), true);
    });

    test('séance valide', () {
      final s = GymSession(
        name: 'Force',
        items: [
          GymSessionExerciseItem(
            exerciseId: 'ex1',
            sets: const [
              GymSet(weightKg: 60, repetitions: 10, restAfterSetSeconds: 90),
              GymSet(weightKg: 60, repetitions: 10),
            ],
          ),
          GymSessionRestItem(durationSeconds: 120),
          GymSessionExerciseItem(
            exerciseId: 'ex2',
            timedSetStartMode: TimedSetStartMode.manual,
            sets: const [GymSet(durationSeconds: 45)],
          ),
        ],
      );
      final errors = s.validate((id) {
        if (id == 'ex1') return GymExerciseType.poidsRepetitions;
        if (id == 'ex2') return GymExerciseType.duree;
        return null;
      });
      expect(errors, isEmpty);
    });

    test('duplicate génère un nouvel ID', () {
      final s = GymSession(name: 'Force', items: []);
      final dup = s.duplicate();
      expect(dup.id, isNot(s.id));
      expect(dup.name, 'Force (copie)');
    });

    test('duplicate copie les séries en profondeur', () {
      final s = GymSession(name: 'Force', items: [
        GymSessionExerciseItem(
            exerciseId: 'ex1',
            sets: const [GymSet(weightKg: 60, repetitions: 10)]),
      ]);
      final dup = s.duplicate();
      final origItem = s.items.first as GymSessionExerciseItem;
      final dupItem = dup.items.first as GymSessionExerciseItem;
      expect(dupItem.id, isNot(origItem.id));
      expect(dupItem.exerciseId, origItem.exerciseId);
      expect(dupItem.sets.first.weightKg, 60);
    });
  });

  // évite warning unused
  _resolverFor({});
}
