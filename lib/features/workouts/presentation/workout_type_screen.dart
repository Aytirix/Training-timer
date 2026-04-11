import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

class WorkoutTypeScreen extends StatelessWidget {
  const WorkoutTypeScreen({super.key});

  void _goBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.goHome();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => _goBack(context),
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Retour',
        ),
        title: const Text('Type de séance'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Choisissez la structure à créer',
            style: AppTypography.headingLarge,
          ),
          const SizedBox(height: 8),
          const Text(
            'La pyramide est prête. Les autres formats arriveront ensuite.',
            style: AppTypography.bodyMedium,
          ),
          const SizedBox(height: 24),
          _WorkoutTypeCard(
            title: 'Pyramide',
            subtitle:
                'Créez une séance de tractions en montée, descente ou mixte.',
            icon: Icons.change_history_rounded,
            accentColor: AppColors.accent,
            isAvailable: true,
            onTap: () => context.goNewPyramidWorkout(),
          ),
          const SizedBox(height: 14),
          const _WorkoutTypeCard(
            title: 'Séance libre',
            subtitle: 'Bientôt disponible pour composer d’autres structures.',
            icon: Icons.dashboard_customize_outlined,
            accentColor: AppColors.paused,
            isAvailable: false,
          ),
          const SizedBox(height: 14),
          const _WorkoutTypeCard(
            title: 'Intervalles',
            subtitle:
                'Bientôt disponible pour les formats par temps ou rounds.',
            icon: Icons.timer_outlined,
            accentColor: AppColors.resting,
            isAvailable: false,
          ),
        ],
      ),
    );
  }
}

class _WorkoutTypeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final bool isAvailable;
  final VoidCallback? onTap;

  const _WorkoutTypeCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.isAvailable,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: isAvailable ? 1 : 0.58,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isAvailable ? onTap : null,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isAvailable
                    ? accentColor.withValues(alpha: 0.5)
                    : AppColors.border,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: accentColor),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child:
                                Text(title, style: AppTypography.headingSmall),
                          ),
                          if (!isAvailable)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceElevated,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: const Text(
                                'Bientôt',
                                style: AppTypography.caption,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(subtitle, style: AppTypography.bodyMedium),
                    ],
                  ),
                ),
                if (isAvailable) ...[
                  const SizedBox(width: 12),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    color: AppColors.textSecondary,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
