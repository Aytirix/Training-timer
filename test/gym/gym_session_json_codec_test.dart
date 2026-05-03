import 'package:flutter_test/flutter_test.dart';
import 'package:traction_timer/core/models/gym/exercise_video.dart';
import 'package:traction_timer/core/models/gym/gym_exercise.dart';
import 'package:traction_timer/core/models/gym/gym_session.dart';
import 'package:traction_timer/core/models/gym/gym_session_item.dart';
import 'package:traction_timer/core/models/gym/gym_set.dart';
import 'package:traction_timer/features/gym/data/gym_session_json_codec.dart';

const validJson = '''
{
  "version": 1,
  "session": {
    "name": "Force",
    "description": "test",
    "items": [
      {
        "kind": "exercise",
        "exercise": {
          "name": "Développé couché",
          "type": "poids_repetitions",
          "instructions": "ok"
        },
        "timedSetStartMode": null,
        "sets": [
          {"weightKg": 60, "repetitions": 10, "restAfterSetSeconds": 90},
          {"weightKg": 65, "repetitions": 8, "restAfterSetSeconds": null}
        ]
      },
      {"kind": "rest", "durationSeconds": 120},
      {
        "kind": "exercise",
        "exercise": {
          "name": "Gainage leste",
          "type": "poids_duree",
          "instructions": "tendu"
        },
        "timedSetStartMode": "manual",
        "sets": [
          {"weightKg": 10, "durationSeconds": 45, "restAfterSetSeconds": null}
        ]
      }
    ]
  }
}
''';

void main() {
  group('GymSessionJsonCodec.decode', () {
    test('JSON valide', () {
      final imported = GymSessionJsonCodec.decode(validJson);
      expect(imported.name, 'Force');
      expect(imported.exerciseItems.length, 2);
      expect(imported.items.whereType<ImportedItemRest>().length, 1);
    });

    test('bloque sans version', () {
      expect(
          () =>
              GymSessionJsonCodec.decode('{"session":{"name":"X","items":[]}}'),
          throwsA(isA<GymImportException>()));
    });

    test('bloque sans nom', () {
      expect(() => GymSessionJsonCodec.decode('{"version":1,"session":{}}'),
          throwsA(isA<GymImportException>()));
    });

    test('bloque sans items', () {
      expect(
          () => GymSessionJsonCodec.decode(
              '{"version":1,"session":{"name":"X"}}'),
          throwsA(isA<GymImportException>()));
    });

    test('bloque type inconnu', () {
      const j = '''
{
  "version":1,
  "session":{"name":"X","items":[
    {"kind":"exercise","exercise":{"name":"y","type":"foo"},"sets":[]}
  ]}
}
''';
      expect(() => GymSessionJsonCodec.decode(j),
          throwsA(isA<GymImportException>()));
    });

    test('bloque série incomplète', () {
      const j = '''
{
  "version":1,
  "session":{"name":"X","items":[
    {"kind":"exercise","exercise":{"name":"y","type":"poids_repetitions"},"sets":[{}]}
  ]}
}
''';
      expect(() => GymSessionJsonCodec.decode(j),
          throwsA(isA<GymImportException>()));
    });

    test('ignore champs inconnus', () {
      const j = '''
{
  "version":1,
  "extra":"ignored",
  "session":{
    "name":"X",
    "foo":"bar",
    "items":[
      {"kind":"exercise","exercise":{"name":"y","type":"repetitions","unknown":1},
       "sets":[{"repetitions":8,"unknown":1}]}
    ]
  }
}
''';
      final imported = GymSessionJsonCodec.decode(j);
      expect(imported.exerciseItems.length, 1);
    });
  });

  group('GymSessionJsonCodec.encode', () {
    test('export sans IDs internes', () {
      final ex = GymExercise(
        name: 'Squat',
        type: GymExerciseType.poidsRepetitions,
        instructions: 'instr',
        video: const ExerciseVideo(
            source: ExerciseVideoSource.directUrl, url: 'https://x/y.mp4'),
      );
      final session = GymSession(name: 'A', items: [
        GymSessionExerciseItem(
            exerciseId: ex.id,
            sets: const [GymSet(weightKg: 60, repetitions: 10)]),
      ]);
      final json = GymSessionJsonCodec.encode(session, [ex]);
      expect(json.contains(ex.id), false, reason: 'pas d\'ID interne');
      expect(json.contains('"version": 1'), true);
      expect(json.contains('Squat'), true);
    });

    test('export puis reimport conserve les séries', () {
      final ex =
          GymExercise(name: 'Squat', type: GymExerciseType.poidsRepetitions);
      final session = GymSession(name: 'A', items: [
        GymSessionExerciseItem(exerciseId: ex.id, sets: const [
          GymSet(weightKg: 60, repetitions: 10, restAfterSetSeconds: 90),
          GymSet(weightKg: 65, repetitions: 8),
        ]),
        GymSessionRestItem(durationSeconds: 60),
      ]);
      final json = GymSessionJsonCodec.encode(session, [ex]);
      // décode => 0 exercice attendu si rest seul ? non, on a un exercice
      final decoded = GymSessionJsonCodec.decode(json);
      expect(decoded.exerciseItems.length, 1);
      expect(decoded.exerciseItems.first.sets.length, 2);
      expect(decoded.exerciseItems.first.sets.first.weightKg, 60);
    });

    test('export vidéo locale sans chemin interne', () {
      final ex = GymExercise(
        name: 'Tractions',
        type: GymExerciseType.repetitions,
        video: const ExerciseVideo(
          source: ExerciseVideoSource.localFile,
          localPath: '/private/app/videos/traction.mp4',
          originalFileName: 'traction.mp4',
        ),
      );
      final session = GymSession(name: 'A', items: [
        GymSessionExerciseItem(
            exerciseId: ex.id, sets: const [GymSet(repetitions: 10)]),
      ]);

      final json = GymSessionJsonCodec.encode(session, [ex]);

      expect(json.contains('/private/app/videos/traction.mp4'), false);
      expect(json.contains('localPath'), false);
      expect(json.contains('"source": "localFile"'), true);
    });
  });
}
