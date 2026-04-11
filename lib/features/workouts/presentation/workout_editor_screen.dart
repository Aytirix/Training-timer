import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/router.dart';
import '../../../core/models/workout_block.dart';
import '../../../core/models/workout_session.dart';
import '../../../core/services/pyramid_parser.dart';
import '../../../core/services/workout_calculator.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../domain/workout_provider.dart';
import 'widgets/block_editor_widget.dart';
import 'widgets/quick_input_field.dart';

class WorkoutEditorScreen extends ConsumerStatefulWidget {
  final String? sessionId;
  final BlockType? initialBlockType;

  const WorkoutEditorScreen({
    super.key,
    this.sessionId,
    this.initialBlockType,
  });

  @override
  ConsumerState<WorkoutEditorScreen> createState() =>
      _WorkoutEditorScreenState();
}

class _WorkoutEditorScreenState extends ConsumerState<WorkoutEditorScreen> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _targetCtrl;
  late final TextEditingController _secondsPerRepCtrl;
  late List<WorkoutBlock> _blocks;
  int? _expandedBlock;
  bool _showQuickInput = false;
  bool _autoChain = true;

  WorkoutSession? _original;

  @override
  void initState() {
    super.initState();
    if (widget.sessionId != null) {
      _original = ref.read(workoutProvider).sessions.firstWhere(
            (s) => s.id == widget.sessionId,
          );
      _nameCtrl = TextEditingController(text: _original!.name);
      _targetCtrl = TextEditingController(
          text: (_original!.targetDurationSeconds ~/ 60).toString());
      _secondsPerRepCtrl = TextEditingController(
          text: _original!.normalizedSecondsPerRep.toString());
      _blocks = List.of(_original!.blocks);
      _autoChain = _original!.autoChain;
    } else {
      _nameCtrl = TextEditingController();
      _targetCtrl = TextEditingController(text: '30');
      _secondsPerRepCtrl = TextEditingController(text: '3');
      _blocks = [];
      _autoChain = true;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _targetCtrl.dispose();
    _secondsPerRepCtrl.dispose();
    super.dispose();
  }

  WorkoutStats get _stats {
    final tmpSession = _buildSession();
    return WorkoutCalculator.computeStats(tmpSession);
  }

  int _parseSecondsPerRep() {
    final seconds = int.tryParse(_secondsPerRepCtrl.text.trim()) ?? 3;
    return seconds.clamp(1, 10);
  }

  WorkoutSession _buildSession() {
    final targetMin = int.tryParse(_targetCtrl.text.trim()) ?? 30;
    return (_original ?? WorkoutSession(name: '', blocks: [])).copyWith(
      id: _original?.id,
      name: _nameCtrl.text.trim().isEmpty ? 'Ma séance' : _nameCtrl.text.trim(),
      targetDurationSeconds: targetMin * 60,
      secondsPerRep: _parseSecondsPerRep(),
      autoChain: _autoChain,
      blocks: _blocks,
    );
  }

  Future<void> _save() async {
    if (_blocks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ajoutez au moins un bloc.')),
      );
      return;
    }
    final session = _buildSession();
    await ref.read(workoutProvider.notifier).save(session);
    if (!mounted) return;
    context.go('/');
  }

  void _goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.goHome();
    }
  }

  void _applyQuickInput(ParseResult result) {
    setState(() {
      _blocks = result.blocks;
      _showQuickInput = false;
    });
  }

  void _addEmptyBlock() {
    final nextIndex = _blocks.length + 1;
    final initialType = widget.initialBlockType;

    setState(() {
      _blocks.add(WorkoutBlock(
        name: initialType == BlockType.pyramid
            ? 'Pyramide $nextIndex'
            : 'Bloc $nextIndex',
        type: initialType ?? BlockType.sequence,
        sequence: [5],
        repeatCount: 1,
      ));
      _expandedBlock = _blocks.length - 1;
    });
  }

  String _screenTitle(bool isEdit) {
    if (isEdit) return 'Modifier la séance';
    if (widget.initialBlockType == BlockType.pyramid) {
      return 'Nouvelle séance pyramide';
    }
    return 'Nouvelle séance';
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = _original != null;
    final stats = _stats;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          onPressed: _goBack,
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Retour',
        ),
        title: Text(_screenTitle(isEdit)),
        actions: [
          if (!isEdit)
            TextButton(
              onPressed: _goBack,
              child: Text(
                'Annuler',
                style: AppTypography.labelLarge.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          TextButton(
            onPressed: _save,
            child: Text(
              'Enregistrer',
              style: AppTypography.labelLarge.copyWith(color: AppColors.accent),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── Nom de la séance ──
          TextField(
            controller: _nameCtrl,
            style: AppTypography.headingSmall,
            decoration: const InputDecoration(
              labelText: 'Nom de la séance',
              hintText: '110 tractions / 30 min',
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),

          // ── Durée cible ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _targetCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Durée cible',
                    suffixText: 'min',
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _secondsPerRepCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Temps par traction',
                    suffixText: 's',
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Utilisé pour le chrono automatique et la durée estimée.',
            style: AppTypography.bodySmall,
          ),
          const SizedBox(height: 8),

          // ── Auto-enchaînement ──
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Enchaînement automatique'),
            subtitle: const Text('La série passe en repos toute seule. '
                'Si tu tardes, ton repos est rogné.'),
            value: _autoChain,
            onChanged: (v) => setState(() => _autoChain = v),
          ),
          const SizedBox(height: 16),

          // ── Statistiques ──
          _StatsBar(stats: stats),
          const SizedBox(height: 24),

          // ── Toggle saisie rapide ──
          Row(
            children: [
              const Text('Blocs', style: AppTypography.headingSmall),
              const Spacer(),
              TextButton.icon(
                onPressed: () =>
                    setState(() => _showQuickInput = !_showQuickInput),
                icon: Icon(
                  _showQuickInput ? Icons.edit_note : Icons.flash_on_rounded,
                  size: 18,
                ),
                label:
                    Text(_showQuickInput ? 'Éditeur manuel' : 'Saisie rapide'),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Saisie rapide ──
          if (_showQuickInput) ...[
            QuickInputField(
              initialText: PyramidParser.blocksToText(_blocks),
              onChanged: (_) {},
              onApply: _applyQuickInput,
            ),
            const SizedBox(height: 24),
          ],

          // ── Éditeur de blocs ──
          if (!_showQuickInput) ...[
            if (_blocks.isEmpty)
              _EmptyBlocks(onAdd: _addEmptyBlock)
            else
              ReorderableListView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (newIndex > oldIndex) newIndex--;
                    final item = _blocks.removeAt(oldIndex);
                    _blocks.insert(newIndex, item);
                  });
                },
                children: [
                  for (int i = 0; i < _blocks.length; i++)
                    BlockEditorWidget(
                      key: ValueKey(_blocks[i].id),
                      block: _blocks[i],
                      blockIndex: i,
                      isExpanded: _expandedBlock == i,
                      onToggleExpanded: () => setState(() {
                        _expandedBlock = _expandedBlock == i ? null : i;
                      }),
                      onChanged: (b) => setState(() => _blocks[i] = b),
                      onDelete: () => setState(() {
                        _blocks.removeAt(i);
                        _expandedBlock = null;
                      }),
                    ),
                ],
              ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _addEmptyBlock,
              icon: const Icon(Icons.add),
              label: const Text('Ajouter un bloc'),
            ),
          ],

          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

// ── Stats bar ──

class _StatsBar extends StatelessWidget {
  final WorkoutStats stats;

  const _StatsBar({required this.stats});

  @override
  Widget build(BuildContext context) {
    final deltaColor = stats.deltaSeconds > 120
        ? AppColors.danger
        : stats.deltaSeconds < -120
            ? AppColors.active
            : AppColors.textSecondary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          _StatItem(
            value: '${stats.totalReps}',
            label: 'reps',
            color: AppColors.accent,
          ),
          const _Divider(),
          _StatItem(
            value: '${stats.totalSets}',
            label: 'séries',
            color: AppColors.active,
          ),
          const _Divider(),
          _StatItem(
            value: stats.estimatedDurationLabel,
            label: 'estimé',
            color: AppColors.resting,
          ),
          const _Divider(),
          _StatItem(
            value: stats.deltaLabel,
            label: 'vs cible',
            color: deltaColor,
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _StatItem({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: AppTypography.headingSmall.copyWith(color: color),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTypography.caption,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 32,
      color: AppColors.border,
      margin: const EdgeInsets.symmetric(horizontal: 8),
    );
  }
}

class _EmptyBlocks extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyBlocks({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, style: BorderStyle.solid),
      ),
      child: Column(
        children: [
          const Icon(Icons.layers_outlined,
              size: 40, color: AppColors.textMuted),
          const SizedBox(height: 12),
          const Text('Aucun bloc', style: AppTypography.bodyMedium),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Ajouter un bloc'),
          ),
        ],
      ),
    );
  }
}
