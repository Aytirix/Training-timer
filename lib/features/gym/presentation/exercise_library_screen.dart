import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/gym/gym_exercise.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../domain/gym_provider.dart';
import 'exercise_editor_screen.dart';
import 'widgets/exercise_card.dart';

/// Écran qui liste les exercices globaux et permet de les gérer.
class ExerciseLibraryScreen extends ConsumerStatefulWidget {
  /// Si non null, l'écran fonctionne en mode "sélection" : retourner un
  /// [GymExercise] via Navigator.pop.
  final bool selectionMode;

  const ExerciseLibraryScreen({super.key, this.selectionMode = false});

  @override
  ConsumerState<ExerciseLibraryScreen> createState() =>
      _ExerciseLibraryScreenState();
}

class _ExerciseLibraryScreenState
    extends ConsumerState<ExerciseLibraryScreen> {
  String _query = '';

  Future<void> _openEditor({String? id}) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ExerciseEditorScreen(exerciseId: id),
      ),
    );
  }

  Future<void> _confirmDelete(GymExercise exercise) async {
    final notifier = ref.read(gymExercisesProvider.notifier);
    final impacted = notifier.findSessionsUsing(exercise.id);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        title: const Text('Supprimer l\'exercice ?'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('« ${exercise.name} » sera supprimé.',
                  style: AppTypography.bodyMedium),
              if (impacted.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'Cet exercice sera retiré de ${impacted.length} séance${impacted.length > 1 ? 's' : ''} :',
                  style: AppTypography.bodyMedium
                      .copyWith(color: AppColors.danger),
                ),
                const SizedBox(height: 4),
                ...impacted.map((s) => Padding(
                      padding: const EdgeInsets.only(left: 8, top: 2),
                      child: Text('• ${s.name}',
                          style: AppTypography.bodySmall),
                    )),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer',
                style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(gymExercisesProvider.notifier).delete(exercise.id);
      ref.read(gymSessionsProvider.notifier).refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gymExercisesProvider);
    final filtered = _query.isEmpty
        ? state.exercises
        : state.exercises
            .where((e) =>
                e.name.toLowerCase().contains(_query.toLowerCase()))
            .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text(widget.selectionMode
            ? 'Choisir un exercice'
            : 'Exercices'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Rechercher…',
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? _EmptyState(onCreate: () => _openEditor())
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 12),
                        itemBuilder: (_, i) {
                          final ex = filtered[i];
                          return ExerciseCard(
                            exercise: ex,
                            onTap: widget.selectionMode
                                ? () => Navigator.pop(context, ex)
                                : () => _openEditor(id: ex.id),
                            onEdit: () => _openEditor(id: ex.id),
                            onDelete: () => _confirmDelete(ex),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(),
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.textOnAccent,
        icon: const Icon(Icons.add),
        label: const Text('Nouvel exercice'),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onCreate;
  const _EmptyState({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.fitness_center,
                size: 64, color: AppColors.textMuted),
            const SizedBox(height: 24),
            const Text('Aucun exercice', style: AppTypography.headingMedium),
            const SizedBox(height: 8),
            const Text(
              'Crée ton premier exercice global pour le réutiliser dans tes séances.',
              style: AppTypography.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: onCreate,
              child: const Text('Créer un exercice'),
            ),
          ],
        ),
      ),
    );
  }
}
