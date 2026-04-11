/// Une étape exécutable dans la séance : une série + son repos associé.
class SetStep {
  final int index; // index global dans la session aplanie
  final int reps;
  final int restAfterSeconds; // 0 pour la dernière étape
  final int blockIndex;
  final String blockName;
  final int cycleIndex; // numéro du cycle (répétition du bloc)
  final bool isLastInCycle;
  final bool isLastInBlock;
  final bool isLastInSession;

  const SetStep({
    required this.index,
    required this.reps,
    required this.restAfterSeconds,
    required this.blockIndex,
    required this.blockName,
    required this.cycleIndex,
    this.isLastInCycle = false,
    this.isLastInBlock = false,
    this.isLastInSession = false,
  });

  SetStep copyWith({
    int? index,
    int? reps,
    int? restAfterSeconds,
    int? blockIndex,
    String? blockName,
    int? cycleIndex,
    bool? isLastInCycle,
    bool? isLastInBlock,
    bool? isLastInSession,
  }) {
    return SetStep(
      index: index ?? this.index,
      reps: reps ?? this.reps,
      restAfterSeconds: restAfterSeconds ?? this.restAfterSeconds,
      blockIndex: blockIndex ?? this.blockIndex,
      blockName: blockName ?? this.blockName,
      cycleIndex: cycleIndex ?? this.cycleIndex,
      isLastInCycle: isLastInCycle ?? this.isLastInCycle,
      isLastInBlock: isLastInBlock ?? this.isLastInBlock,
      isLastInSession: isLastInSession ?? this.isLastInSession,
    );
  }

  @override
  String toString() =>
      'SetStep(#$index block=$blockIndex cycle=$cycleIndex reps=$reps rest=${restAfterSeconds}s)';
}
