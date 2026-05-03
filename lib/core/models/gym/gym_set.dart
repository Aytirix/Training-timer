import 'gym_exercise.dart';

/// Erreurs de validation d'une série.
class GymSetValidationError {
  final String field;
  final String message;
  const GymSetValidationError(this.field, this.message);

  @override
  String toString() => '[$field] $message';
}

/// Une série configurée pour un exercice dans une séance.
///
/// Les champs requis dépendent du type de l'exercice parent.
class GymSet {
  final double? weightKg;
  final int? repetitions;
  final int? durationSeconds;

  /// Repos après cette série, en secondes. Doit être nul ou ignoré pour la
  /// dernière série d'un exercice.
  final int? restAfterSetSeconds;

  const GymSet({
    this.weightKg,
    this.repetitions,
    this.durationSeconds,
    this.restAfterSetSeconds,
  });

  GymSet copyWith({
    double? weightKg,
    int? repetitions,
    int? durationSeconds,
    int? restAfterSetSeconds,
    bool clearWeight = false,
    bool clearRepetitions = false,
    bool clearDuration = false,
    bool clearRest = false,
  }) {
    return GymSet(
      weightKg: clearWeight ? null : (weightKg ?? this.weightKg),
      repetitions: clearRepetitions ? null : (repetitions ?? this.repetitions),
      durationSeconds:
          clearDuration ? null : (durationSeconds ?? this.durationSeconds),
      restAfterSetSeconds:
          clearRest ? null : (restAfterSetSeconds ?? this.restAfterSetSeconds),
    );
  }

  /// Liste des erreurs bloquantes pour le lancement, selon type.
  ///
  /// `isLast` : si true, `restAfterSetSeconds` est ignoré et doit pouvoir
  /// rester vide.
  List<GymSetValidationError> validate(GymExerciseType type,
      {required bool isLast}) {
    final errors = <GymSetValidationError>[];
    if (type.hasWeight) {
      if (weightKg == null) {
        errors.add(const GymSetValidationError('weightKg', 'Poids requis'));
      } else if (weightKg! < 0) {
        errors.add(const GymSetValidationError(
            'weightKg', 'Le poids doit être >= 0'));
      }
    }
    if (type.hasReps) {
      if (repetitions == null) {
        errors.add(
            const GymSetValidationError('repetitions', 'Répétitions requises'));
      } else if (repetitions! <= 0) {
        errors.add(const GymSetValidationError(
            'repetitions', 'Répétitions doivent être > 0'));
      }
    }
    if (type.hasDuration) {
      if (durationSeconds == null) {
        errors
            .add(const GymSetValidationError('durationSeconds', 'Durée requise'));
      } else if (durationSeconds! <= 0) {
        errors.add(const GymSetValidationError(
            'durationSeconds', 'Durée doit être > 0'));
      }
    }
    if (!isLast &&
        restAfterSetSeconds != null &&
        restAfterSetSeconds! < 0) {
      errors.add(const GymSetValidationError(
          'restAfterSetSeconds', 'Repos négatif interdit'));
    }
    return errors;
  }

  bool isValid(GymExerciseType type, {required bool isLast}) =>
      validate(type, isLast: isLast).isEmpty;

  Map<String, dynamic> toJson() => {
        if (weightKg != null) 'weightKg': weightKg,
        if (repetitions != null) 'repetitions': repetitions,
        if (durationSeconds != null) 'durationSeconds': durationSeconds,
        'restAfterSetSeconds': restAfterSetSeconds,
      };

  factory GymSet.fromJson(Map<String, dynamic> json) {
    final w = json['weightKg'];
    return GymSet(
      weightKg: w == null ? null : (w as num).toDouble(),
      repetitions: json['repetitions'] as int?,
      durationSeconds: json['durationSeconds'] as int?,
      restAfterSetSeconds: json['restAfterSetSeconds'] as int?,
    );
  }
}
