import '../../../core/models/gym/gym_exercise.dart';
import '../../../core/models/gym/gym_session.dart';
import '../../../core/models/gym/gym_session_item.dart';
import 'gym_repository.dart';
import 'gym_session_json_codec.dart';

/// Action choisie pour résoudre un conflit d'exercice à l'import.
enum ImportConflictAction {
  /// Garder l'exercice global existant inchangé.
  keepExisting,

  /// Mettre à jour l'exercice global existant avec les nouvelles infos.
  updateExisting,

  /// Créer un nouvel exercice avec un nom modifié.
  createNew,
}

/// Conflit détecté pour un exercice du JSON par rapport à la bibliothèque.
class ImportConflict {
  final ImportedExerciseSpec imported;
  final GymExercise existing;
  final List<String> differences;

  const ImportConflict({
    required this.imported,
    required this.existing,
    required this.differences,
  });
}

/// Plan d'import préparé : à présenter à l'utilisateur, puis exécuter.
class ImportPlan {
  final ImportedSession imported;

  /// Exercices à créer (clé `nom + type` non trouvée).
  final List<ImportedExerciseSpec> toCreate;

  /// Exercices déjà présents et identiques.
  final List<GymExercise> reused;

  /// Exercices déjà présents avec différences.
  final List<ImportConflict> conflicts;

  ImportPlan({
    required this.imported,
    required this.toCreate,
    required this.reused,
    required this.conflicts,
  });

  bool get hasConflicts => conflicts.isNotEmpty;
}

/// Service qui prépare et applique un import JSON.
class GymImportService {
  final GymRepository _repo;
  GymImportService(this._repo);

  /// Analyse un JSON et retourne un plan.
  ImportPlan prepare(String rawJson) {
    final imported = GymSessionJsonCodec.decode(rawJson);
    final exercises = _repo.loadExercises();

    final toCreate = <ImportedExerciseSpec>[];
    final reused = <GymExercise>[];
    final conflicts = <ImportConflict>[];

    for (final item in imported.exerciseItems) {
      final spec = item.exercise;
      final match = _findFunctionalMatch(exercises, spec);
      if (match == null) {
        if (!toCreate.any(
            (e) => e.name == spec.name && e.type == spec.type)) {
          toCreate.add(spec);
        }
        continue;
      }
      final diffs = _diff(spec, match);
      if (diffs.isEmpty) {
        if (!reused.any((e) => e.id == match.id)) reused.add(match);
      } else {
        if (!conflicts.any((c) => c.existing.id == match.id)) {
          conflicts.add(ImportConflict(
              imported: spec, existing: match, differences: diffs));
        }
      }
    }

    return ImportPlan(
      imported: imported,
      toCreate: toCreate,
      reused: reused,
      conflicts: conflicts,
    );
  }

  GymExercise? _findFunctionalMatch(
      List<GymExercise> all, ImportedExerciseSpec spec) {
    for (final e in all) {
      if (e.functionallyEqualsNameType(spec.name, spec.type)) return e;
    }
    return null;
  }

  List<String> _diff(ImportedExerciseSpec spec, GymExercise existing) {
    final diffs = <String>[];
    if (spec.instructions.trim() != existing.instructions.trim()) {
      diffs.add('instructions');
    }
    final specVideoUrl = spec.video?.url;
    final existingVideoUrl = existing.video?.url;
    final specSource = spec.video?.source.id;
    final existingSource = existing.video?.source.id;
    if (specVideoUrl != existingVideoUrl || specSource != existingSource) {
      diffs.add('vidéo');
    }
    return diffs;
  }

  /// Applique le plan : crée les exercices manquants, applique les décisions
  /// de conflit, puis sauvegarde la séance.
  ///
  /// `decisions` : map de `existing.id` → action choisie. Pour `createNew`,
  /// `renameMap[existing.id]` doit fournir un nouveau nom.
  Future<GymSession> apply(
    ImportPlan plan, {
    Map<String, ImportConflictAction> decisions = const {},
    Map<String, String> renameMap = const {},
  }) async {
    final exercises = List<GymExercise>.of(_repo.loadExercises());

    // Crée les exercices manquants
    final createdById = <String, GymExercise>{};
    for (final spec in plan.toCreate) {
      final created = GymExercise(
        name: spec.name,
        type: spec.type,
        instructions: spec.instructions,
        video: spec.video,
      );
      exercises.add(created);
      createdById['${spec.name}|${spec.type.id}'] = created;
    }

    // Applique les décisions de conflit
    final resolvedById = <String, GymExercise>{};
    for (final c in plan.conflicts) {
      final action = decisions[c.existing.id] ?? ImportConflictAction.keepExisting;
      switch (action) {
        case ImportConflictAction.keepExisting:
          resolvedById[c.existing.id] = c.existing;
          break;
        case ImportConflictAction.updateExisting:
          final updated = c.existing.copyWith(
            instructions: c.imported.instructions,
            video: c.imported.video,
            clearVideo: c.imported.video == null,
          );
          final idx =
              exercises.indexWhere((e) => e.id == c.existing.id);
          if (idx >= 0) exercises[idx] = updated;
          resolvedById[c.existing.id] = updated;
          break;
        case ImportConflictAction.createNew:
          final newName = renameMap[c.existing.id] ??
              '${c.imported.name} (importé)';
          final created = GymExercise(
            name: newName,
            type: c.imported.type,
            instructions: c.imported.instructions,
            video: c.imported.video,
          );
          exercises.add(created);
          resolvedById[c.existing.id] = created;
          break;
      }
    }

    await _repo.saveExercises(exercises);

    // Construit les items de séance
    final items = <GymSessionItem>[];
    for (final raw in plan.imported.items) {
      if (raw is ImportedItemRest) {
        items.add(GymSessionRestItem(durationSeconds: raw.durationSeconds));
        continue;
      }
      if (raw is ImportedItemExercise) {
        final spec = raw.exercise;
        // Détermine l'exercice cible
        GymExercise? target;
        // 1) un conflit résolu ?
        for (final c in plan.conflicts) {
          if (c.imported.name == spec.name && c.imported.type == spec.type) {
            target = resolvedById[c.existing.id];
            break;
          }
        }
        // 2) un exercice créé pour ce spec ?
        target ??= createdById['${spec.name}|${spec.type.id}'];
        // 3) un exercice existant déjà identique ?
        if (target == null) {
          for (final e in plan.reused) {
            if (e.functionallyEqualsNameType(spec.name, spec.type)) {
              target = e;
              break;
            }
          }
        }
        if (target == null) {
          // dernier recours : recherche dans la liste finale
          for (final e in exercises) {
            if (e.functionallyEqualsNameType(spec.name, spec.type)) {
              target = e;
              break;
            }
          }
        }
        if (target == null) {
          throw GymImportException(
              'Exercice cible introuvable pour « ${spec.name} »');
        }
        items.add(GymSessionExerciseItem(
          exerciseId: target.id,
          timedSetStartMode: raw.timedSetStartMode,
          sets: raw.sets.map((s) => s.copyWith()).toList(),
        ));
      }
    }

    final session = GymSession(
      name: plan.imported.name,
      description: plan.imported.description,
      items: items,
    );
    await _repo.saveSession(session);
    return session;
  }
}

