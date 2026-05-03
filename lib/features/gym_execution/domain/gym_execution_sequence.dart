import '../../../core/models/gym/gym_exercise.dart';
import '../../../core/models/gym/gym_session.dart';
import '../../../core/models/gym/gym_session_item.dart';
import '../../../core/models/gym/gym_set.dart';

/// Type d'étape dans la séquence d'exécution.
enum GymStepKind {
  /// Une série à réaliser.
  set,

  /// Repos après une série (intra-exercice).
  restAfterSet,

  /// Repos entre deux exercices.
  restBetweenExercises,
}

/// Une étape de la séquence d'exécution d'une séance.
class GymExecutionStep {
  final GymStepKind kind;

  /// Index de l'exercice (parmi les items exercices) — null pour repos
  /// entre exercices.
  final int? exerciseIndex;
  final String? exerciseId;
  final GymExerciseType? exerciseType;
  final TimedSetStartMode? timedSetStartMode;

  /// Index de la série dans l'exercice (1-based pour affichage : on stocke 0-based).
  final int? setIndex;
  final int? totalSets;
  final GymSet? set;

  /// Pour les repos.
  final int? restSeconds;

  const GymExecutionStep({
    required this.kind,
    this.exerciseIndex,
    this.exerciseId,
    this.exerciseType,
    this.timedSetStartMode,
    this.setIndex,
    this.totalSets,
    this.set,
    this.restSeconds,
  });
}

/// Construit la séquence d'exécution d'une séance valide.
class GymExecutionSequenceBuilder {
  final GymSession session;
  final GymExerciseType? Function(String exerciseId) resolveType;

  GymExecutionSequenceBuilder({
    required this.session,
    required this.resolveType,
  });

  List<GymExecutionStep> build() {
    final steps = <GymExecutionStep>[];
    final exItems = session.exerciseItems;
    int exerciseIndex = 0;

    for (var i = 0; i < session.items.length; i++) {
      final item = session.items[i];
      if (item is GymSessionExerciseItem) {
        final type = resolveType(item.exerciseId);
        for (var s = 0; s < item.sets.length; s++) {
          final isLastSet = s == item.sets.length - 1;
          steps.add(GymExecutionStep(
            kind: GymStepKind.set,
            exerciseIndex: exerciseIndex,
            exerciseId: item.exerciseId,
            exerciseType: type,
            timedSetStartMode: item.timedSetStartMode,
            setIndex: s,
            totalSets: item.sets.length,
            set: item.sets[s],
          ));
          // repos entre séries (sauf dernière série)
          if (!isLastSet) {
            final rest = item.sets[s].restAfterSetSeconds ?? 0;
            if (rest > 0) {
              steps.add(GymExecutionStep(
                kind: GymStepKind.restAfterSet,
                exerciseIndex: exerciseIndex,
                exerciseId: item.exerciseId,
                exerciseType: type,
                restSeconds: rest,
              ));
            }
          }
        }
        exerciseIndex++;
      } else if (item is GymSessionRestItem) {
        // Repos entre exercices : on ignore si vide ou si c'est avant le 1er exercice / après le dernier
        if (item.durationSeconds <= 0) continue;
        // Doit être suivi d'au moins un autre exercice pour avoir du sens
        bool hasNextExercise = false;
        for (var j = i + 1; j < session.items.length; j++) {
          if (session.items[j] is GymSessionExerciseItem) {
            hasNextExercise = true;
            break;
          }
        }
        if (!hasNextExercise) continue;
        steps.add(GymExecutionStep(
          kind: GymStepKind.restBetweenExercises,
          restSeconds: item.durationSeconds,
        ));
      }
    }

    // évite warning sur exItems si vide
    if (exItems.isEmpty) return [];

    return steps;
  }
}
