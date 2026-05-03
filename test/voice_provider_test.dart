import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:traction_timer/core/audio/tts_service.dart';
import 'package:traction_timer/core/storage/local_storage.dart';
import 'package:traction_timer/features/voice/application/voice_provider.dart';

class _FakeTtsService extends TtsService {
  _FakeTtsService(this.voices);

  final List<VoiceInfo> voices;
  VoiceInfo? selected;

  @override
  Future<List<VoiceInfo>> getAvailableVoices() async => voices;

  @override
  Future<bool> setVoice(VoiceInfo voice) async {
    selected = voice;
    return true;
  }

  @override
  Future<void> stop() async {}

  @override
  Future<void> speak(String text) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('sélectionne automatiquement la première voix si aucune configurée',
      () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final storage = LocalStorage(prefs);
    const first = VoiceInfo(name: 'Voix A', locale: 'fr-FR');
    const second = VoiceInfo(name: 'Voix B', locale: 'fr-FR');
    final tts = _FakeTtsService([first, second]);
    final notifier = VoiceNotifier(tts, storage);

    await notifier.loadVoices();

    expect(notifier.state.selectedVoice, first);
    expect(notifier.state.voiceEnabled, true);
    expect(tts.selected, first);
    expect(storage.selectedVoiceId, first.key);
    expect(storage.voiceEnabled, true);
    expect(storage.voiceConfigured, true);
  });
}
