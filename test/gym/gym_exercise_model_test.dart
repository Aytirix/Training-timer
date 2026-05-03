import 'package:flutter_test/flutter_test.dart';
import 'package:traction_timer/core/models/gym/gym_exercise.dart';
import 'package:traction_timer/core/models/gym/exercise_video.dart';

void main() {
  group('GymExerciseType', () {
    test('parse les ids', () {
      expect(GymExerciseType.fromId('poids_repetitions'),
          GymExerciseType.poidsRepetitions);
      expect(
          GymExerciseType.fromId('repetitions'), GymExerciseType.repetitions);
      expect(GymExerciseType.fromId('duree'), GymExerciseType.duree);
      expect(GymExerciseType.fromId('poids_duree'), GymExerciseType.poidsDuree);
      expect(GymExerciseType.fromId('inconnu'), null);
      expect(GymExerciseType.fromId(null), null);
    });

    test('drapeaux par type', () {
      expect(GymExerciseType.poidsRepetitions.hasWeight, true);
      expect(GymExerciseType.poidsRepetitions.hasReps, true);
      expect(GymExerciseType.poidsRepetitions.hasDuration, false);

      expect(GymExerciseType.repetitions.hasWeight, false);
      expect(GymExerciseType.repetitions.hasReps, true);

      expect(GymExerciseType.duree.hasDuration, true);
      expect(GymExerciseType.duree.hasWeight, false);

      expect(GymExerciseType.poidsDuree.hasWeight, true);
      expect(GymExerciseType.poidsDuree.hasDuration, true);
    });
  });

  group('GymExercise', () {
    test('égalité fonctionnelle nom + type avec accents/espaces', () {
      final a = GymExercise(
          name: 'Développé Couché', type: GymExerciseType.poidsRepetitions);
      final b = GymExercise(
          name: 'developpe   couche', type: GymExerciseType.poidsRepetitions);
      expect(a.functionallyEquals(b), true);
    });

    test('même nom mais type différent => non égaux', () {
      final a = GymExercise(
          name: 'Gainage', type: GymExerciseType.duree);
      final b = GymExercise(
          name: 'Gainage', type: GymExerciseType.poidsDuree);
      expect(a.functionallyEquals(b), false);
    });

    test('serialization JSON aller-retour', () {
      final ex = GymExercise(
        name: 'Développé Couché',
        type: GymExerciseType.poidsRepetitions,
        instructions: 'Garder les omoplates serrées.',
        video: const ExerciseVideo(
            source: ExerciseVideoSource.directUrl,
            url: 'https://example.com/dc.mp4'),
      );
      final round = GymExercise.fromJson(ex.toJson());
      expect(round.id, ex.id);
      expect(round.name, ex.name);
      expect(round.type, ex.type);
      expect(round.instructions, ex.instructions);
      expect(round.video?.url, ex.video?.url);
      expect(round.video?.source, ex.video?.source);
    });

    test('JSON refuse un type inconnu', () {
      expect(
          () => GymExercise.fromJson(
              {'name': 'X', 'type': 'foo', 'instructions': ''}),
          throwsFormatException);
    });
  });
}
