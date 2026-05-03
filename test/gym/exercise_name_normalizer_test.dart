import 'package:flutter_test/flutter_test.dart';
import 'package:traction_timer/core/services/exercise_name_normalizer.dart';

void main() {
  group('ExerciseNameNormalizer', () {
    test('lowercase', () {
      expect(ExerciseNameNormalizer.normalize('Developpe Couche'),
          'developpe couche');
    });

    test('retire les accents', () {
      expect(ExerciseNameNormalizer.normalize('développé couché'),
          'developpe couche');
    });

    test('réduit les espaces multiples', () {
      expect(ExerciseNameNormalizer.normalize('developpe   couche'),
          'developpe couche');
    });

    test('trim', () {
      expect(ExerciseNameNormalizer.normalize('  développé couché  '),
          'developpe couche');
    });

    test('mêmes noms équivalents', () {
      final a = ExerciseNameNormalizer.normalize('Développé   Couché');
      final b = ExerciseNameNormalizer.normalize('developpe couche');
      expect(a, b);
    });

    test('caractères spéciaux conservés', () {
      expect(ExerciseNameNormalizer.normalize("Tractions L'épée"),
          "tractions l'epee");
    });

    test('œ et æ développés', () {
      expect(ExerciseNameNormalizer.normalize('Cœur Æther'), 'coeur aether');
    });
  });
}
