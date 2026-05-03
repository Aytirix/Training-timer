import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../domain/workout_provider.dart';
import '../../timer/application/timer_provider.dart';
import '../../voice/application/voice_provider.dart';
import '../../../app/router.dart';
import 'widgets/workout_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String? _selectedId;
  Timer? _voiceBannerTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkVoiceConfig();
      // Pré-sélectionne la première session
      final sessions = ref.read(workoutProvider).sessions;
      if (sessions.isNotEmpty) {
        setState(() => _selectedId = sessions.first.id);
      }
    });
  }

  Future<void> _checkVoiceConfig() async {
    final voice = ref.read(voiceProvider.notifier);
    if (voice.isConfigured) return;

    await voice.loadVoices();
    if (!mounted || voice.isConfigured) return;

    // Propose la configuration voix uniquement si l'auto-sélection a échoué.
    _voiceBannerTimer = Timer(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      _showVoiceBanner();
    });
  }

  @override
  void dispose() {
    _voiceBannerTimer?.cancel();
    super.dispose();
  }

  void _showVoiceBanner() {
    ScaffoldMessenger.of(context).showMaterialBanner(
      MaterialBanner(
        backgroundColor: AppColors.surfaceVariant,
        content: const Text(
          'Configurer une voix pour les annonces vocales (optionnel)',
          style: AppTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
              ref.read(voiceProvider.notifier).markConfigured();
            },
            child: const Text('Plus tard'),
          ),
          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
              ref.read(voiceProvider.notifier).markConfigured();
              context.goVoice();
            },
            child: const Text('Configurer'),
          ),
        ],
      ),
    );
  }

  Future<void> _startSession(String id) async {
    final session =
        ref.read(workoutProvider).sessions.firstWhere((s) => s.id == id);

    // Applique les paramètres voix courants à la session
    final voiceState = ref.read(voiceProvider);
    final sessionWithVoice = session.copyWith(
      voiceEnabled: voiceState.voiceEnabled,
      selectedVoiceId: voiceState.selectedVoice?.key,
      selectedVoiceName: voiceState.selectedVoice?.name,
    );

    await ref.read(timerProvider.notifier).startSession(sessionWithVoice);
    if (!mounted) return;
    context.goSession();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(workoutProvider);
    final voiceState = ref.watch(voiceProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── App Bar ──
            SliverAppBar(
              floating: true,
              backgroundColor: AppColors.background,
              title: Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: AppColors.accentGradient,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'TRAINING',
                      style: AppTypography.labelLarge.copyWith(
                        color: AppColors.textOnAccent,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('Timer', style: AppTypography.headingMedium),
                ],
              ),
              actions: [
                // Badge voix
                IconButton(
                  icon: Icon(
                    voiceState.voiceEnabled
                        ? Icons.volume_up_rounded
                        : Icons.volume_off_rounded,
                    color: voiceState.voiceEnabled
                        ? AppColors.active
                        : AppColors.textMuted,
                  ),
                  tooltip: 'Paramètres voix',
                  onPressed: () => context.goVoice(),
                ),
                const SizedBox(width: 8),
              ],
            ),

            // ── Header ──
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Mes séances',
                        style: AppTypography.headingLarge),
                    const SizedBox(height: 4),
                    Text(
                      '${state.sessions.length} séance${state.sessions.length > 1 ? 's' : ''}',
                      style: AppTypography.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 20)),

            // ── Liste des séances ──
            if (state.isLoading)
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              )
            else if (state.sessions.isEmpty)
              SliverFillRemaining(
                child: _EmptyState(onCreate: () => context.goNewWorkout()),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final session = state.sessions[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: WorkoutCard(
                          session: session,
                          isSelected: _selectedId == session.id,
                          onTap: () => setState(() => _selectedId = session.id),
                          onStart: () => _startSession(session.id),
                          onEdit: () => context.goEditWorkout(session.id),
                          onDelete: () =>
                              _confirmDelete(session.id, session.name),
                        ),
                      );
                    },
                    childCount: state.sessions.length,
                  ),
                ),
              ),

            // ── Bottom padding ──
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),

      // ── FAB ──
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.goNewWorkout(),
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.textOnAccent,
        icon: const Icon(Icons.add),
        label: const Text(
          'Nouvelle séance',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(String id, String name) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        title: const Text('Supprimer la séance ?'),
        content: Text('« $name » sera supprimée définitivement.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Supprimer',
              style: TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
    if (ok == true) {
      ref.read(workoutProvider.notifier).delete(id);
    }
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
            const Icon(
              Icons.fitness_center,
              size: 64,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 24),
            const Text(
              'Aucune séance',
              style: AppTypography.headingMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Créez votre première séance de tractions',
              style: AppTypography.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: onCreate,
              child: const Text('Créer une séance'),
            ),
          ],
        ),
      ),
    );
  }
}
