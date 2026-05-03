import 'dart:convert';

import '../../../core/models/gym/exercise_video.dart';
import '../../../core/models/gym/gym_exercise.dart';
import '../../../core/models/gym/gym_session.dart';
import '../../../core/models/gym/gym_session_item.dart';
import '../../../core/models/gym/gym_set.dart';

/// Erreur d'import JSON.
class GymImportException implements Exception {
  final String message;
  final List<String> details;
  GymImportException(this.message, [this.details = const []]);

  @override
  String toString() {
    if (details.isEmpty) return message;
    return '$message\n- ${details.join('\n- ')}';
  }
}

/// Snapshot exercice tel que décrit dans un JSON portable.
class ImportedExerciseSpec {
  final String name;
  final GymExerciseType type;
  final String instructions;
  final ExerciseVideo? video;

  const ImportedExerciseSpec({
    required this.name,
    required this.type,
    required this.instructions,
    this.video,
  });
}

class ImportedItemExercise {
  final ImportedExerciseSpec exercise;
  final TimedSetStartMode? timedSetStartMode;
  final List<GymSet> sets;

  const ImportedItemExercise({
    required this.exercise,
    required this.sets,
    this.timedSetStartMode,
  });
}

class ImportedItemRest {
  final int durationSeconds;
  const ImportedItemRest(this.durationSeconds);
}

/// Résultat décodé : pas encore appliqué au stockage.
class ImportedSession {
  final String name;
  final String description;
  final List<Object> items; // ImportedItemExercise | ImportedItemRest

  const ImportedSession({
    required this.name,
    required this.description,
    required this.items,
  });

  List<ImportedItemExercise> get exerciseItems =>
      items.whereType<ImportedItemExercise>().toList();
}

/// Encode/décode une séance en JSON portable (sans IDs internes).
class GymSessionJsonCodec {
  static const int version = 1;

  // ────────────── Encode ──────────────

  static String encode(GymSession session, List<GymExercise> referenced) {
    final byId = {for (final e in referenced) e.id: e};
    final items = session.items.map<Map<String, dynamic>>((it) {
      if (it is GymSessionRestItem) {
        return {
          'kind': 'rest',
          'durationSeconds': it.durationSeconds,
        };
      }
      if (it is GymSessionExerciseItem) {
        final ex = byId[it.exerciseId];
        return {
          'kind': 'exercise',
          'exercise': {
            'name': ex?.name ?? '',
            'type': ex?.type.id ?? '',
            'instructions': ex?.instructions ?? '',
            if (ex?.video != null) 'video': ex!.video!.toPortableJson(),
          },
          'timedSetStartMode': it.timedSetStartMode?.id,
          'sets': it.sets
              .map((s) => {
                    if (s.weightKg != null) 'weightKg': s.weightKg,
                    if (s.repetitions != null) 'repetitions': s.repetitions,
                    if (s.durationSeconds != null)
                      'durationSeconds': s.durationSeconds,
                    'restAfterSetSeconds': s.restAfterSetSeconds,
                  })
              .toList(),
        };
      }
      return {};
    }).toList();

    final root = {
      'version': version,
      'session': {
        'name': session.name,
        'description': session.description,
        'items': items,
      },
    };

    return const JsonEncoder.withIndent('  ').convert(root);
  }

  // ────────────── Decode ──────────────

