import 'package:flutter_test/flutter_test.dart';
import 'package:traction_timer/core/services/pyramid_parser.dart';
import 'package:traction_timer/core/models/workout_block.dart';

void main() {
  group('PyramidParser', () {
    test('parse séquence simple', () {
      final result = PyramidParser.parse('2-4-6-8-6-4-2');
      expect(result.isValid, isTrue);
      expect(result.blocks.length, 1);
      expect(result.blocks.first.sequence, [2, 4, 6, 8, 6, 4, 2]);
      expect(result.blocks.first.repeatCount, 1);
      expect(result.blocks.first.type, BlockType.pyramid);
    });

    test('parse pyramide répétée', () {
      final result = PyramidParser.parse('1-2-3-4-3-2-1 x3');
      expect(result.isValid, isTrue);
      expect(result.blocks.first.repeatCount, 3);
      expect(result.blocks.first.totalReps, 16 * 3); // 1+2+3+4+3+2+1 = 16, x3 = 48
    });

    test('parse multi-blocs (séance 110 reps)', () {
      const input = '1-2-3-4-3-2-1 x3\n2-4-6-8-6-4-2\n2-3-5-3-2 x2';
      final result = PyramidParser.parse(input);
      expect(result.isValid, isTrue);
      expect(result.blocks.length, 3);
      expect(result.totalReps, 110);
    });

    test('ignore lignes vides et commentaires', () {
      const input = '''
# Mon entraînement

1-2-3-4-3-2-1 x3

# Bloc 2
2-4-6-8-6-4-2
''';
      final result = PyramidParser.parse(input);
      expect(result.blocks.length, 2);
    });

    test('erreur sur valeur invalide', () {
      final result = PyramidParser.parse('1-2-abc-4');
      expect(result.hasErrors, isTrue);
    });

    test('erreur sur répétition invalide', () {
      final result = PyramidParser.parse('1-2-3 x0');
      expect(result.hasErrors, isTrue);
    });

    test('blocksToText est l\'inverse de parse', () {
      const input = '1-2-3-4-3-2-1 x3\n2-4-6-8-6-4-2\n2-3-5-3-2 x2';
      final result = PyramidParser.parse(input);
      final text = PyramidParser.blocksToText(result.blocks);
      final result2 = PyramidParser.parse(text);
      expect(result2.totalReps, result.totalReps);
    });

    test('séquence non-pyramide détectée comme sequence', () {
      final result = PyramidParser.parse('5-5-5-5');
      expect(result.blocks.first.type, BlockType.sequence);
    });
  });
}
