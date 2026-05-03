import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../../core/models/gym/exercise_video.dart';
import '../../../core/models/gym/gym_exercise.dart';

/// Détermine si un chemin local est encore référencé par au moins un autre
/// exercice que celui en cours d'opération.
class LocalVideoUsageTracker {
  /// Liste tous les exercices qui pointent vers `localPath`.
  static List<GymExercise> findUsers(
      List<GymExercise> exercises, String localPath) {
    return exercises.where((e) {
      final v = e.video;
      if (v == null) return false;
      if (v.source != ExerciseVideoSource.localFile) return false;
      return v.localPath == localPath;
    }).toList();
  }

  /// Indique si le fichier est encore utilisé par d'autres exercices après
  /// retrait de l'exercice `excludeId`.
  static bool isStillUsed(
    List<GymExercise> exercises,
    String localPath, {
    required String excludeId,
  }) {
    return exercises.any((e) =>
        e.id != excludeId &&
        e.video?.source == ExerciseVideoSource.localFile &&
        e.video?.localPath == localPath);
  }

  /// Quand on supprime ou modifie la vidéo d'un exercice, retourne `true`
  /// si le fichier local précédemment associé peut être supprimé physiquement.
  static bool canDeletePhysical({
    required List<GymExercise> allExercises,
    required GymExercise modifiedExercise,
    required String previousLocalPath,
  }) {
    return !isStillUsed(allExercises, previousLocalPath,
        excludeId: modifiedExercise.id);
  }
}

class LocalVideoStore {
  static const _folderName = 'gym_exercise_videos';

  static Future<ExerciseVideo> copyIntoAppStorage({
    required String sourcePath,
    required String originalFileName,
  }) async {
    final source = File(sourcePath);
    if (!await source.exists()) {
      throw const FileSystemException('Fichier vidéo introuvable');
    }

    final appDir = await getApplicationDocumentsDirectory();
    final videoDir = Directory('${appDir.path}/$_folderName');
    if (!await videoDir.exists()) {
      await videoDir.create(recursive: true);
    }

    final extension = _extensionOf(originalFileName);
    final safeName = '${const Uuid().v4()}$extension';
    final targetPath = '${videoDir.path}/$safeName';
    await source.copy(targetPath);

    return ExerciseVideo(
      source: ExerciseVideoSource.localFile,
      localPath: targetPath,
      originalFileName: originalFileName,
    );
  }

  static Future<void> deleteIfExists(String localPath) async {
    final file = File(localPath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  static String _extensionOf(String fileName) {
    final dot = fileName.lastIndexOf('.');
    if (dot < 0 || dot == fileName.length - 1) return '';
    return fileName.substring(dot);
  }
}