  static ImportedSession decode(String raw) {
    final dynamic parsed;
    try {
      parsed = jsonDecode(raw);
    } catch (e) {
      throw GymImportException('JSON invalide : $e');
    }
    if (parsed is! Map<String, dynamic>) {
      throw GymImportException('La racine doit être un objet JSON.');
    }
    if (parsed['version'] == null) {
      throw GymImportException('Champ obligatoire manquant : version');
    }
    final session = parsed['session'];
    if (session is! Map<String, dynamic>) {
      throw GymImportException('Champ obligatoire manquant : session');
    }
    final name = session['name'];
    if (name is! String || name.trim().isEmpty) {
      throw GymImportException('Champ obligatoire manquant : session.name');
    }
    final description = session['description'] as String? ?? '';
    final itemsRaw = session['items'];
    if (itemsRaw is! List || itemsRaw.isEmpty) {
      throw GymImportException(
          'La séance doit contenir au moins un item dans session.items.');
    }

    final errors = <String>[];
    final items = <Object>[];
    var hasExercise = false;

    for (var i = 0; i < itemsRaw.length; i++) {
      final raw = itemsRaw[i];
      if (raw is! Map<String, dynamic>) {
        errors.add('items[$i] : doit être un objet');
        continue;
      }
      final kind = raw['kind'];
      if (kind == 'rest') {
        final d = raw['durationSeconds'];
        if (d is! int || d < 0) {
          errors.add('items[$i] : durationSeconds invalide');
          continue;
        }
        items.add(ImportedItemRest(d));
      } else if (kind == 'exercise') {
        try {
          final parsed = _decodeExerciseItem(raw, i);
          items.add(parsed);
          hasExercise = true;
        } on GymImportException catch (e) {
          errors.add(e.message);
        }
      } else {
        errors.add('items[$i] : kind inconnu (« $kind »)');
      }
    }

    if (!hasExercise) {
      errors.add('La séance doit contenir au moins un exercice.');
    }
    if (errors.isNotEmpty) {
      throw GymImportException('Erreurs de validation', errors);
    }

    return ImportedSession(
      name: name.trim(),
      description: description,
      items: items,
    );
  }

  static ImportedItemExercise _decodeExerciseItem(
      Map<String, dynamic> raw, int index) {
    final ex = raw['exercise'];
    if (ex is! Map<String, dynamic>) {
      throw GymImportException(
          'items[$index].exercise manquant ou invalide.');
    }
    final exName = ex['name'];
    if (exName is! String || exName.trim().isEmpty) {
      throw GymImportException(
          'items[$index].exercise.name obligatoire.');
    }
    final typeId = ex['type'];
    final type = GymExerciseType.fromId(typeId is String ? typeId : null);
    if (type == null) {
      throw GymImportException(
          'items[$index].exercise.type invalide (« $typeId »).');
    }
    final instructions = ex['instructions'] as String? ?? '';
    ExerciseVideo? video;
    final videoRaw = ex['video'];
    if (videoRaw is Map<String, dynamic>) {
      video = ExerciseVideo.fromPortableJson(videoRaw);
    }
    final spec = ImportedExerciseSpec(
      name: exName.trim(),
      type: type,
      instructions: instructions,
      video: video,
    );
    final mode = TimedSetStartMode.fromId(
        raw['timedSetStartMode'] as String?,
        fallback: type.hasDuration ? TimedSetStartMode.manual : null);
    final timedMode = type.hasDuration ? mode : null;

    final setsRaw = raw['sets'];
    if (setsRaw is! List || setsRaw.isEmpty) {
      throw GymImportException(
          'items[$index].sets : au moins une série requise.');
    }
    final sets = <GymSet>[];
    for (var s = 0; s < setsRaw.length; s++) {
      final raw = setsRaw[s];
      if (raw is! Map<String, dynamic>) {
        throw GymImportException(
            'items[$index].sets[$s] : doit être un objet.');
      }
      final isLast = s == setsRaw.length - 1;
      final set = GymSet(
        weightKg: (raw['weightKg'] as num?)?.toDouble(),
        repetitions: raw['repetitions'] as int?,
        durationSeconds: raw['durationSeconds'] as int?,
        restAfterSetSeconds: raw['restAfterSetSeconds'] as int?,
      );
      final errors = set.validate(type, isLast: isLast);
      if (errors.isNotEmpty) {
        throw GymImportException(
            'items[$index].sets[$s] : ${errors.first.message}');
      }
      sets.add(set);
    }

    return ImportedItemExercise(
      exercise: spec,
      sets: sets,
      timedSetStartMode: timedMode,
    );
  }
}
