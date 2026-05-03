import '../../../core/models/gym/gym_exercise.dart';
import '../../../core/models/gym/gym_session.dart';
import '../../../core/models/gym/gym_session_item.dart';
import '../../../core/storage/local_storage.dart';

/// Résultat d'une suppression d'exercice global.
class DeleteExerciseResult {
  /// Séances qui contenaient l'exercice (avant suppression).
  final List<GymSession> impactedSessions;

  /// Séances après nettoyage (les exercices retirés).
  final List<GymSession> cleanedSessions;

  const DeleteExerciseResult({
    required this.impactedSessions,
    required this.cleanedSessions,
  });
}

/// Accès atomique au stockage des exercices et séances de salle.
///
/// Lecture/écriture passent toujours par le storage : pas de cache local pour
/// éviter les divergences. Le provider Riverpod garde l'état en mémoire.
class GymRepository {
  final LocalStorage _storage;

  GymRepository(this._storage);

  // ───────── Exercices ─────────

  List<GymExercise> loadExercises() => _storage.loadGymExercises();

  Future<void> saveExercise(GymExercise exercise) async {
    final all = loadExercises();
    final idx = all.indexWhere((e) => e.id == exercise.id);
    if (idx >= 0) {
      all[idx] = exercise;
    } else {
      all.add(exercise);
    }
    await _storage.saveGymExercises(all);
  }

  Future<void> saveExercises(List<GymExercise> exercises) async {
    await _storage.saveGymExercises(exercises);
  }

  GymExercise? findExerciseById(String id) {
    try {
      return loadExercises().firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Trouve un exercice fonctionnellement équivalent (nom normalisé + type).
  GymExercise? findFunctionalMatch(String name, GymExerciseType type) {
    for (final e in loadExercises()) {
      if (e.functionallyEqualsNameType(name, type)) return e;
    }
    return null;
  }

  /// Vrai si un autre exercice (id différent) partage déjà la même clé fonctionnelle.
  bool hasDuplicateFunctionalKey(GymExercise exercise) {
    for (final e in loadExercises()) {
      if (e.id == exercise.id) continue;
      if (e.functionallyEquals(exercise)) return true;
    }
    return false;
  }

  /// Retourne les séances qui utilisent l'exercice donné.
  List<GymSession> findSessionsUsingExercise(String exerciseId) {
    return _storage
        .loadGymSessions()
        .where((s) => s.referencedExerciseIds.contains(exerciseId))
        .toList();
  }

  /// Supprime l'exercice et nettoie les séances qui l'utilisent.
  ///
  /// Si une séance devient vide après nettoyage, elle reste sauvegardée.
  /// Elle sera bloquée au lancement par la validation.
  Future<DeleteExerciseResult> deleteExercise(String exerciseId) async {
    final allExercises = loadExercises();
    final allSessions = _storage.loadGymSessions();

    final impacted = allSessions
        .where((s) => s.referencedExerciseIds.contains(exerciseId))
        .toList();

    final cleanedSessions = allSessions.map((session) {
      if (!session.referencedExerciseIds.contains(exerciseId)) return session;
      final newItems = <GymSessionItem>[];
      var skipNextRest = false;
      for (final item in session.items) {
        if (skipNextRest && item is GymSessionRestItem) {
          skipNextRest = false;
          continue;
        }
        skipNextRest = false;
        if (item is GymSessionExerciseItem && item.exerciseId == exerciseId) {
          // Le repos entre exercices suit l'exercice précédent. Si on supprime
          // cet exercice, le repos qui le suit doit disparaître aussi.
          skipNextRest = true;
          continue;
        }
        newItems.add(item);
      }
      return session.copyWith(
          items: _normalizeSessionItems(newItems), updatedAt: DateTime.now());
    }).toList();

    final newExercises = allExercises.where((e) => e.id != exerciseId).toList();
    await _storage.saveGymExercises(newExercises);
    await _storage.saveGymSessions(cleanedSessions);

    return DeleteExerciseResult(
      impactedSessions: impacted,
      cleanedSessions: cleanedSessions,
    );
  }

  // ───────── Séances ─────────

  List<GymSession> loadSessions() => _storage.loadGymSessions();

  Future<void> saveSession(GymSession session) async {
    final all = loadSessions();
    final idx = all.indexWhere((s) => s.id == session.id);
    if (idx >= 0) {
      all[idx] = session;
    } else {
      all.add(session);
    }
    await _storage.saveGymSessions(all);
  }

  Future<void> saveSessions(List<GymSession> sessions) async {
    await _storage.saveGymSessions(sessions);
  }

  Future<void> deleteSession(String id) async {
    final all = loadSessions().where((s) => s.id != id).toList();
    await _storage.saveGymSessions(all);
  }

  GymSession? findSessionById(String id) {
    try {
      return loadSessions().firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  List<GymSessionItem> _normalizeSessionItems(List<GymSessionItem> items) {
    final cleaned = <GymSessionItem>[];
    for (final item in items) {
      if (item is GymSessionRestItem) {
        if (cleaned.isEmpty || cleaned.last is GymSessionRestItem) {
          continue;
        }
      }
      cleaned.add(item);
    }
    while (cleaned.isNotEmpty && cleaned.last is GymSessionRestItem) {
      cleaned.removeLast();
    }
    return cleaned;
  }
}
