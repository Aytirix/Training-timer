import 'package:uuid/uuid.dart';
import '../../services/exercise_name_normalizer.dart';
import 'exercise_video.dart';

/// Type d'un exercice. Détermine les champs requis dans une série.
enum GymExerciseType {
  poidsRepetitions,
  repetitions,
  duree,
  poidsDuree;

  String get id {
    switch (this) {
      case GymExerciseType.poidsRepetitions:
        return 'poids_repetitions';
      case GymExerciseType.repetitions:
        return 'repetitions';
      case GymExerciseType.duree:
        return 'duree';
      case GymExerciseType.poidsDuree:
        return 'poids_duree';
    }
  }

  static GymExerciseType? fromId(String? id) {
    switch (id) {
      case 'poids_repetitions':
        return GymExerciseType.poidsRepetitions;
      case 'repetitions':
        return GymExerciseType.repetitions;
      case 'duree':
        return GymExerciseType.duree;
      case 'poids_duree':
        return GymExerciseType.poidsDuree;
      default:
        return null;
    }
  }

  String get label {
    switch (this) {
      case GymExerciseType.poidsRepetitions:
        return 'Poids + répétitions';
      case GymExerciseType.repetitions:
        return 'Répétitions';
      case GymExerciseType.duree:
        return 'Durée';
      case GymExerciseType.poidsDuree:
        return 'Poids + durée';
    }
  }

  bool get hasWeight =>
      this == GymExerciseType.poidsRepetitions ||
      this == GymExerciseType.poidsDuree;

  bool get hasReps =>
      this == GymExerciseType.poidsRepetitions ||
      this == GymExerciseType.repetitions;

  bool get hasDuration =>
      this == GymExerciseType.duree || this == GymExerciseType.poidsDuree;
}

/// Exercice global réutilisable dans plusieurs séances.
class GymExercise {
  final String id;
  final String name;
  final GymExerciseType type;
  final String instructions;
  final ExerciseVideo? video;
  final DateTime createdAt;
  final DateTime updatedAt;

  GymExercise({
    String? id,
    required this.name,
    required this.type,
    this.instructions = '',
    this.video,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  String get normalizedName => ExerciseNameNormalizer.normalize(name);

  /// Identité fonctionnelle : nom normalisé + type.
  String get functionalKey => '$normalizedName|${type.id}';

  /// Deux exercices sont fonctionnellement égaux si leur clé est identique.
  bool functionallyEquals(GymExercise other) =>
      functionalKey == other.functionalKey;

  bool functionallyEqualsNameType(String otherName, GymExerciseType otherType) {
    return ExerciseNameNormalizer.normalize(otherName) == normalizedName &&
        otherType == type;
  }

  GymExercise copyWith({
    String? id,
    String? name,
    GymExerciseType? type,
    String? instructions,
    ExerciseVideo? video,
    bool clearVideo = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GymExercise(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      instructions: instructions ?? this.instructions,
      video: clearVideo ? null : (video ?? this.video),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type.id,
        'instructions': instructions,
        'video': video?.toJson(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory GymExercise.fromJson(Map<String, dynamic> json) {
    final typeId = json['type'] as String?;
    final type = GymExerciseType.fromId(typeId);
    if (type == null) {
      throw FormatException('Type d\'exercice invalide: $typeId');
    }
    final videoJson = json['video'];
    return GymExercise(
      id: json['id'] as String?,
      name: json['name'] as String,
      type: type,
      instructions: json['instructions'] as String? ?? '',
      video: videoJson is Map<String, dynamic>
          ? ExerciseVideo.fromJson(videoJson)
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
    );
  }
}
