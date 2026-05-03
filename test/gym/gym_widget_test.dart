import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:traction_timer/core/models/gym/exercise_video.dart';
import 'package:traction_timer/core/models/gym/gym_exercise.dart';
import 'package:traction_timer/core/models/gym/gym_session.dart';
import 'package:traction_timer/core/models/gym/gym_session_item.dart';
import 'package:traction_timer/core/models/gym/gym_set.dart';
import 'package:traction_timer/core/storage/local_storage.dart';
import 'package:traction_timer/features/gym/presentation/exercise_editor_screen.dart';
import 'package:traction_timer/features/gym/presentation/gym_json_import_screen.dart';
import 'package:traction_timer/features/gym/presentation/gym_session_editor_screen.dart';
import 'package:traction_timer/features/gym/presentation/gym_sessions_screen.dart';
import 'package:traction_timer/features/gym/presentation/gym_video_player_screen.dart';
import 'package:traction_timer/features/workouts/domain/workout_provider.dart';

Future<Widget> _wrapWithProviders(Widget child) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  return _wrapWithPrefs(child, prefs);
}

Widget _wrapWithPrefs(Widget child, SharedPreferences prefs) {
  return ProviderScope(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    child: MaterialApp(home: child),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('création séance revient sur la liste et affiche la séance',
      (tester) async {
    await tester
        .pumpWidget(await _wrapWithProviders(const GymSessionsScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(find.text('Nouvelle séance'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'Séance test');
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();

    expect(find.text('Séance test'), findsOneWidget);
    expect(find.text('1 séance'), findsOneWidget);
  });

  testWidgets(
      'liste séances affiche une séance sauvegardée avec deux exercices',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final storage = LocalStorage(prefs);
    final squat =
        GymExercise(name: 'Squat', type: GymExerciseType.poidsRepetitions);
    final gainage = GymExercise(name: 'Gainage', type: GymExerciseType.duree);
    await storage.saveGymExercises([squat, gainage]);
    await storage.saveGymSessions([
      GymSession(
        name: 'Séance complète',
        description: 'Deux exercices',
        items: [
          GymSessionExerciseItem(
            exerciseId: squat.id,
            sets: const [
              GymSet(weightKg: 60, repetitions: 10),
              GymSet(weightKg: 70, repetitions: 8),
            ],
          ),
          GymSessionRestItem(durationSeconds: 120),
          GymSessionExerciseItem(
            exerciseId: gainage.id,
            timedSetStartMode: TimedSetStartMode.manual,
            sets: const [GymSet(durationSeconds: 45)],
          ),
        ],
      ),
    ]);

    await tester.pumpWidget(_wrapWithPrefs(const GymSessionsScreen(), prefs));
    await tester.pumpAndSettle();

    expect(find.text('Séance complète'), findsOneWidget);
    expect(find.text('Deux exercices'), findsOneWidget);
    expect(find.text('1 séance'), findsOneWidget);
    expect(find.text('2 exercices'), findsOneWidget);
    expect(find.text('3 séries'), findsOneWidget);
  });

  testWidgets('éditeur exercice propose URL et vidéo locale', (tester) async {
    await tester
        .pumpWidget(await _wrapWithProviders(const ExerciseEditorScreen()));
    await tester.pumpAndSettle();

    expect(find.text('URL de la vidéo'), findsWidgets);
    expect(find.text('Vidéo locale'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(3));

    await tester.tap(find.text('Vidéo locale'));
    await tester.pumpAndSettle();

    expect(find.text('Choisir une vidéo'), findsOneWidget);
    expect(find.text('Aucune vidéo locale sélectionnée'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'URL de la vidéo'), findsNothing);

    await tester.tap(find.text('URL de la vidéo'));
    await tester.pumpAndSettle();

    expect(
        find.widgetWithText(TextFormField, 'URL de la vidéo'), findsOneWidget);
  });

  testWidgets('écran import JSON affiche le formulaire', (tester) async {
    await tester.pumpWidget(await _wrapWithProviders(
      const GymJsonImportScreen(),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Importer une séance'), findsOneWidget);
    expect(find.text('Collez ici le JSON de la séance.'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Analyser'), findsOneWidget);
  });

  testWidgets('champs séance exposent une sortie de focus au tap extérieur',
      (tester) async {
    await tester
        .pumpWidget(await _wrapWithProviders(const GymSessionEditorScreen()));
    await tester.pumpAndSettle();

    final fields = tester.widgetList<TextField>(find.byType(TextField));
    expect(fields.length, 2);
    expect(fields.every((field) => field.onTapOutside != null), true);
  });

  test('launcher vidéo identifie les vidéos YouTube', () {
    const video = ExerciseVideo(
      source: ExerciseVideoSource.youtube,
      url: 'https://www.youtube.com/watch?v=abc123',
    );

    expect(GymVideoLauncher.videoLabel(video), 'Lire la vidéo YouTube');
  });
}
