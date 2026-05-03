import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/workout_session.dart';
import '../models/gym/gym_exercise.dart';
import '../models/gym/gym_session.dart';

/// Clés de stockage SharedPreferences.
class StorageKeys {
  static const String sessions = 'workout_sessions';
  static const String selectedVoiceId = 'selected_voice_id';
  static const String selectedVoiceName = 'selected_voice_name';
  static const String voiceEnabled = 'voice_enabled';
  static const String voiceConfigured = 'voice_configured'; // a-t-on déjà vu l'écran config voix
  static const String activeSessionId = 'active_session_id';

  // Gym (séances de salle de sport)
  static const String gymExercises = 'gym_exercises';
  static const String gymSessions = 'gym_sessions';
  static const String gymBeepEnabled = 'gym_beep_enabled';
  static const String gymVoiceEnabled = 'gym_voice_enabled';
}

/// Service de persistance locale (SharedPreferences).
class LocalStorage {
  final SharedPreferences _prefs;

  LocalStorage(this._prefs);

  // ───────── Sessions ─────────

  List<WorkoutSession> loadSessions() {
    final raw = _prefs.getString(StorageKeys.sessions);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => WorkoutSession.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveSessions(List<WorkoutSession> sessions) async {
    final encoded = jsonEncode(sessions.map((s) => s.toJson()).toList());
    await _prefs.setString(StorageKeys.sessions, encoded);
  }

  Future<void> saveSession(WorkoutSession session, List<WorkoutSession> allSessions) async {
    final idx = allSessions.indexWhere((s) => s.id == session.id);
    List<WorkoutSession> updated;
    if (idx >= 0) {
      updated = List.of(allSessions)..[idx] = session;
    } else {
      updated = [...allSessions, session];
    }
    await saveSessions(updated);
  }

  Future<void> deleteSession(String id, List<WorkoutSession> allSessions) async {
    final updated = allSessions.where((s) => s.id != id).toList();
    await saveSessions(updated);
  }

  // ───────── Voice settings ─────────

  String? get selectedVoiceId => _prefs.getString(StorageKeys.selectedVoiceId);
  String? get selectedVoiceName => _prefs.getString(StorageKeys.selectedVoiceName);
  bool get voiceEnabled => _prefs.getBool(StorageKeys.voiceEnabled) ?? false;
  bool get voiceConfigured => _prefs.getBool(StorageKeys.voiceConfigured) ?? false;

  Future<void> saveVoiceSettings({
    required String? voiceId,
    required String? voiceName,
    required bool enabled,
  }) async {
    if (voiceId != null) {
      await _prefs.setString(StorageKeys.selectedVoiceId, voiceId);
    } else {
      await _prefs.remove(StorageKeys.selectedVoiceId);
    }
    if (voiceName != null) {
      await _prefs.setString(StorageKeys.selectedVoiceName, voiceName);
    } else {
      await _prefs.remove(StorageKeys.selectedVoiceName);
    }
    await _prefs.setBool(StorageKeys.voiceEnabled, enabled);
    await _prefs.setBool(StorageKeys.voiceConfigured, true);
  }

  Future<void> markVoiceConfigured() async {
    await _prefs.setBool(StorageKeys.voiceConfigured, true);
  }

  Future<void> clearVoice() async {
    await _prefs.remove(StorageKeys.selectedVoiceId);
    await _prefs.remove(StorageKeys.selectedVoiceName);
    await _prefs.setBool(StorageKeys.voiceEnabled, false);
  }

  // ───────── Gym - Exercices globaux ─────────

  List<GymExercise> loadGymExercises() {
    final raw = _prefs.getString(StorageKeys.gymExercises);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => GymExercise.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveGymExercises(List<GymExercise> exercises) async {
    final encoded = jsonEncode(exercises.map((e) => e.toJson()).toList());
    await _prefs.setString(StorageKeys.gymExercises, encoded);
  }

  // ───────── Gym - Séances ─────────

  List<GymSession> loadGymSessions() {
    final raw = _prefs.getString(StorageKeys.gymSessions);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => GymSession.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveGymSessions(List<GymSession> sessions) async {
    final encoded = jsonEncode(sessions.map((s) => s.toJson()).toList());
    await _prefs.setString(StorageKeys.gymSessions, encoded);
  }

  // ───────── Gym - Préférences alertes ─────────

  bool get gymBeepEnabled => _prefs.getBool(StorageKeys.gymBeepEnabled) ?? true;
  bool get gymVoiceEnabled =>
      _prefs.getBool(StorageKeys.gymVoiceEnabled) ?? false;

  Future<void> setGymBeepEnabled(bool value) async {
    await _prefs.setBool(StorageKeys.gymBeepEnabled, value);
  }

  Future<void> setGymVoiceEnabled(bool value) async {
    await _prefs.setBool(StorageKeys.gymVoiceEnabled, value);
  }
}
