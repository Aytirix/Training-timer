import 'package:flutter/material.dart';
import '../../../../core/models/gym/gym_session.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

class GymSessionCard extends StatelessWidget {
  final GymSession session;
  final VoidCallback? onTap;
  final VoidCallback? onStart;
  final VoidCallback? onEdit;
  final VoidCallback? onDuplicate;
  final VoidCallback? onDelete;
  final VoidCallback? onExport;

  const GymSessionCard({
    super.key,
    required this.session,
    this.onTap,
    this.onStart,
    this.onEdit,
    this.onDuplicate,
    this.onDelete,
    this.onExport,
  });

  @override
  Widget build(BuildContext context) {
    final title =
        session.name.trim().isEmpty ? 'Séance sans nom' : session.name;
    final exerciseCount = session.exerciseItems.length;
    return InkWell(
      onTap: onTap ?? onEdit,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.accentDim, width: 1.2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(title,
                      style: AppTypography.headingSmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert,
                      color: AppColors.textSecondary),
                  color: AppColors.surfaceElevated,
                  onSelected: (v) {
                    switch (v) {
                      case 'edit':
                        onEdit?.call();
                        break;
                      case 'dup':
                        onDuplicate?.call();
                        break;
                      case 'del':
                        onDelete?.call();
                        break;
                      case 'export':
                        onExport?.call();
                        break;
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'edit', child: Text('Modifier')),
                    const PopupMenuItem(value: 'dup', child: Text('Dupliquer')),
                    const PopupMenuItem(
                        value: 'export', child: Text('Exporter JSON')),
                    const PopupMenuItem(
                      value: 'del',
                      child: Text('Supprimer',
                          style: TextStyle(color: AppColors.danger)),
                    ),
                  ],
                ),
              ],
            ),
            if (session.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(session.description,
                  style: AppTypography.bodyMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                _Stat(
                  icon: Icons.fitness_center,
                  label:
                      '$exerciseCount exercice${exerciseCount > 1 ? 's' : ''}',
                ),
                const SizedBox(width: 16),
                _Stat(
                  icon: Icons.layers,
                  label:
                      '${session.exerciseItems.fold<int>(0, (s, e) => s + e.sets.length)} séries',
                ),
              ],
            ),
            const SizedBox(height: 16),
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
                OutlinedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Modifier'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Stat({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(label, style: AppTypography.bodySmall),
      ],
    );
  }
}
