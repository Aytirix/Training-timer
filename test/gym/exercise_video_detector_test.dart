import 'package:flutter_test/flutter_test.dart';
import 'package:traction_timer/core/models/gym/exercise_video.dart';
import 'package:traction_timer/features/gym/services/exercise_video_detector.dart';

void main() {
  group('ExerciseVideoDetector.detect', () {
    test('mp4 direct', () {
      expect(ExerciseVideoDetector.detect('https://example.com/v.mp4'),
          ExerciseVideoSource.directUrl);
    });

    test('webm direct', () {
      expect(ExerciseVideoDetector.detect('https://example.com/foo.webm'),
          ExerciseVideoSource.directUrl);
    });

    test('youtube watch', () {
      expect(
          ExerciseVideoDetector.detect(
              'https://www.youtube.com/watch?v=abc123'),
          ExerciseVideoSource.youtube);
    });

    test('youtu.be court', () {
      expect(ExerciseVideoDetector.detect('https://youtu.be/abc123'),
          ExerciseVideoSource.youtube);
    });

    test('instagram', () {
      expect(ExerciseVideoDetector.detect('https://instagram.com/p/xxx'),
          ExerciseVideoSource.platformLink);
    });

    test('tiktok', () {
      expect(ExerciseVideoDetector.detect('https://www.tiktok.com/@u/video/1'),
          ExerciseVideoSource.platformLink);
    });

    test('url inconnue mais http => plateforme', () {
      expect(ExerciseVideoDetector.detect('https://exo.example/page'),
          ExerciseVideoSource.platformLink);
    });

    test('texte non url => unknown', () {
      expect(ExerciseVideoDetector.detect('pas une url'),
          ExerciseVideoSource.unknown);
    });
  });

  group('isValidDirectVideoUrl', () {
    test('mp4 OK', () {
      expect(
          ExerciseVideoDetector.isValidDirectVideoUrl(
              'https://example.com/foo.mp4'),
          true);
    });

    test('https sans extension KO', () {
      expect(
          ExerciseVideoDetector.isValidDirectVideoUrl('https://example.com/foo'),
          false);
    });

    test('ftp KO', () {
      expect(
          ExerciseVideoDetector.isValidDirectVideoUrl('ftp://example.com/foo.mp4'),
          false);
    });
  });

  group('extractYoutubeId', () {
    test('watch?v=', () {
      expect(
          ExerciseVideoDetector.extractYoutubeId(
              'https://youtube.com/watch?v=abc'),
          'abc');
    });

    test('youtu.be', () {
      expect(ExerciseVideoDetector.extractYoutubeId('https://youtu.be/zZz'),
          'zZz');
    });

    test('shorts', () {
      expect(
          ExerciseVideoDetector.extractYoutubeId(
              'https://youtube.com/shorts/short1'),
          'short1');
    });

    test('embed', () {
      expect(
          ExerciseVideoDetector.extractYoutubeId(
              'https://youtube.com/embed/em1'),
          'em1');
    });

    test('non youtube', () {
      expect(ExerciseVideoDetector.extractYoutubeId('https://example.com/x'), null);
    });
  });
}
