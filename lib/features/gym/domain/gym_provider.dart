import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/gym/gym_exercise.dart';
import '../../../core/models/gym/gym_session.dart';
import '../../workouts/domain/workout_provider.dart';
import '../data/gym_repository.dart';

final gymRepositoryProvider = Provider<GymRepository>((ref) {
  final storage = ref.watch(localStorageProvider);
  return GymRepository(storage);
});

// ───────── Exercices ─────────

class GymExercisesState {
  final List<GymExercise> exercises;
  final bool isLoading;
  final String? error;

  const GymExercisesState({
    this.exercises = const [],
    this.isLoading = false,
    this.error,
  });

  GymExercisesState copyWith({
    List<GymExercise>? exercises,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) =>
      GymExercisesState(
        exercises: exercises ?? this.exercises,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : (error ?? this.error),
      );
}

class GymExercisesNotifier extends StateNotifier<GymExercisesState> {
  final GymRepository _repo;

  GymExercisesNotifier(this._repo) : super(const GymExercisesState()) {
    _load();
  }

  void _load() {
    state = state.copyWith(isLoading: true);
    final exercises = _repo.loadExercises();
    state = state.copyWith(exercises: exercises, isLoading: false);
  }

  /// Crée ou met à jour un exercice.
  ///
  /// Lève [DuplicateExerciseException] si la clé `nom + type` est déjà prise
  /// par un autre exercice.
  Future<void> save(GymExercise exercise) async {
    if (_repo.hasDuplicateFunctionalKey(exercise)) {
      throw DuplicateExerciseException(exercise.name, exercise.type);
    }
    await _repo.saveExercise(exercise);
    state = state.copyWith(exercises: _repo.loadExercises(), clearError: true);
  }

  Future<DeleteExerciseResult> delete(String id) async {
    final result = await _repo.deleteExercise(id);
    state = state.copyWith(exercises: _repo.loadExercises(), clearError: true);
    return result;
  }

  List<GymSession> findSessionsUsing(String exerciseId) =>
      _repo.findSessionsUsingExercise(exerciseId);

  GymExercise? findById(String id) => _repo.findExerciseById(id);

  GymExercise? findFunctionalMatch(String name, GymExerciseType type) =>
      _repo.findFunctionalMatch(name, type);

  /// Recharge la liste depuis le stockage (utile après un import par exemple).
  void refresh() {
    state = state.copyWith(exercises: _repo.loadExercises());
  }
}

class DuplicateExerciseException implements Exception {
  final String name;
  final GymExerciseType type;
  DuplicateExerciseException(this.name, this.type);
  @override
  String toString() =>
      'Un exercice « $name » existe déjà avec ce type (${type.label}).';
}

final gymExercisesProvider =
    StateNotifierProvider<GymExercisesNotifier, GymExercisesState>((ref) {
  final repo = ref.watch(gymRepositoryProvider);
  return GymExercisesNotifier(repo);
});

// ───────── Séances ─────────

class GymSessionsState {
  final List<GymSession> sessions;
  final bool isLoading;
  final String? error;

  const GymSessionsState({
    this.sessions = const [],
    this.isLoading = false,
    this.error,
  });

  GymSessionsState copyWith({
    List<GymSession>? sessions,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) =>
      GymSessionsState(
        sessions: sessions ?? this.sessions,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : (error ?? this.error),
      );
}

class GymSessionsNotifier extends StateNotifier<GymSessionsState> {
  final GymRepository _repo;

  GymSessionsNotifier(this._repo) : super(const GymSessionsState()) {
    _load();
  }

  void _load() {
    state = state.copyWith(isLoading: true);
    final sessions = _repo.loadSessions();
    state = state.copyWith(sessions: sessions, isLoading: false);
  }

  Future<void> save(GymSession session) async {
    await _repo.saveSession(session);
    state = state.copyWith(sessions: _repo.loadSessions(), clearError: true);
  }

  Future<void> delete(String id) async {
    await _repo.deleteSession(id);
    state = state.copyWith(sessions: _repo.loadSessions(), clearError: true);
  }

  Future<void> duplicate(GymSession session) async {
    await _repo.saveSession(session.duplicate());
    state = state.copyWith(sessions: _repo.loadSessions(), clearError: true);
  }

  /// Force le rafraîchissement (après une suppression d'exercice qui a nettoyé
  /// des séances par exemple).
  void refresh() {
    state = state.copyWith(sessions: _repo.loadSessions());
  }

  GymSession? findById(String id) => _repo.findSessionById(id);
}

final gymSessionsProvider =
    StateNotifierProvider<GymSessionsNotifier, GymSessionsState>((ref) {
  final repo = ref.watch(gymRepositoryProvider);
  return GymSessionsNotifier(repo);
});

// ───────── Préférences alertes ─────────

class GymAlertsPrefs {
  final bool beepEnabled;
  final bool voiceEnabled;
  const GymAlertsPrefs(
      {required this.beepEnabled, required this.voiceEnabled});

  GymAlertsPrefs copyWith({bool? beepEnabled, bool? voiceEnabled}) =>
      GymAlertsPrefs(
        beepEnabled: beepEnabled ?? this.beepEnabled,
        voiceEnabled: voiceEnabled ?? this.voiceEnabled,
      );
}

class GymAlertsNotifier extends StateNotifier<GymAlertsPrefs> {
  final dynamic _storage; // LocalStorage

  GymAlertsNotifier(this._storage)
      : super(GymAlertsPrefs(
          beepEnabled: _storage.gymBeepEnabled as bool,
          voiceEnabled: _storage.gymVoiceEnabled as bool,
        ));

  Future<void> setBeep(bool value) async {
    await _storage.setGymBeepEnabled(value);
    state = state.copyWith(beepEnabled: value);
  }

  Future<void> setVoice(bool value) async {
    await _storage.setGymVoiceEnabled(value);
    state = state.copyWith(voiceEnabled: value);
  }
}

final gymAlertsProvider =
    StateNotifierProvider<GymAlertsNotifier, GymAlertsPrefs>((ref) {
  final storage = ref.watch(localStorageProvider);
  return GymAlertsNotifier(storage);
});
