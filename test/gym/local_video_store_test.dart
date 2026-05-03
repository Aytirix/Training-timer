import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:traction_timer/core/models/gym/exercise_video.dart';
import 'package:traction_timer/core/models/gym/gym_exercise.dart';
import 'package:traction_timer/features/gym/services/local_video_store.dart';

class _FakePathProviderPlatform extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  _FakePathProviderPlatform(this.documentsPath);

  final String documentsPath;

  @override
  Future<String?> getApplicationDocumentsPath() async => documentsPath;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  GymExercise withLocal(String name, String path) {
    return GymExercise(
      name: name,
      type: GymExerciseType.repetitions,
      video:
          ExerciseVideo(source: ExerciseVideoSource.localFile, localPath: path),
    );
  }

  group('LocalVideoUsageTracker', () {
    test('findUsers retourne les exercices qui partagent le chemin', () {
      final a = withLocal('A', '/store/v1.mp4');
      final b = withLocal('B', '/store/v1.mp4');
      final c = withLocal('C', '/store/v2.mp4');
      final users =
          LocalVideoUsageTracker.findUsers([a, b, c], '/store/v1.mp4');
      expect(users.length, 2);
    });

    test('isStillUsed exclut l\'exercice fourni', () {
      final a = withLocal('A', '/store/v1.mp4');
      final b = withLocal('B', '/store/v1.mp4');
      expect(
          LocalVideoUsageTracker.isStillUsed([a, b], '/store/v1.mp4',
              excludeId: a.id),
          true);
    });

    test('isStillUsed false si dernier référent', () {
      final a = withLocal('A', '/store/v1.mp4');
      expect(
          LocalVideoUsageTracker.isStillUsed([a], '/store/v1.mp4',
              excludeId: a.id),
          false);
    });

    test('canDeletePhysical true si plus aucun ref hors exclu', () {
      final a = withLocal('A', '/store/v1.mp4');
      expect(
          LocalVideoUsageTracker.canDeletePhysical(
              allExercises: [a],
              modifiedExercise: a,
              previousLocalPath: '/store/v1.mp4'),
          true);
    });

    test('canDeletePhysical false si encore partagé', () {
      final a = withLocal('A', '/store/v1.mp4');
      final b = withLocal('B', '/store/v1.mp4');
      expect(
          LocalVideoUsageTracker.canDeletePhysical(
              allExercises: [a, b],
              modifiedExercise: a,
              previousLocalPath: '/store/v1.mp4'),
          false);
    });
  });

  group('LocalVideoStore', () {
    test('copyIntoAppStorage copie le fichier et conserve le nom original',
        () async {
      final temp =
          await Directory.systemTemp.createTemp('traction_video_test_');
      addTearDown(() async {
        if (await temp.exists()) {
          await temp.delete(recursive: true);
        }
      });

      PathProviderPlatform.instance = _FakePathProviderPlatform(temp.path);
      final source = File('${temp.path}/source.mp4');
      await source.writeAsBytes([1, 2, 3, 4]);

      final video = await LocalVideoStore.copyIntoAppStorage(
        sourcePath: source.path,
        originalFileName: 'source.mp4',
      );

      expect(video.source, ExerciseVideoSource.localFile);
      expect(video.originalFileName, 'source.mp4');
      expect(video.localPath, isNot(source.path));
      expect(video.localPath, endsWith('.mp4'));
      expect(await File(video.localPath!).exists(), true);
      expect(await File(video.localPath!).readAsBytes(), [1, 2, 3, 4]);
    });
  });
}
