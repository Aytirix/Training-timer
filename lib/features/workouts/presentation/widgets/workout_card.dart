import 'package:flutter/material.dart';
import '../../../../core/models/workout_session.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

class WorkoutCard extends StatelessWidget {
  final WorkoutSession session;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onStart;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const WorkoutCard({
    super.key,
    required this.session,
    this.isSelected = false,
    this.onTap,
    this.onStart,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final estimatedMin = session.estimatedDurationSeconds ~/ 60;
    final targetMin = session.targetDurationSeconds ~/ 60;
    final delta = session.durationDeltaSeconds;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accentMuted : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.accent : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── En-tête ──
            Row(
              children: [
                Expanded(
                  child: Text(
                    session.name,
                    style: AppTypography.headingSmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _PopupMenu(
                  onEdit: onEdit,
                  onDelete: onDelete,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Stats ──
            Row(
              children: [
                _StatChip(
                  value: '${session.totalReps}',
                  label: 'reps',
                  color: AppColors.accent,
                ),
                const SizedBox(width: 12),
                _StatChip(
                  value: '${session.totalSets}',
                  label: 'séries',
                  color: AppColors.active,
                ),
                const SizedBox(width: 12),
                _StatChip(
                  value: '~${estimatedMin}min',
                  label: 'estimé',
                  color: AppColors.resting,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Durée cible & delta ──
            Row(
              children: [
                Icon(
                  Icons.flag_outlined,
                  size: 14,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: 4),
                Text(
                  'Cible : ${targetMin}min',
                  style: AppTypography.bodySmall,
                ),
                const SizedBox(width: 8),
                if (delta != 0)
                  Text(
                    delta > 0
                        ? '(+${delta ~/ 60}min)'
                        : '(-${(-delta) ~/ 60}min)',
                    style: AppTypography.bodySmall.copyWith(
                      color: delta > 60
                          ? AppColors.danger
                          : delta < -60
                              ? AppColors.active
                              : AppColors.textMuted,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),

            // ── Blocs ──
            Text(
              session.blocks
                  .map((b) => b.repeatCount > 1
                      ? '${b.sequence.join('-')} x${b.repeatCount}'
                      : b.sequence.join('-'))
                  .join('  •  '),
              style: AppTypography.caption,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            // ── Bouton Démarrer ──
            if (onStart != null) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onStart,
                  icon: const Icon(Icons.play_arrow_rounded, size: 20),
                  label: const Text('Démarrer'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _StatChip({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: AppTypography.labelLarge.copyWith(color: color),
          ),
          Text(
            label,
            style: AppTypography.labelSmall,
          ),
        ],
      ),
    );
  }
}

class _PopupMenu extends StatelessWidget {
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _PopupMenu({this.onEdit, this.onDelete});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: AppColors.textMuted),
      color: AppColors.surfaceElevated,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      itemBuilder: (_) => [
        if (onEdit != null)
          const PopupMenuItem(
            value: 'edit',
            child: Row(
              children: [
                Icon(Icons.edit_outlined, size: 18),
                SizedBox(width: 12),
                Text('Modifier'),
              ],
            ),
          ),
        if (onDelete != null)
          PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                Icon(Icons.delete_outline, size: 18, color: AppColors.danger),
                const SizedBox(width: 12),
                Text(
                  'Supprimer',
                  style: TextStyle(color: AppColors.danger),
                ),
              ],
            ),
          ),
      ],
      onSelected: (value) {
        if (value == 'edit') onEdit?.call();
        if (value == 'delete') onDelete?.call();
      },
    );
  }
}
