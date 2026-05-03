import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:traction_timer/core/models/gym/gym_exercise.dart';
import 'package:traction_timer/core/models/gym/gym_session.dart';
import 'package:traction_timer/core/models/gym/gym_session_item.dart';
import 'package:traction_timer/core/models/gym/gym_set.dart';
import 'package:traction_timer/core/storage/local_storage.dart';
import 'package:traction_timer/features/gym/data/gym_repository.dart';

Future<GymRepository> _makeRepo() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  return GymRepository(LocalStorage(prefs));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GymRepository - exercices', () {
    test('liste vide au démarrage', () async {
      final repo = await _makeRepo();
      expect(repo.loadExercises(), isEmpty);
    });

    test('save + reload', () async {
      final repo = await _makeRepo();
      final ex =
          GymExercise(name: 'Squat', type: GymExerciseType.poidsRepetitions);
      await repo.saveExercise(ex);
      final loaded = repo.loadExercises();
      expect(loaded.length, 1);
      expect(loaded.first.name, 'Squat');
    });

    test('détecte doublon nom + type', () async {
      final repo = await _makeRepo();
      final a =
          GymExercise(name: 'Squat', type: GymExerciseType.poidsRepetitions);
      await repo.saveExercise(a);
      final b =
          GymExercise(name: 'SQUAT', type: GymExerciseType.poidsRepetitions);
      expect(repo.hasDuplicateFunctionalKey(b), true);
    });

    test('même nom type différent autorisé', () async {
      final repo = await _makeRepo();
      final a = GymExercise(name: 'Gainage', type: GymExerciseType.duree);
      await repo.saveExercise(a);
      final b = GymExercise(name: 'Gainage', type: GymExerciseType.poidsDuree);
      expect(repo.hasDuplicateFunctionalKey(b), false);
    });

    test('findFunctionalMatch normalise', () async {
      final repo = await _makeRepo();
      final a = GymExercise(
          name: 'Développé Couché', type: GymExerciseType.poidsRepetitions);
      await repo.saveExercise(a);
      final found = repo.findFunctionalMatch(
          'developpe   couche', GymExerciseType.poidsRepetitions);
      expect(found?.id, a.id);
    });
  });

  group('GymRepository - séances', () {
    test('save + reload', () async {
      final repo = await _makeRepo();
      final ex =
          GymExercise(name: 'Squat', type: GymExerciseType.poidsRepetitions);
      await repo.saveExercise(ex);
      final session = GymSession(name: 'Jambes', items: [
        GymSessionExerciseItem(
            exerciseId: ex.id,
            sets: const [GymSet(weightKg: 60, repetitions: 10)]),
      ]);
      await repo.saveSession(session);
      final loaded = repo.loadSessions();
      expect(loaded.length, 1);
      expect(loaded.first.name, 'Jambes');
      expect(loaded.first.items.length, 1);
    });

    test('deleteSession', () async {
      final repo = await _makeRepo();
      final session = GymSession(name: 'A', items: []);
      await repo.saveSession(session);
      await repo.deleteSession(session.id);
      expect(repo.loadSessions(), isEmpty);
    });
  });

  group('GymRepository - suppression exercice utilisé', () {
    test('liste les séances impactées et nettoie', () async {
      final repo = await _makeRepo();
      final ex1 =
          GymExercise(name: 'Squat', type: GymExerciseType.poidsRepetitions);
      final ex2 = GymExercise(name: 'Gainage', type: GymExerciseType.duree);
      await repo.saveExercise(ex1);
      await repo.saveExercise(ex2);

      final s1 = GymSession(name: 'A', items: [
        GymSessionExerciseItem(
            exerciseId: ex1.id,
            sets: const [GymSet(weightKg: 60, repetitions: 10)]),
        GymSessionRestItem(durationSeconds: 60),
        GymSessionExerciseItem(
          exerciseId: ex2.id,
          timedSetStartMode: TimedSetStartMode.manual,
          sets: const [GymSet(durationSeconds: 30)],
        ),
      ]);
      final s2 = GymSession(name: 'B', items: [
        GymSessionExerciseItem(
            exerciseId: ex1.id,
            sets: const [GymSet(weightKg: 80, repetitions: 5)]),
      ]);
      await repo.saveSession(s1);
      await repo.saveSession(s2);

      final result = await repo.deleteExercise(ex1.id);
      expect(result.impactedSessions.length, 2);

      // ex1 supprimé
      expect(repo.loadExercises().any((e) => e.id == ex1.id), false);

      // s1 ne contient plus ex1, et le repos qui suivait ex1 est retiré.
      final sessions = repo.loadSessions();
      final cleanedS1 = sessions.firstWhere((s) => s.id == s1.id);
      expect(cleanedS1.items.whereType<GymSessionExerciseItem>().length, 1);
      expect(
          (cleanedS1.items.whereType<GymSessionExerciseItem>().first)
              .exerciseId,
          ex2.id);
      expect(cleanedS1.items.whereType<GymSessionRestItem>(), isEmpty);

      // s2 devient vide mais reste sauvegardée
      final cleanedS2 = sessions.firstWhere((s) => s.id == s2.id);
      expect(cleanedS2.items, isEmpty);
    });

    test('suppression sans usage ne casse rien', () async {
      final repo = await _makeRepo();
      final ex = GymExercise(name: 'X', type: GymExerciseType.repetitions);
      await repo.saveExercise(ex);
      final result = await repo.deleteExercise(ex.id);
      expect(result.impactedSessions, isEmpty);
      expect(repo.loadExercises(), isEmpty);
    });

    test('nettoie les repos orphelins ou consécutifs après suppression',
        () async {
      final repo = await _makeRepo();
      final ex1 =
          GymExercise(name: 'Squat', type: GymExerciseType.poidsRepetitions);
      final ex2 =
          GymExercise(name: 'Rowing', type: GymExerciseType.poidsRepetitions);
      final ex3 =
          GymExercise(name: 'Pompes', type: GymExerciseType.repetitions);
      await repo.saveExercise(ex1);
      await repo.saveExercise(ex2);
      await repo.saveExercise(ex3);

      final session = GymSession(name: 'A', items: [
        GymSessionExerciseItem(
            exerciseId: ex1.id,
            sets: const [GymSet(weightKg: 60, repetitions: 10)]),
        GymSessionRestItem(durationSeconds: 60),
        GymSessionExerciseItem(
            exerciseId: ex2.id,
            sets: const [GymSet(weightKg: 50, repetitions: 10)]),
        GymSessionRestItem(durationSeconds: 90),
        GymSessionExerciseItem(
            exerciseId: ex3.id, sets: const [GymSet(repetitions: 20)]),
      ]);
      await repo.saveSession(session);

      await repo.deleteExercise(ex2.id);

      final cleaned = repo.loadSessions().single;
      expect(cleaned.items, hasLength(3));
      expect(cleaned.items[0], isA<GymSessionExerciseItem>());
      expect(cleaned.items[1], isA<GymSessionRestItem>());
      expect(cleaned.items[2], isA<GymSessionExerciseItem>());
      expect((cleaned.items[1] as GymSessionRestItem).durationSeconds, 60);
      expect((cleaned.items[2] as GymSessionExerciseItem).exerciseId, ex3.id);
    });
  });

  test('cohabitation avec workout sessions existantes', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final storage = LocalStorage(prefs);

    // Pas de sessions classiques au départ
    expect(storage.loadSessions(), isEmpty);
    expect(storage.loadGymExercises(), isEmpty);
    expect(storage.loadGymSessions(), isEmpty);

    // Sauvegarde d'un exercice gym ne casse pas les workouts classiques
    final ex = GymExercise(name: 'A', type: GymExerciseType.repetitions);
    await storage.saveGymExercises([ex]);
    expect(storage.loadGymExercises().length, 1);
    expect(storage.loadSessions(), isEmpty);
  });
}
