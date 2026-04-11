import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/models/workout_session.dart';
import '../../../core/storage/local_storage.dart';
import '../data/default_workouts.dart';

// ── Infrastructure providers ──

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Initialize with ProviderScope override');
});

final localStorageProvider = Provider<LocalStorage>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return LocalStorage(prefs);
});

// ── Workouts state ──

class WorkoutListState {
  final List<WorkoutSession> sessions;
  final bool isLoading;
  final String? error;

  const WorkoutListState({
    this.sessions = const [],
    this.isLoading = false,
    this.error,
  });

  WorkoutListState copyWith({
    List<WorkoutSession>? sessions,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return WorkoutListState(
      sessions: sessions ?? this.sessions,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ── Notifier ──

class WorkoutNotifier extends StateNotifier<WorkoutListState> {
  final LocalStorage _storage;

  WorkoutNotifier(this._storage) : super(const WorkoutListState()) {
    _load();
  }

  void _load() {
    state = state.copyWith(isLoading: true);
    try {
      final sessions = _storage.loadSessions();
      if (sessions.isEmpty) {
        // Premier lancement : injecte la séance par défaut
        final defaults = DefaultWorkouts.all;
        _storage.saveSessions(defaults);
        state = state.copyWith(sessions: defaults, isLoading: false);
      } else {
        state = state.copyWith(sessions: sessions, isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        sessions: DefaultWorkouts.all,
        error: 'Erreur de chargement : $e',
      );
    }
  }

  Future<void> save(WorkoutSession session) async {
    await _storage.saveSession(session, state.sessions);
    final sessions = _storage.loadSessions();
    state = state.copyWith(sessions: sessions, clearError: true);
  }

  Future<void> delete(String id) async {
    await _storage.deleteSession(id, state.sessions);
    final sessions = _storage.loadSessions();
    state = state.copyWith(sessions: sessions, clearError: true);
  }

  Future<void> duplicate(WorkoutSession session) async {
    final copy = session.copyWith(
      id: null, // génère un nouvel ID
      name: '${session.name} (copie)',
      createdAt: DateTime.now(),
    );
    await save(copy);
  }

  WorkoutSession? findById(String id) {
    try {
      return state.sessions.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }
}

// ── Provider ──

final workoutProvider =
    StateNotifierProvider<WorkoutNotifier, WorkoutListState>((ref) {
  final storage = ref.watch(localStorageProvider);
  return WorkoutNotifier(storage);
});

/// Provider pour accéder à une session par ID.
final sessionByIdProvider =
    Provider.family<WorkoutSession?, String>((ref, id) {
  final state = ref.watch(workoutProvider);
  try {
    return state.sessions.firstWhere((s) => s.id == id);
  } catch (_) {
    return null;
  }
});
