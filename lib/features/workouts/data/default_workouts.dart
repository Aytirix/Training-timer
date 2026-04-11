import '../../../core/models/workout_block.dart';
import '../../../core/models/workout_session.dart';

/// Séance préchargée de référence.
/// Structure :
///   Bloc 1 : [1,2,3,4,3,2,1] x3  → 48 reps | ~9 min
///   Bloc 2 : [2,4,6,8,6,4,2] x1  → 32 reps | ~11 min
///   Bloc 3 : [2,3,5,3,2] x2      → 30 reps | ~10 min
///   Total  : 110 reps | cible 30 min
abstract class DefaultWorkouts {
  static WorkoutSession get tractions110 {
    // Pour les blocs répétés, le dernier repos de restPerSet est utilisé
    // entre deux cycles. Le dernier cycle utilise transitionRestSeconds.
    final block1 = WorkoutBlock(
      id: 'default-block-a',
      name: 'Bloc 1 - 1-2-3-4-3-2-1',
      type: BlockType.pyramid,
      sequence: const [1, 2, 3, 4, 3, 2, 1],
      repeatCount: 3,
      transitionRestSeconds: 35,
      //                       1→  2→  3→  4→  3→  2→  1→
      restPerSet: const [10, 15, 20, 25, 20, 15, 35],
    );

    final block2 = WorkoutBlock(
      id: 'default-block-b',
      name: 'Bloc 2 - 2-4-6-8-6-4-2',
      type: BlockType.pyramid,
      sequence: const [2, 4, 6, 8, 6, 4, 2],
      repeatCount: 1,
      transitionRestSeconds: 150,
      //                       2→  4→  6→  8→  6→  4→  (2→bloc suivant)
      restPerSet: const [35, 55, 75, 105, 90, 75],
    );

    final block3 = WorkoutBlock(
      id: 'default-block-c',
      name: 'Bloc 3 - 2-3-5-3-2',
      type: BlockType.custom,
      sequence: const [2, 3, 5, 3, 2],
      repeatCount: 2,
      transitionRestSeconds: 60,
      //                       2→  3→  5→  3→  2→
      restPerSet: const [40, 45, 70, 45, 60],
    );

    return WorkoutSession(
      id: 'default-110',
      name: '110 tractions / 30 min',
      targetDurationSeconds: 1800, // 30 minutes
      warmupSeconds: 0,
      voiceEnabled: false,
      remainingTimeAnnouncements: const [900, 600, 300, 60],
      blocks: [block1, block2, block3],
      createdAt: DateTime(2024, 1, 1),
    );
  }

  /// Retourne toutes les séances par défaut.
  static List<WorkoutSession> get all => [tractions110];
}
