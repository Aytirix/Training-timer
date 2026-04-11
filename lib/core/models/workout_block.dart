import 'package:uuid/uuid.dart';
import 'rest_strategy.dart';

enum BlockType { pyramid, sequence, custom }

const Object _unsetRestPerSet = Object();

/// Un bloc de travail : séquence de séries, éventuellement répétée.
class WorkoutBlock {
  final String id;
  final String name;
  final BlockType type;

  /// La séquence brute de reps, ex: [1,2,3,4,3,2,1] ou [2,4,6,8,6,4,2]
  final List<int> sequence;

  /// Nombre de répétitions du bloc complet
  final int repeatCount;

  /// Repos entre ce bloc et le suivant (uniquement si suivi d'un autre bloc)
  final int transitionRestSeconds;

  final RestStrategy restStrategy;

  /// Repos explicites par position dans la séquence (optionnel).
  /// Quand défini, remplace restStrategy pour chaque index.
  /// Longueur attendue = sequence.length.
  /// Le dernier élément sert au repos entre deux cycles si repeatCount > 1.
  /// Sinon, il est ignoré au profit de la transition/fin de séance.
  final List<int>? restPerSet;

  WorkoutBlock({
    String? id,
    required this.name,
    this.type = BlockType.sequence,
    required this.sequence,
    this.repeatCount = 1,
    this.transitionRestSeconds = 120,
    this.restStrategy = const RestStrategy(),
    this.restPerSet,
  }) : id = id ?? const Uuid().v4();

  /// Total des reps pour ce bloc (toutes répétitions comprises)
  int get totalReps => sequence.fold(0, (s, r) => s + r) * repeatCount;

  /// Total des séries pour ce bloc
  int get totalSets => sequence.length * repeatCount;

  bool get hasCustomRestPerSet => restPerSet != null;

  /// Durée estimée du bloc en secondes (repos inclus sauf après la dernière série)
  int get estimatedDurationSeconds {
    int total = 0;
    for (int cycle = 0; cycle < repeatCount; cycle++) {
      for (int i = 0; i < sequence.length; i++) {
        final reps = sequence[i];
        final isLast = cycle == repeatCount - 1 && i == sequence.length - 1;
        // temps approximatif pour faire les reps (~2s/rep + 1s overhead)
        total += reps * 2 + 1;
        if (!isLast) {
          if (restPerSet != null && i < restPerSet!.length) {
            total += restPerSet![i];
          } else {
            total += restStrategy.restForReps(reps);
          }
        }
      }
    }
    return total;
  }

  WorkoutBlock copyWith({
    String? id,
    String? name,
    BlockType? type,
    List<int>? sequence,
    int? repeatCount,
    int? transitionRestSeconds,
    RestStrategy? restStrategy,
    Object? restPerSet = _unsetRestPerSet,
  }) {
    return WorkoutBlock(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      sequence: sequence ?? List.unmodifiable(this.sequence),
      repeatCount: repeatCount ?? this.repeatCount,
      transitionRestSeconds:
          transitionRestSeconds ?? this.transitionRestSeconds,
      restStrategy: restStrategy ?? this.restStrategy,
      restPerSet: identical(restPerSet, _unsetRestPerSet)
          ? this.restPerSet
          : restPerSet as List<int>?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type.name,
        'sequence': sequence,
        'repeatCount': repeatCount,
        'transitionRestSeconds': transitionRestSeconds,
        'restStrategy': restStrategy.toJson(),
        if (restPerSet != null) 'restPerSet': restPerSet,
      };

  factory WorkoutBlock.fromJson(Map<String, dynamic> json) => WorkoutBlock(
        id: json['id'] as String?,
        name: json['name'] as String,
        type: BlockType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => BlockType.sequence,
        ),
        sequence: List<int>.from(json['sequence'] as List),
        repeatCount: json['repeatCount'] as int? ?? 1,
        transitionRestSeconds: json['transitionRestSeconds'] as int? ?? 120,
        restStrategy: json['restStrategy'] != null
            ? RestStrategy.fromJson(
                json['restStrategy'] as Map<String, dynamic>)
            : const RestStrategy(),
        restPerSet: json['restPerSet'] != null
            ? List<int>.from(json['restPerSet'] as List)
            : null,
      );

  @override
  String toString() =>
      'WorkoutBlock($name, seq=$sequence, x$repeatCount, ${totalReps}reps)';
}
