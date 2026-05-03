import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/audio/tts_service.dart';
import '../../../core/storage/local_storage.dart';
import '../../workouts/domain/workout_provider.dart';

// ── Providers globaux ──

final ttsServiceProvider = Provider<TtsService>((ref) => TtsService());

// ── State ──

class VoiceState {
  final List<VoiceInfo> availableVoices;
  final VoiceInfo? selectedVoice;
  final bool voiceEnabled;
  final bool isLoading;
  final bool isTesting;
  final String? error;

  const VoiceState({
    this.availableVoices = const [],
    this.selectedVoice,
    this.voiceEnabled = false,
    this.isLoading = false,
    this.isTesting = false,
    this.error,
  });

  VoiceState copyWith({
    List<VoiceInfo>? availableVoices,
    VoiceInfo? selectedVoice,
    bool? voiceEnabled,
    bool? isLoading,
    bool? isTesting,
    String? error,
    bool clearSelection = false,
    bool clearError = false,
  }) {
    return VoiceState(
      availableVoices: availableVoices ?? this.availableVoices,
      selectedVoice:
          clearSelection ? null : (selectedVoice ?? this.selectedVoice),
      voiceEnabled: voiceEnabled ?? this.voiceEnabled,
      isLoading: isLoading ?? this.isLoading,
      isTesting: isTesting ?? this.isTesting,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ── Notifier ──

class VoiceNotifier extends StateNotifier<VoiceState> {
  final TtsService _tts;
  final LocalStorage _storage;

  VoiceNotifier(this._tts, this._storage)
      : super(VoiceState(
          voiceEnabled: _storage.voiceEnabled,
        ));

  /// Charge les voix disponibles et restaure la sélection.
  Future<void> loadVoices() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final voices = await _tts.getAvailableVoices();
      final savedId = _storage.selectedVoiceId;

      VoiceInfo? selected;
      if (savedId != null) {
        try {
          selected = voices.firstWhere((v) => v.key == savedId);
        } catch (_) {
          // Voix sauvegardée plus disponible
          await _storage.clearVoice();
          state = state.copyWith(
            availableVoices: voices,
            isLoading: false,
            voiceEnabled: false,
            clearSelection: true,
            error: 'La voix précédemment sélectionnée n\'est plus disponible.',
          );
          return;
        }
      } else if (voices.isNotEmpty) {
        selected = voices.first;
        final ok = await _tts.setVoice(selected);
        if (ok) {
          await _storage.saveVoiceSettings(
            voiceId: selected.key,
            voiceName: selected.name,
            enabled: true,
          );
        } else {
          selected = null;
        }
      }

      if (selected != null) {
        await _tts.setVoice(selected);
      }

      state = state.copyWith(
        availableVoices: voices,
        selectedVoice: selected,
        voiceEnabled: _storage.voiceEnabled && selected != null,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Impossible de charger les voix : $e',
      );
    }
  }

  /// Sélectionne une voix.
  Future<void> selectVoice(VoiceInfo voice) async {
    final ok = await _tts.setVoice(voice);
    if (!ok) {
      state = state.copyWith(error: 'Impossible de configurer cette voix.');
      return;
    }
    state = state.copyWith(
      selectedVoice: voice,
      voiceEnabled: true,
      clearError: true,
    );
    await _storage.saveVoiceSettings(
      voiceId: voice.key,
      voiceName: voice.name,
      enabled: true,
    );
  }

  /// Désactive la voix sans supprimer la sélection.
  Future<void> disableVoice() async {
    await _tts.stop();
    state = state.copyWith(
        voiceEnabled: false, clearSelection: true, clearError: true);
    await _storage.clearVoice();
  }

  /// Teste une voix en la lisant.
  Future<void> testVoice(VoiceInfo voice) async {
    if (state.isTesting) return;
    state = state.copyWith(isTesting: true);
    await _tts.setVoice(voice);
    await _tts.speak('4 tractions. 3. 2. 1. Go !');
    state = state.copyWith(isTesting: false);
  }

  /// Marque l'écran de config voix comme vu (même sans choix).
  Future<void> markConfigured() async {
    await _storage.markVoiceConfigured();
  }

  bool get isConfigured => _storage.voiceConfigured;
}

// ── Provider ──

final voiceProvider = StateNotifierProvider<VoiceNotifier, VoiceState>((ref) {
  final tts = ref.watch(ttsServiceProvider);
  final storage = ref.watch(localStorageProvider);
  return VoiceNotifier(tts, storage);
});
