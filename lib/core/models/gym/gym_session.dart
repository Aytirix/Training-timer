import 'package:uuid/uuid.dart';
import 'gym_exercise.dart';
import 'gym_session_item.dart';

/// Erreurs bloquantes lors de la validation d'une séance.
class GymSessionValidationError {
  final String code;
  final String message;
  const GymSessionValidationError(this.code, this.message);

  @override
  String toString() => '[$code] $message';
}

/// Séance de salle de sport.
class GymSession {
  final String id;
  final String name;
  final String description;
  final List<GymSessionItem> items;
  final DateTime createdAt;
  final DateTime updatedAt;

  GymSession({
    String? id,
    required this.name,
    this.description = '',
    required this.items,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Liste des items qui sont des exercices (utile pour calculer le nombre).
  List<GymSessionExerciseItem> get exerciseItems =>
      items.whereType<GymSessionExerciseItem>().toList();

  /// IDs des exercices globaux référencés.
  Set<String> get referencedExerciseIds =>
      exerciseItems.map((e) => e.exerciseId).toSet();

  GymSession copyWith({
    String? id,
    String? name,
    String? description,
    List<GymSessionItem>? items,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GymSession(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      items: items ?? this.items,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  /// Duplique la séance avec un nouvel ID.
  GymSession duplicate({String? newName}) {
    return GymSession(
      name: newName ?? '$name (copie)',
      description: description,
      items: items
          .map((item) {
            if (item is GymSessionExerciseItem) {
              return GymSessionExerciseItem(
                exerciseId: item.exerciseId,
                sets: item.sets.map((s) => s.copyWith()).toList(),
                timedSetStartMode: item.timedSetStartMode,
              );
            }
            if (item is GymSessionRestItem) {
              return GymSessionRestItem(
                durationSeconds: item.durationSeconds,
              );
            }
            return item;
          })
          .toList(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Validation complète : à utiliser avant lancement et avant sauvegarde stricte.
  ///
  /// `resolveExerciseType` : retourne le type d'un exercice global par son ID,
  /// ou null si introuvable.
  List<GymSessionValidationError> validate(
    GymExerciseType? Function(String exerciseId) resolveExerciseType,
  ) {
    final errors = <GymSessionValidationError>[];
    if (name.trim().isEmpty) {
      errors.add(const GymSessionValidationError(
          'session.name', 'Nom de séance obligatoire'));
    }
    final exItems = exerciseItems;
    if (exItems.isEmpty) {
      errors.add(const GymSessionValidationError(
          'session.items', 'La séance doit contenir au moins un exercice'));
      return errors;
    }
    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      if (item is GymSessionExerciseItem) {
        final type = resolveExerciseType(item.exerciseId);
        if (type == null) {
          errors.add(GymSessionValidationError(
              'item[$i].exerciseId',
              'Exercice introuvable (${item.exerciseId})'));
          continue;
        }
        if (item.sets.isEmpty) {
          errors.add(GymSessionValidationError(
              'item[$i].sets', 'Au moins une série requise'));
          continue;
        }
        if (type.hasDuration && item.timedSetStartMode == null) {
          errors.add(GymSessionValidationError(
              'item[$i].timedSetStartMode',
              'Mode de démarrage requis pour les séries en durée'));
        }
        for (var s = 0; s < item.sets.length; s++) {
          final isLast = s == item.sets.length - 1;
          final setErrors = item.sets[s].validate(type, isLast: isLast);
          for (final se in setErrors) {
            errors.add(GymSessionValidationError(
                'item[$i].set[$s].${se.field}', se.message));
          }
        }
      } else if (item is GymSessionRestItem) {
        if (item.durationSeconds < 0) {
          errors.add(GymSessionValidationError(
              'item[$i].durationSeconds', 'Repos négatif interdit'));
        }
      }
    }
    return errors;
  }

  bool isValid(
    GymExerciseType? Function(String exerciseId) resolveExerciseType,
  ) =>
      validate(resolveExerciseType).isEmpty;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'items': items.map((it) => it.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory GymSession.fromJson(Map<String, dynamic> json) {
    return GymSession(
      id: json['id'] as String?,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      items: (json['items'] as List)
          .map((it) => GymSessionItem.fromJson(it as Map<String, dynamic>))
          .toList(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
    );
  }
}
