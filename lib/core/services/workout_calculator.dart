import '../models/set_step.dart';
import '../models/workout_session.dart';

/// Convertit une [WorkoutSession] en liste plate de [SetStep] exécutables.
/// C'est le "compilateur" de la séance : il aplatit les blocs répétés
/// et calcule les repos pour chaque étape.
class WorkoutCalculator {
  /// Génère la liste complète des étapes d'une séance.
  static List<SetStep> buildSteps(WorkoutSession session) {
    final steps = <SetStep>[];
    int globalIndex = 0;

    for (int blockIdx = 0; blockIdx < session.blocks.length; blockIdx++) {
      final block = session.blocks[blockIdx];
      final isLastBlock = blockIdx == session.blocks.length - 1;

      for (int cycle = 0; cycle < block.repeatCount; cycle++) {
        final isLastCycle = cycle == block.repeatCount - 1;

        for (int setIdx = 0; setIdx < block.sequence.length; setIdx++) {
          final reps = block.sequence[setIdx];
          final isLastSetInCycle = setIdx == block.sequence.length - 1;
          final isLastSetInBlock = isLastCycle && isLastSetInCycle;
          final isLastSetInSession = isLastBlock && isLastSetInBlock;

          int rest;
          if (isLastSetInSession) {
            rest = 0;
          } else if (isLastSetInBlock) {
            rest = block.transitionRestSeconds;
          } else if (block.restPerSet != null &&
              setIdx < block.restPerSet!.length) {
            rest = block.restPerSet![setIdx];
          } else {
            rest = block.restStrategy.restForReps(reps);
          }

          steps.add(SetStep(
            index: globalIndex,
            reps: reps,
            restAfterSeconds: rest,
            blockIndex: blockIdx,
            blockName: block.name,
            cycleIndex: cycle,
            isLastInCycle: isLastSetInCycle,
            isLastInBlock: isLastSetInBlock,
            isLastInSession: isLastSetInSession,
          ));

          globalIndex++;
        }
      }
    }

    return steps;
  }

  /// Calcule la durée totale estimée d'une liste d'étapes (repos + effort).
  static int estimateDuration(WorkoutSession session, List<SetStep> steps) {
    int total = 0;
    for (final step in steps) {
      total += session.activeSetDurationSeconds(step.reps);
      total += step.restAfterSeconds;
    }
    return total;
  }

  /// Retourne un résumé statistique d'une séance.
  static WorkoutStats computeStats(WorkoutSession session) {
    final steps = buildSteps(session);
    final totalReps = steps.fold(0, (s, step) => s + step.reps);
    final totalSets = steps.length;
    final estimatedSeconds = estimateDuration(session, steps);
    final targetSeconds = session.targetDurationSeconds;
    final deltaSeconds = estimatedSeconds - targetSeconds;

    return WorkoutStats(
      totalReps: totalReps,
      totalSets: totalSets,
      estimatedDurationSeconds: estimatedSeconds,
      targetDurationSeconds: targetSeconds,
      deltaSeconds: deltaSeconds,
      steps: steps,
    );
  }

  /// Calcule l'index de l'étape courante correspondant à un temps écoulé.
  static int stepAtElapsed(
    List<SetStep> steps,
    int elapsedSeconds, {
    int secondsPerRep = 3,
  }) {
    int elapsed = 0;
    for (int i = 0; i < steps.length; i++) {
      elapsed += (steps[i].reps * secondsPerRep).clamp(6, 60);
      if (elapsed >= elapsedSeconds) return i;
      elapsed += steps[i].restAfterSeconds;
      if (elapsed >= elapsedSeconds) return i;
    }
    return steps.length - 1;
  }
}

class WorkoutStats {
  final int totalReps;
  final int totalSets;
  final int estimatedDurationSeconds;
  final int targetDurationSeconds;
  final int deltaSeconds; // positif = trop long, négatif = plus court que cible
  final List<SetStep> steps;

  const WorkoutStats({
    required this.totalReps,
    required this.totalSets,
    required this.estimatedDurationSeconds,
    required this.targetDurationSeconds,
    required this.deltaSeconds,
    required this.steps,
  });

  String get estimatedDurationLabel {
    final m = estimatedDurationSeconds ~/ 60;
    final s = estimatedDurationSeconds % 60;
    return s == 0 ? '${m}min' : '${m}min ${s}s';
  }

  String get deltaLabel {
    final abs = deltaSeconds.abs();
    final m = abs ~/ 60;
    final s = abs % 60;
    final prefix = deltaSeconds > 0 ? '+' : '-';
    return s == 0 ? '$prefix${m}min' : '$prefix${m}min ${s}s';
  }
}
