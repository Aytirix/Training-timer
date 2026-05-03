import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:traction_timer/core/models/gym/gym_exercise.dart';
import 'package:traction_timer/core/storage/local_storage.dart';
import 'package:traction_timer/features/gym/data/gym_import_service.dart';
import 'package:traction_timer/features/gym/data/gym_repository.dart';

const baseJson = '''
{
  "version": 1,
  "session": {
    "name": "Force",
    "description": "",
    "items": [
      {
        "kind": "exercise",
        "exercise": {
          "name": "Développé couché",
          "type": "poids_repetitions",
          "instructions": "v2"
        },
        "sets": [
          {"weightKg": 60, "repetitions": 10}
        ]
      }
    ]
  }
}
''';

Future<GymRepository> _makeRepo() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  return GymRepository(LocalStorage(prefs));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('crée l\'exercice manquant et la séance', () async {
    final repo = await _makeRepo();
    final service = GymImportService(repo);
    final plan = service.prepare(baseJson);
    expect(plan.toCreate.length, 1);
    expect(plan.reused, isEmpty);
    expect(plan.conflicts, isEmpty);

    final session = await service.apply(plan);
    expect(repo.loadExercises().length, 1);
    expect(repo.loadSessions().length, 1);
    expect(repo.loadSessions().first.id, session.id);
  });

  test('détecte exercice existant identique', () async {
    final repo = await _makeRepo();
    final existing = GymExercise(
      name: 'Développé Couché',
      type: GymExerciseType.poidsRepetitions,
      instructions: 'v2',
    );
    await repo.saveExercise(existing);

    final plan = GymImportService(repo).prepare(baseJson);
    expect(plan.toCreate, isEmpty);
    expect(plan.reused.length, 1);
    expect(plan.conflicts, isEmpty);
  });

  test('détecte conflit instructions', () async {
    final repo = await _makeRepo();
    final existing = GymExercise(
      name: 'Développé Couché',
      type: GymExerciseType.poidsRepetitions,
      instructions: 'v1',
    );
    await repo.saveExercise(existing);

    final plan = GymImportService(repo).prepare(baseJson);
    expect(plan.conflicts.length, 1);
    expect(plan.conflicts.first.differences, contains('instructions'));
  });

  test('action keepExisting laisse l\'exercice inchangé', () async {
    final repo = await _makeRepo();
    final existing = GymExercise(
      name: 'Développé Couché',
      type: GymExerciseType.poidsRepetitions,
      instructions: 'v1',
    );
    await repo.saveExercise(existing);

    final service = GymImportService(repo);
    final plan = service.prepare(baseJson);
    await service.apply(plan, decisions: {
      existing.id: ImportConflictAction.keepExisting,
    });

    final after = repo.findExerciseById(existing.id)!;
    expect(after.instructions, 'v1');
    expect(repo.loadExercises().length, 1);
  });

  test('action updateExisting met à jour les instructions', () async {
    final repo = await _makeRepo();
    final existing = GymExercise(
      name: 'Développé Couché',
      type: GymExerciseType.poidsRepetitions,
      instructions: 'v1',
    );
    await repo.saveExercise(existing);

    final service = GymImportService(repo);
    final plan = service.prepare(baseJson);
    await service.apply(plan, decisions: {
      existing.id: ImportConflictAction.updateExisting,
    });

    final after = repo.findExerciseById(existing.id)!;
    expect(after.instructions, 'v2');
  });

  test('action createNew crée un nouvel exercice avec nom modifié', () async {
    final repo = await _makeRepo();
    final existing = GymExercise(
      name: 'Développé Couché',
      type: GymExerciseType.poidsRepetitions,
      instructions: 'v1',
    );
    await repo.saveExercise(existing);

    final service = GymImportService(repo);
    final plan = service.prepare(baseJson);
    await service.apply(plan,
        decisions: {existing.id: ImportConflictAction.createNew},
        renameMap: {existing.id: 'DC v2'});

    expect(repo.loadExercises().length, 2);
    expect(
        repo.loadExercises().any((e) => e.name == 'DC v2'), true);
    final unchanged = repo.findExerciseById(existing.id)!;
    expect(unchanged.instructions, 'v1');
  });
}
