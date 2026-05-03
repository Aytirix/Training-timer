import 'package:uuid/uuid.dart';
import 'gym_set.dart';

/// Mode de démarrage des séries en durée.
enum TimedSetStartMode {
  manual,
  automatic;

  String get id => this == TimedSetStartMode.manual ? 'manual' : 'automatic';

  static TimedSetStartMode fromId(String? id, {TimedSetStartMode? fallback}) {
    if (id == 'manual') return TimedSetStartMode.manual;
    if (id == 'automatic') return TimedSetStartMode.automatic;
    return fallback ?? TimedSetStartMode.manual;
  }
}

/// Item d'une séance : soit un exercice configuré, soit un repos entre exercices.
sealed class GymSessionItem {
  String get id;
  String get kind;
  Map<String, dynamic> toJson();

  const GymSessionItem();

  static GymSessionItem fromJson(Map<String, dynamic> json) {
    final kind = json['kind'] as String?;
    if (kind == 'exercise') {
      return GymSessionExerciseItem.fromJson(json);
    }
    if (kind == 'rest') {
      return GymSessionRestItem.fromJson(json);
    }
    throw FormatException('Item de séance inconnu: $kind');
  }
}

/// Exercice configuré dans une séance (référence à un exercice global).
class GymSessionExerciseItem extends GymSessionItem {
  @override
  final String id;

  /// ID interne d'un exercice global.
  final String exerciseId;
  final List<GymSet> sets;

  /// Pour les types en durée : `manual` ou `automatic`.
  /// Null si non applicable au type.
  final TimedSetStartMode? timedSetStartMode;

  GymSessionExerciseItem({
    String? id,
    required this.exerciseId,
    required this.sets,
    this.timedSetStartMode,
  }) : id = id ?? const Uuid().v4();

  @override
  String get kind => 'exercise';

  GymSessionExerciseItem copyWith({
    String? id,
    String? exerciseId,
    List<GymSet>? sets,
    TimedSetStartMode? timedSetStartMode,
    bool clearTimedMode = false,
  }) {
    return GymSessionExerciseItem(
      id: id ?? this.id,
      exerciseId: exerciseId ?? this.exerciseId,
      sets: sets ?? this.sets,
      timedSetStartMode: clearTimedMode
          ? null
          : (timedSetStartMode ?? this.timedSetStartMode),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': kind,
        'exerciseId': exerciseId,
        'timedSetStartMode': timedSetStartMode?.id,
        'sets': sets.map((s) => s.toJson()).toList(),
      };

  factory GymSessionExerciseItem.fromJson(Map<String, dynamic> json) {
    return GymSessionExerciseItem(
      id: json['id'] as String?,
      exerciseId: json['exerciseId'] as String,
      sets: (json['sets'] as List)
          .map((e) => GymSet.fromJson(e as Map<String, dynamic>))
          .toList(),
      timedSetStartMode: json['timedSetStartMode'] == null
          ? null
          : TimedSetStartMode.fromId(json['timedSetStartMode'] as String?),
    );
  }
}

/// Repos entre exercices.
class GymSessionRestItem extends GymSessionItem {
  @override
  final String id;
  final int durationSeconds;

  GymSessionRestItem({
    String? id,
    required this.durationSeconds,
  }) : id = id ?? const Uuid().v4();

  @override
  String get kind => 'rest';

  GymSessionRestItem copyWith({String? id, int? durationSeconds}) =>
      GymSessionRestItem(
        id: id ?? this.id,
        durationSeconds: durationSeconds ?? this.durationSeconds,
      );

  /// Repos vide : passe directement à la suite.
  bool get isEmpty => durationSeconds <= 0;

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': kind,
        'durationSeconds': durationSeconds,
      };

  factory GymSessionRestItem.fromJson(Map<String, dynamic> json) {
    return GymSessionRestItem(
      id: json['id'] as String?,
      durationSeconds: json['durationSeconds'] as int? ?? 0,
    );
  }
}
