import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/audio/tts_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../application/voice_provider.dart';
import 'widgets/voice_list_tile.dart';

class VoiceSettingsScreen extends ConsumerStatefulWidget {
  const VoiceSettingsScreen({super.key});

  @override
  ConsumerState<VoiceSettingsScreen> createState() =>
      _VoiceSettingsScreenState();
}

class _VoiceSettingsScreenState extends ConsumerState<VoiceSettingsScreen> {
  String _search = '';
  VoiceInfo? _testingVoice;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(voiceProvider.notifier).loadVoices();
    });
  }

  List<VoiceInfo> _filtered(List<VoiceInfo> voices) {
    if (_search.isEmpty) return voices;
    final q = _search.toLowerCase();
    return voices
        .where((v) =>
            v.name.toLowerCase().contains(q) ||
            v.locale.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(voiceProvider);
    final notifier = ref.read(voiceProvider.notifier);
    final filtered = _filtered(state.availableVoices);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Voix'),
        actions: [
          // Badge statut voix
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Chip(
              avatar: Icon(
                state.voiceEnabled
                    ? Icons.volume_up_rounded
                    : Icons.volume_off_rounded,
                size: 16,
                color: state.voiceEnabled
                    ? AppColors.active
                    : AppColors.textMuted,
              ),
              label: Text(
                state.voiceEnabled ? 'Activée' : 'Désactivée',
                style: AppTypography.labelSmall.copyWith(
                  color: state.voiceEnabled
                      ? AppColors.active
                      : AppColors.textMuted,
                ),
              ),
              backgroundColor: AppColors.surfaceVariant,
              side: BorderSide.none,
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Banner d'état ──
          if (state.selectedVoice != null)
            _SelectedVoiceBanner(
              voice: state.selectedVoice!,
              enabled: state.voiceEnabled,
              onDisable: () => notifier.disableVoice(),
            )
          else
            _NoVoiceBanner(),

          // ── Erreur ──
          if (state.error != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: AppColors.danger, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        state.error!,
                        style: AppTypography.bodySmall
                            .copyWith(color: AppColors.danger),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ── Barre de recherche ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              decoration: const InputDecoration(
                hintText: 'Rechercher une voix…',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
          ),

          // ── Liste des voix ──
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : state.availableVoices.isEmpty
                    ? _EmptyVoices()
                    : _VoiceList(
                        voices: filtered,
                        selectedVoice: state.selectedVoice,
                        testingVoice: _testingVoice,
                        onSelect: (v) => notifier.selectVoice(v),
                        onTest: (v) async {
                          setState(() => _testingVoice = v);
                          await notifier.testVoice(v);
                          if (mounted) setState(() => _testingVoice = null);
                        },
                      ),
          ),

          // ── Bouton valider / continuer ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            child: state.selectedVoice != null
                ? ElevatedButton(
                    onPressed: () {
                      notifier.markConfigured();
                      context.go('/');
                    },
                    child: const Text('Confirmer la voix'),
                  )
                : OutlinedButton(
                    onPressed: () {
                      notifier.markConfigured();
                      context.go('/');
                    },
                    child: const Text('Continuer sans voix'),
                  ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────

class _SelectedVoiceBanner extends StatelessWidget {
  final VoiceInfo voice;
  final bool enabled;
  final VoidCallback onDisable;

  const _SelectedVoiceBanner({
    required this.voice,
    required this.enabled,
    required this.onDisable,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.accentMuted,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.record_voice_over_rounded,
              color: AppColors.accent, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  voice.name,
                  style: AppTypography.labelLarge
                      .copyWith(color: AppColors.accent),
                ),
                Text(voice.locale, style: AppTypography.bodySmall),
              ],
            ),
          ),
          TextButton(
            onPressed: onDisable,
            child: const Text(
              'Désactiver',
              style: TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoVoiceBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: const Row(
        children: [
          Icon(Icons.volume_off_rounded,
              color: AppColors.textMuted, size: 24),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Aucune voix sélectionnée',
                    style: AppTypography.labelLarge),
                Text(
                  'L\'application fonctionne parfaitement sans voix.',
                  style: AppTypography.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VoiceList extends StatelessWidget {
  final List<VoiceInfo> voices;
  final VoiceInfo? selectedVoice;
  final VoiceInfo? testingVoice;
  final void Function(VoiceInfo) onSelect;
  final Future<void> Function(VoiceInfo) onTest;

  const _VoiceList({
    required this.voices,
    required this.selectedVoice,
    required this.testingVoice,
    required this.onSelect,
    required this.onTest,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      itemCount: voices.length,
      itemBuilder: (context, index) {
        final voice = voices[index];
        final isSelected = selectedVoice?.key == voice.key;
        final isTesting = testingVoice?.key == voice.key;

        return VoiceListTile(
          voice: voice,
          isSelected: isSelected,
          isTesting: isTesting,
          onSelect: () => onSelect(voice),
          onTest: () => onTest(voice),
        );
      },
    );
  }
}

class _EmptyVoices extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.hearing_disabled_outlined,
                size: 64, color: AppColors.textMuted),
            SizedBox(height: 16),
            Text('Aucune voix disponible', style: AppTypography.headingMedium),
            SizedBox(height: 8),
            Text(
              'Vérifiez les paramètres de synthèse vocale de votre appareil Android (Paramètres > Accessibilité > Synthèse vocale).',
              style: AppTypography.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
