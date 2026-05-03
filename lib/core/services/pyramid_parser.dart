import '../models/workout_block.dart';
import '../models/rest_strategy.dart';

/// Résultat du parsing d'une saisie rapide.
class ParseResult {
  final List<WorkoutBlock> blocks;
  final List<String> errors;

  const ParseResult({required this.blocks, this.errors = const []});

  bool get hasErrors => errors.isNotEmpty;
  bool get isValid => blocks.isNotEmpty && errors.isEmpty;

  int get totalReps => blocks.fold(0, (s, b) => s + b.totalReps);
  int get totalSets => blocks.fold(0, (s, b) => s + b.totalSets);
}

/// Parser de saisie rapide de séances.
///
/// Format supporté (une ligne = un bloc) :
///   1-2-3-4-3-2-1 x3
///   2-4-6-8-6-4-2
///   2-3-5-3-2 x2
///
/// Règles :
/// - Séquence : entiers séparés par des tirets
/// - Répétition optionnelle : xN ou x N (insensible à la casse)
/// - Lignes vides et commentaires (#) ignorés
class PyramidParser {
  static const _restStrategy = RestStrategy();

  /// Parse un texte multi-lignes et retourne un [ParseResult].
  static ParseResult parse(String input) {
    final blocks = <WorkoutBlock>[];
    final errors = <String>[];
    final lines = input.split('\n');

    for (int i = 0; i < lines.length; i++) {
      final lineNumber = i + 1;
      final raw = lines[i].trim();

      // Ignore lignes vides et commentaires
      if (raw.isEmpty || raw.startsWith('#')) continue;

      final result = _parseLine(raw, lineNumber);
      if (result.error != null) {
        errors.add(result.error!);
      } else if (result.block != null) {
        blocks.add(result.block!);
      }
    }

    return ParseResult(blocks: blocks, errors: errors);
  }

  /// Parse une seule ligne et retourne un bloc ou une erreur.
  static _LineResult _parseLine(String line, int lineNumber) {
    // Sépare séquence et répétitions
    // Pattern : "1-2-3-4-3-2-1 x3" ou "2-4-6-8-6-4-2"
    final repeatMatch = RegExp(r'[xX]\s*(\d+)', caseSensitive: false).firstMatch(line);
    int repeatCount = 1;
    String sequencePart = line;

    if (repeatMatch != null) {
      final repeatStr = repeatMatch.group(1);
      repeatCount = int.tryParse(repeatStr ?? '') ?? 1;
      if (repeatCount < 1 || repeatCount > 20) {
        return _LineResult.error(
          'Ligne $lineNumber : nombre de répétitions invalide ($repeatCount). Doit être entre 1 et 20.',
        );
      }
      sequencePart = line.substring(0, repeatMatch.start).trim();
    }

    // Parse la séquence
    final parts = sequencePart
        .split('-')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    if (parts.isEmpty) {
      return _LineResult.error('Ligne $lineNumber : séquence vide.');
    }

    final sequence = <int>[];
    for (final part in parts) {
      final n = int.tryParse(part);
      if (n == null) {
        return _LineResult.error(
          'Ligne $lineNumber : "$part" n\'est pas un entier valide.',
        );
      }
      if (n < 1 || n > 100) {
        return _LineResult.error(
          'Ligne $lineNumber : valeur $n hors plage (1–100).',
        );
      }
      sequence.add(n);
    }

    if (sequence.isEmpty) {
      return _LineResult.error('Ligne $lineNumber : séquence trop courte.');
    }

    // Détermine le type de bloc
    final type = _detectType(sequence);

    // Génère un nom automatique
    final name = _generateName(sequence, repeatCount, type);

    final block = WorkoutBlock(
      name: name,
      type: type,
      sequence: sequence,
      repeatCount: repeatCount,
      restStrategy: _restStrategy,
    );

    return _LineResult.block(block);
  }

  /// Détecte si la séquence est une pyramide montante, descendante ou mixte.
  static BlockType _detectType(List<int> seq) {
    if (seq.length < 3) return BlockType.sequence;

    bool hasPeak = false;
    bool isSymmetric = true;

    // Vérifie la symétrie (pyramide complète)
    for (int i = 0; i < seq.length ~/ 2; i++) {
      if (seq[i] != seq[seq.length - 1 - i]) {
        isSymmetric = false;
        break;
      }
    }

    // Vérifie s'il y a un pic
    final maxVal = seq.reduce((a, b) => a > b ? a : b);
    final maxIdx = seq.indexOf(maxVal);
    if (maxIdx > 0 && maxIdx < seq.length - 1) hasPeak = true;

    if (hasPeak && isSymmetric) return BlockType.pyramid;
    if (hasPeak) return BlockType.custom;
    return BlockType.sequence;
  }

  /// Génère un nom descriptif pour le bloc.
  static String _generateName(List<int> seq, int repeatCount, BlockType type) {
    final seqStr = seq.join('-');
    final suffix = repeatCount > 1 ? ' x$repeatCount' : '';
    return '$seqStr$suffix';
  }

  /// Parse une ligne unique (utile pour la validation en temps réel).
  static ParseResult parseSingleLine(String line) {
    return parse(line);
  }

  /// Formate une liste de blocs en texte (pour re-édition).
  static String blocksToText(List<WorkoutBlock> blocks) {
    return blocks.map((b) {
      final seq = b.sequence.join('-');
      if (b.repeatCount > 1) return '$seq x${b.repeatCount}';
      return seq;
    }).join('\n');
  }
}

class _LineResult {
  final WorkoutBlock? block;
  final String? error;

  const _LineResult._({this.block, this.error});

  factory _LineResult.block(WorkoutBlock b) => _LineResult._(block: b);
  factory _LineResult.error(String msg) => _LineResult._(error: msg);
}
