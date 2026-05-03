import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/gym/gym_session.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../app/router.dart';
import '../domain/gym_provider.dart';
import '../data/gym_session_json_codec.dart';
import 'exercise_library_screen.dart';
import 'gym_json_import_screen.dart';
import 'gym_session_editor_screen.dart';

class GymSessionsScreen extends ConsumerWidget {
  const GymSessionsScreen({super.key});

  Future<void> _openEditor(BuildContext context, WidgetRef ref,
      {String? id}) async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => GymSessionEditorScreen(sessionId: id),
    ));
    // Le pop de l'éditeur peut revenir sur un écran conservé par l'onglet.
    // On relit le stockage pour éviter une liste visuellement vide/stale.
    ref.read(gymSessionsProvider.notifier).refresh();
  }

  void _exportSession(BuildContext context, GymSession session, WidgetRef ref) {
    final exercises = ref
        .read(gymExercisesProvider)
        .exercises
        .where((e) => session.referencedExerciseIds.contains(e.id))
        .toList();
    final json = GymSessionJsonCodec.encode(session, exercises);
    Clipboard.setData(ClipboardData(text: json));
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        title: const Text('Export JSON'),
        content: SizedBox(
          width: 600,
          child: SingleChildScrollView(
            child: SelectableText(
              json,
              style: AppTypography.bodySmall.copyWith(fontFamily: 'monospace'),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('JSON copié dans le presse-papiers')),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, GymSession session) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        title: const Text('Supprimer la séance ?'),
        content: Text('« ${session.name} » sera supprimée définitivement.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer',
                style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(gymSessionsProvider.notifier).delete(session.id);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gymSessionsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 8, 8),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Séances de salle',
                      style: AppTypography.headingMedium,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Bibliothèque exercices',
                    icon: const Icon(Icons.fitness_center),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const ExerciseLibraryScreen()),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Importer JSON',
                    icon: const Icon(Icons.file_download),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const GymJsonImportScreen()),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Text(
                '${state.sessions.length} séance${state.sessions.length > 1 ? 's' : ''}',
                style: AppTypography.bodyMedium,
              ),
            ),
            Expanded(
              child: state.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : state.sessions.isEmpty
                      ? _EmptyState(onCreate: () => _openEditor(context, ref))
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                          itemCount: state.sessions.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (ctx, i) {
                            final s = state.sessions[i];
                            return _SessionCard(
                              session: s,
                              onOpen: () => _openEditor(ctx, ref, id: s.id),
                              onStart: () => ctx.goActiveGymSession(s.id),
                              onDuplicate: () => ref
                                  .read(gymSessionsProvider.notifier)
                                  .duplicate(s),
                              onDelete: () => _confirmDelete(ctx, ref, s),
                              onExport: () => _exportSession(ctx, s, ref),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(context, ref),
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.textOnAccent,
        icon: const Icon(Icons.add),
        label: const Text('Nouvelle séance'),
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  final GymSession session;
  final VoidCallback onOpen;
  final VoidCallback onStart;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;
  final VoidCallback onExport;

  const _SessionCard({
    required this.session,
    required this.onOpen,
    required this.onStart,
    required this.onDuplicate,
    required this.onDelete,
    required this.onExport,
  });

  @override
  Widget build(BuildContext context) {
    final title =
        session.name.trim().isEmpty ? 'Séance sans nom' : session.name;
    final exerciseCount = session.exerciseItems.length;
    final setCount = session.exerciseItems
        .fold<int>(0, (sum, item) => sum + item.sets.length);

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderActive),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: AppTypography.headingSmall,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (session.description.trim().isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            session.description,
                            style: AppTypography.bodyMedium,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    tooltip: 'Actions séance',
                    color: AppColors.surfaceElevated,
                    icon: const Icon(Icons.more_vert,
                        color: AppColors.textSecondary),
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          onOpen();
                          break;
                        case 'duplicate':
                          onDuplicate();
                          break;
                        case 'export':
                          onExport();
                          break;
                        case 'delete':
                          onDelete();
                          break;
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('Modifier')),
                      PopupMenuItem(
                          value: 'duplicate', child: Text('Dupliquer')),
                      PopupMenuItem(
                          value: 'export', child: Text('Exporter JSON')),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text('Supprimer',
                            style: TextStyle(color: AppColors.danger)),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  _SessionStat(
                    icon: Icons.fitness_center,
                    label:
                        '$exerciseCount exercice${exerciseCount > 1 ? 's' : ''}',
                  ),
                  _SessionStat(
                    icon: Icons.layers,
                    label: '$setCount série${setCount > 1 ? 's' : ''}',
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onStart,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Lancer'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    tooltip: 'Modifier',
                    onPressed: onOpen,
                    icon: const Icon(Icons.edit_outlined),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SessionStat extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SessionStat({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(label, style: AppTypography.bodySmall),
      ],
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
            const Icon(Icons.list_alt_rounded,
                size: 64, color: AppColors.textMuted),
            const SizedBox(height: 24),
            const Text('Aucune séance', style: AppTypography.headingMedium),
            const SizedBox(height: 8),
            const Text(
              'Crée ta première séance de salle ou importe un JSON.',
              style: AppTypography.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 12,
              children: [
                ElevatedButton.icon(
                  onPressed: onCreate,
                  icon: const Icon(Icons.add),
                  label: const Text('Créer'),
                ),
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const GymJsonImportScreen()),
                  ),
                  icon: const Icon(Icons.file_download),
                  label: const Text('Importer'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
