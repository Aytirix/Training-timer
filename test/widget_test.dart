// Smoke test minimal du démarrage de l'application avec les onglets.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:traction_timer/core/audio/tts_service.dart';
import 'package:traction_timer/app/app.dart';
import 'package:traction_timer/features/voice/application/voice_provider.dart';
import 'package:traction_timer/features/workouts/domain/workout_provider.dart';

class _FakeTtsService extends TtsService {
  final List<VoiceInfo> voices;
  _FakeTtsService(this.voices);

  @override
  Future<List<VoiceInfo>> getAvailableVoices() async => voices;

  @override
  Future<bool> setVoice(VoiceInfo voice) async => true;
}

void main() {
  testWidgets('App démarre et affiche les onglets Minuteurs / Séances',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          ttsServiceProvider.overrideWithValue(_FakeTtsService(
            const [VoiceInfo(name: 'Voix test', locale: 'fr-FR')],
          )),
        ],
        child: const TrainingTimerApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Minuteurs'), findsWidgets);
    expect(find.text('Séances'), findsWidgets);
    expect(
      find.text('Configurer une voix pour les annonces vocales (optionnel)'),
      findsNothing,
    );
  });
}
