/// Source d'une vidéo d'exercice.
enum ExerciseVideoSource {
  localFile,
  directUrl,
  youtube,
  platformLink,
  unknown;

  String get id {
    switch (this) {
      case ExerciseVideoSource.localFile:
        return 'localFile';
      case ExerciseVideoSource.directUrl:
        return 'directUrl';
      case ExerciseVideoSource.youtube:
        return 'youtube';
      case ExerciseVideoSource.platformLink:
        return 'platformLink';
      case ExerciseVideoSource.unknown:
        return 'unknown';
    }
  }

  static ExerciseVideoSource fromId(String? id) {
    switch (id) {
      case 'localFile':
        return ExerciseVideoSource.localFile;
      case 'directUrl':
        return ExerciseVideoSource.directUrl;
      case 'youtube':
        return ExerciseVideoSource.youtube;
      case 'platformLink':
        return ExerciseVideoSource.platformLink;
      default:
        return ExerciseVideoSource.unknown;
    }
  }
}

/// Vidéo rattachée à un exercice global.
class ExerciseVideo {
  final ExerciseVideoSource source;
  final String? url;
  final String? localPath;
  final String? originalFileName;

  const ExerciseVideo({
    required this.source,
    this.url,
    this.localPath,
    this.originalFileName,
  });

  bool get hasContent =>
      (url != null && url!.isNotEmpty) ||
      (localPath != null && localPath!.isNotEmpty);

  ExerciseVideo copyWith({
    ExerciseVideoSource? source,
    String? url,
    String? localPath,
    String? originalFileName,
  }) {
    return ExerciseVideo(
      source: source ?? this.source,
      url: url ?? this.url,
      localPath: localPath ?? this.localPath,
      originalFileName: originalFileName ?? this.originalFileName,
    );
  }

  Map<String, dynamic> toJson() => {
        'source': source.id,
        if (url != null) 'url': url,
        if (localPath != null) 'localPath': localPath,
        if (originalFileName != null) 'originalFileName': originalFileName,
      };

  /// Désérialisation interne (avec localPath).
  factory ExerciseVideo.fromJson(Map<String, dynamic> json) {
    return ExerciseVideo(
      source: ExerciseVideoSource.fromId(json['source'] as String?),
      url: json['url'] as String?,
      localPath: json['localPath'] as String?,
      originalFileName: json['originalFileName'] as String?,
    );
  }

  /// Désérialisation pour import JSON portable (sans localPath).
  factory ExerciseVideo.fromPortableJson(Map<String, dynamic> json) {
    final source = ExerciseVideoSource.fromId(json['source'] as String?);
    if (source == ExerciseVideoSource.localFile) {
      // Une vidéo locale n'est pas portable : on la traite comme inconnue
      return const ExerciseVideo(source: ExerciseVideoSource.unknown);
    }
    return ExerciseVideo(
      source: source,
      url: json['url'] as String?,
    );
  }

  /// Sérialisation portable (sans localPath).
  Map<String, dynamic> toPortableJson() {
    if (source == ExerciseVideoSource.localFile) {
      return {'source': ExerciseVideoSource.localFile.id};
    }
    return {
      'source': source.id,
      if (url != null) 'url': url,
    };
  }

  @override
  bool operator ==(Object other) =>
      other is ExerciseVideo &&
      other.source == source &&
      other.url == url &&
      other.localPath == localPath;

  @override
  int get hashCode => Object.hash(source, url, localPath);
}
