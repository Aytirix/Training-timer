import '../../../core/models/gym/exercise_video.dart';

/// Détecte le type d'une URL vidéo et valide les URLs directes.
class ExerciseVideoDetector {
  static const _directExtensions = [
    '.mp4',
    '.m4v',
    '.mov',
    '.webm',
    '.mkv',
    '.avi',
    '.3gp',
  ];

  static const _youtubeHosts = [
    'youtube.com',
    'www.youtube.com',
    'm.youtube.com',
    'youtu.be',
    'youtube-nocookie.com',
    'www.youtube-nocookie.com',
  ];

  static const _platformHosts = [
    'instagram.com',
    'www.instagram.com',
    'tiktok.com',
    'www.tiktok.com',
    'vm.tiktok.com',
    'facebook.com',
    'www.facebook.com',
    'fb.watch',
    'twitter.com',
    'x.com',
    'vimeo.com',
    'www.vimeo.com',
  ];

  /// Détecte la source d'une URL.
  static ExerciseVideoSource detect(String input) {
    final url = input.trim();
    if (url.isEmpty) return ExerciseVideoSource.unknown;
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) {
      return ExerciseVideoSource.unknown;
    }
    final host = uri.host.toLowerCase();
    if (_youtubeHosts.contains(host)) return ExerciseVideoSource.youtube;
    if (_platformHosts.contains(host)) {
      return ExerciseVideoSource.platformLink;
    }
    final path = uri.path.toLowerCase();
    for (final ext in _directExtensions) {
      if (path.endsWith(ext)) return ExerciseVideoSource.directUrl;
    }
    // si http/https sans extension reconnue, on considère plateforme externe
    if (uri.scheme == 'http' || uri.scheme == 'https') {
      return ExerciseVideoSource.platformLink;
    }
    return ExerciseVideoSource.unknown;
  }

  /// Valide une URL directe : http(s) avec extension vidéo connue.
  static bool isValidDirectVideoUrl(String input) {
    final uri = Uri.tryParse(input.trim());
    if (uri == null) return false;
    if (uri.scheme != 'http' && uri.scheme != 'https') return false;
    final path = uri.path.toLowerCase();
    return _directExtensions.any(path.endsWith);
  }

  /// Extrait l'ID d'une vidéo YouTube si possible.
  static String? extractYoutubeId(String input) {
    final uri = Uri.tryParse(input.trim());
    if (uri == null) return null;
    final host = uri.host.toLowerCase();
    if (host == 'youtu.be') {
      final segs = uri.pathSegments;
      if (segs.isNotEmpty) return segs.first;
      return null;
    }
    if (_youtubeHosts.contains(host)) {
      final v = uri.queryParameters['v'];
      if (v != null && v.isNotEmpty) return v;
      // formats /embed/ID, /shorts/ID, /v/ID
      final segs = uri.pathSegments;
      for (final keyword in ['embed', 'shorts', 'v']) {
        final idx = segs.indexOf(keyword);
        if (idx >= 0 && idx + 1 < segs.length) return segs[idx + 1];
      }
    }
    return null;
  }
}
