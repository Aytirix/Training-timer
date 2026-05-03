import 'dart:async';
import 'package:flutter_tts/flutter_tts.dart';

/// Modèle représentant une voix disponible sur l'appareil.
class VoiceInfo {
  final String name;
  final String locale;
  final String? identifier;

  const VoiceInfo({
    required this.name,
    required this.locale,
    this.identifier,
  });

  /// Clé unique pour identifier la voix (utilisé pour sauvegarde)
  String get key => identifier ?? '$name-$locale';

  String get displayLocale {
    final parts = locale.split('-');
    if (parts.isEmpty) return locale;
    return parts.first.toUpperCase();
  }

  @override
  String toString() => 'VoiceInfo($name, $locale)';

  @override
  bool operator ==(Object other) =>
      other is VoiceInfo && key == other.key;

  @override
  int get hashCode => key.hashCode;
}

/// Service TTS encapsulant flutter_tts.
/// Gère la liste des voix, la sélection et la synthèse vocale.
class TtsService {
  final FlutterTts _tts = FlutterTts();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    await _tts.setVolume(1.0);
    await _tts.setSpeechRate(0.5);
    await _tts.setPitch(1.0);
    _initialized = true;
  }

  /// Retourne toutes les voix disponibles sur l'appareil.
  Future<List<VoiceInfo>> getAvailableVoices() async {
    await init();
    try {
      final rawVoices = await _tts.getVoices;
      if (rawVoices == null) return [];

      final voices = <VoiceInfo>[];
      final seen = <String>{};

      for (final v in rawVoices) {
        if (v is! Map) continue;
        final name = v['name']?.toString() ?? '';
        final locale = v['locale']?.toString() ?? '';
        final identifier = v['identifier']?.toString();

        if (name.isEmpty || locale.isEmpty) continue;

        final info = VoiceInfo(name: name, locale: locale, identifier: identifier);
        if (!seen.contains(info.key)) {
          seen.add(info.key);
          voices.add(info);
        }
      }

      // Trie : français en premier, puis alphabétique
      voices.sort((a, b) {
        final aFr = a.locale.startsWith('fr') ? 0 : 1;
        final bFr = b.locale.startsWith('fr') ? 0 : 1;
        if (aFr != bFr) return aFr - bFr;
        return a.name.compareTo(b.name);
      });

      return voices;
    } catch (_) {
      return [];
    }
  }

  /// Sélectionne une voix par sa clé.
  Future<bool> setVoice(VoiceInfo voice) async {
    await init();
    try {
      final voiceMap = <String, String>{'name': voice.name, 'locale': voice.locale};
      if (voice.identifier != null) voiceMap['identifier'] = voice.identifier!;
      await _tts.setVoice(voiceMap);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Vérifie si une voix est disponible sur l'appareil.
  Future<bool> isVoiceAvailable(String voiceKey) async {
    final voices = await getAvailableVoices();
    return voices.any((v) => v.key == voiceKey);
  }

  /// Prononce un texte (non-bloquant : retourne dès que la synthèse démarre).
  Future<void> speak(String text) async {
    if (!_initialized) await init();
    await _tts.stop();
    await _tts.speak(text);
  }

  /// Prononce un texte et attend la fin de la synthèse avant de retourner.
  Future<void> speakAndWait(String text) async {
    if (!_initialized) await init();
    final completer = Completer<void>();
    _tts.setCompletionHandler(() {
      if (!completer.isCompleted) completer.complete();
    });
    await _tts.stop();
    await _tts.speak(text);
    await completer.future;
  }

  /// Arrête la synthèse en cours.
  Future<void> stop() async {
    await _tts.stop();
  }

  /// Libère les ressources.
  Future<void> dispose() async {
    await _tts.stop();
  }
}
