import 'package:uuid/uuid.dart';
import 'workout_block.dart';

/// Une séance complète composée de blocs.
class WorkoutSession {
  final String id;
  final String name;

  /// Durée cible en secondes (ex: 1800 = 30 min)
  final int targetDurationSeconds;

  /// Échauffement avant la première série (en secondes)
  final int warmupSeconds;

  /// Temps moyen alloué à une traction pour le chrono auto et les estimations.
  final int secondsPerRep;

  final bool voiceEnabled;
  final String? selectedVoiceId;
  final String? selectedVoiceName;

  /// Jalons d'annonce du temps restant (en secondes)
  /// ex: [900, 600, 300, 60] = 15min, 10min, 5min, 1min
  final List<int> remainingTimeAnnouncements;

  /// Quand activé (défaut), le chrono de série tourne automatiquement
  /// et la série passe en repos sans attendre "Série terminée".
  /// Si l'utilisateur tarde à appuyer, son temps de repos est rogné.
  final bool autoChain;

  final List<WorkoutBlock> blocks;
  final DateTime createdAt;

  WorkoutSession({
    String? id,
    required this.name,
    this.targetDurationSeconds = 1800,
    this.warmupSeconds = 0,
    this.secondsPerRep = 3,
    this.voiceEnabled = false,
    this.selectedVoiceId,
    this.selectedVoiceName,
    this.remainingTimeAnnouncements = const [900, 600, 300, 60],
    this.autoChain = true,
    required this.blocks,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  // ───────── Computed ─────────

  int get totalReps => blocks.fold(0, (s, b) => s + b.totalReps);

  int get totalSets => blocks.fold(0, (s, b) => s + b.totalSets);

  int get normalizedSecondsPerRep => secondsPerRep.clamp(1, 10);

  int activeSetDurationSeconds(int reps) =>
      (reps * normalizedSecondsPerRep).clamp(6, 60);

  int get estimatedDurationSeconds {
    int total = 0;

    for (int blockIdx = 0; blockIdx < blocks.length; blockIdx++) {
      final block = blocks[blockIdx];
      final isLastBlock = blockIdx == blocks.length - 1;

      for (int cycle = 0; cycle < block.repeatCount; cycle++) {
        final isLastCycle = cycle == block.repeatCount - 1;

        for (int setIdx = 0; setIdx < block.sequence.length; setIdx++) {
          final reps = block.sequence[setIdx];
          final isLastSetInCycle = setIdx == block.sequence.length - 1;
          final isLastSetInBlock = isLastCycle && isLastSetInCycle;
          final isLastSetInSession = isLastBlock && isLastSetInBlock;

          total += activeSetDurationSeconds(reps);

          if (isLastSetInSession) continue;

          if (isLastSetInBlock) {
            total += block.transitionRestSeconds;
          } else if (block.restPerSet != null &&
              setIdx < block.restPerSet!.length) {
            total += block.restPerSet![setIdx];
          } else {
            total += block.restStrategy.restForReps(reps);
          }
        }
      }
    }

    return total;
  }

  /// Différence entre durée estimée et durée cible (positif = trop long)
  int get durationDeltaSeconds =>
      estimatedDurationSeconds - targetDurationSeconds;

  // ───────── Copy / Serialization ─────────

  WorkoutSession copyWith({
    String? id,
    String? name,
    int? targetDurationSeconds,
    int? warmupSeconds,
    int? secondsPerRep,
    bool? voiceEnabled,
    String? selectedVoiceId,
    String? selectedVoiceName,
    List<int>? remainingTimeAnnouncements,
    bool? autoChain,
    List<WorkoutBlock>? blocks,
    DateTime? createdAt,
  }) {
    return WorkoutSession(
      id: id ?? this.id,
      name: name ?? this.name,
      targetDurationSeconds:
          targetDurationSeconds ?? this.targetDurationSeconds,
      warmupSeconds: warmupSeconds ?? this.warmupSeconds,
      secondsPerRep: secondsPerRep ?? this.secondsPerRep,
      voiceEnabled: voiceEnabled ?? this.voiceEnabled,
      selectedVoiceId: selectedVoiceId ?? this.selectedVoiceId,
      selectedVoiceName: selectedVoiceName ?? this.selectedVoiceName,
      remainingTimeAnnouncements:
          remainingTimeAnnouncements ?? this.remainingTimeAnnouncements,
      autoChain: autoChain ?? this.autoChain,
      blocks: blocks ?? this.blocks,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Retourne une copie avec la voix désactivée (si la voix sélectionnée n'est plus disponible)
  WorkoutSession withVoiceCleared() => copyWith(
        voiceEnabled: false,
        selectedVoiceId: null,
        selectedVoiceName: null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'targetDurationSeconds': targetDurationSeconds,
        'warmupSeconds': warmupSeconds,
        'secondsPerRep': normalizedSecondsPerRep,
        'voiceEnabled': voiceEnabled,
        'selectedVoiceId': selectedVoiceId,
        'selectedVoiceName': selectedVoiceName,
        'remainingTimeAnnouncements': remainingTimeAnnouncements,
        'autoChain': autoChain,
        'blocks': blocks.map((b) => b.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
      };

  factory WorkoutSession.fromJson(Map<String, dynamic> json) => WorkoutSession(
        id: json['id'] as String?,
        name: json['name'] as String,
        targetDurationSeconds: json['targetDurationSeconds'] as int? ?? 1800,
        warmupSeconds: json['warmupSeconds'] as int? ?? 0,
        secondsPerRep: (json['secondsPerRep'] as int? ?? 3).clamp(1, 10),
        voiceEnabled: json['voiceEnabled'] as bool? ?? false,
        selectedVoiceId: json['selectedVoiceId'] as String?,
        selectedVoiceName: json['selectedVoiceName'] as String?,
        remainingTimeAnnouncements: json['remainingTimeAnnouncements'] != null
            ? List<int>.from(json['remainingTimeAnnouncements'] as List)
            : const [900, 600, 300, 60],
        autoChain: json['autoChain'] as bool? ?? true,
        blocks: (json['blocks'] as List)
            .map((b) => WorkoutBlock.fromJson(b as Map<String, dynamic>))
            .toList(),
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'] as String)
            : null,
      );

  @override
  String toString() =>
      'WorkoutSession($name, ${totalReps}reps, ${totalSets}sets, ~${estimatedDurationSeconds ~/ 60}min)';
}
