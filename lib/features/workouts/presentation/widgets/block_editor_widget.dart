import 'package:flutter/material.dart';
import '../../../../core/models/workout_block.dart';
import '../../../../core/models/rest_strategy.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

/// Éditeur d'un seul bloc (expandable).
class BlockEditorWidget extends StatefulWidget {
  final WorkoutBlock block;
  final int blockIndex;
  final void Function(WorkoutBlock) onChanged;
  final VoidCallback onDelete;
  final bool isExpanded;
  final VoidCallback onToggleExpanded;

  const BlockEditorWidget({
    super.key,
    required this.block,
    required this.blockIndex,
    required this.onChanged,
    required this.onDelete,
    this.isExpanded = false,
    required this.onToggleExpanded,
  });

  @override
  State<BlockEditorWidget> createState() => _BlockEditorWidgetState();
}

class _BlockEditorWidgetState extends State<BlockEditorWidget> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _sequenceCtrl;
  late final TextEditingController _repeatCtrl;
  late final TextEditingController _transitionCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.block.name);
    _sequenceCtrl =
        TextEditingController(text: widget.block.sequence.join('-'));
    _repeatCtrl =
        TextEditingController(text: widget.block.repeatCount.toString());
    _transitionCtrl = TextEditingController(
        text: widget.block.transitionRestSeconds.toString());
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _sequenceCtrl.dispose();
    _repeatCtrl.dispose();
    _transitionCtrl.dispose();
    super.dispose();
  }

  int _clampRepeat(int value) => value.clamp(1, 20);

  int _clampSeconds(int value) => value.clamp(0, 600);

  List<int> _parseSequenceInput() {
    return _sequenceCtrl.text
        .split('-')
        .map((s) => int.tryParse(s.trim()) ?? 0)
        .where((n) => n > 0)
        .toList();
  }

  int _parseRepeatInput() {
    final repeat = int.tryParse(_repeatCtrl.text.trim()) ?? 1;
    return _clampRepeat(repeat);
  }

  int _parseTransitionInput() {
    final transition = int.tryParse(_transitionCtrl.text.trim()) ?? 120;
    return _clampSeconds(transition);
  }

  List<int> _buildDefaultPreciseRests({
    required List<int> sequence,
    required int transitionSeconds,
  }) {
    return List<int>.generate(sequence.length, (index) {
      final isLast = index == sequence.length - 1;
      if (isLast) {
        return _clampSeconds(transitionSeconds);
      }
      return widget.block.restStrategy.restForReps(sequence[index]);
    });
  }

  List<int> _coercePreciseRests({
    required List<int> source,
    required List<int> sequence,
    required int transitionSeconds,
  }) {
    final defaults = _buildDefaultPreciseRests(
      sequence: sequence,
      transitionSeconds: transitionSeconds,
    );

    return List<int>.generate(sequence.length, (index) {
      if (index < source.length) {
        return _clampSeconds(source[index]);
      }
      return defaults[index];
    });
  }

  List<int>? _normalizePreciseRests({
    required List<int> sequence,
    required int transitionSeconds,
  }) {
    final current = widget.block.restPerSet;
    if (current == null) return null;

    return _coercePreciseRests(
      source: current,
      sequence: sequence,
      transitionSeconds: transitionSeconds,
    );
  }

  void _apply({
    RestStrategy? strategy,
    List<int>? preciseRests,
    bool overridePreciseRests = false,
  }) {
    final parts = _parseSequenceInput();
    if (parts.isEmpty) return;

    final repeat = _parseRepeatInput();
    final transition = _parseTransitionInput();
    final nextRestPerSet = overridePreciseRests
        ? (preciseRests == null
            ? null
            : _coercePreciseRests(
                source: preciseRests,
                sequence: parts,
                transitionSeconds: transition,
              ))
        : _normalizePreciseRests(
            sequence: parts,
            transitionSeconds: transition,
          );

    widget.onChanged(widget.block.copyWith(
      name: _nameCtrl.text.trim().isNotEmpty
          ? _nameCtrl.text.trim()
          : parts.join('-'),
      sequence: parts,
      repeatCount: repeat,
      transitionRestSeconds: transition,
      restStrategy: strategy ?? widget.block.restStrategy,
      restPerSet: nextRestPerSet,
    ));
  }

  void _setPreciseRestMode(bool enabled) {
    final parts = _parseSequenceInput();
    if (parts.isEmpty) return;

    final transition = _parseTransitionInput();

    final nextRests = enabled
        ? (_normalizePreciseRests(
              sequence: parts,
              transitionSeconds: transition,
            ) ??
            _buildDefaultPreciseRests(
              sequence: parts,
              transitionSeconds: transition,
            ))
        : null;

    _apply(
      preciseRests: nextRests,
      overridePreciseRests: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.block;
    final usesPreciseRest = b.hasCustomRestPerSet;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.isExpanded ? AppColors.accent : AppColors.border,
          width: widget.isExpanded ? 1.5 : 1,
        ),
      ),
      child: Column(
        children: [
          // ── En-tête cliquable ──
          InkWell(
            onTap: widget.onToggleExpanded,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.accentMuted,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '${widget.blockIndex + 1}',
                        style: AppTypography.labelLarge
                            .copyWith(color: AppColors.accent),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(b.name, style: AppTypography.headingSmall),
                        const SizedBox(height: 2),
                        Text(
                          '${b.totalReps} reps  •  ${b.totalSets} séries'
                          '  •  ${usesPreciseRest ? 'repos précis' : 'repos auto'}',
                          style: AppTypography.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    widget.isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: AppColors.textMuted,
                  ),
                ],
              ),
            ),
          ),

          // ── Corps expansible ──
          if (widget.isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nom
                  TextField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(labelText: 'Nom du bloc'),
                    onChanged: (_) => _apply(),
                  ),
                  const SizedBox(height: 12),

                  // Séquence
                  TextField(
                    controller: _sequenceCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Séquence (ex: 1-2-3-4-3-2-1)',
                      hintText: '2-4-6-8-6-4-2',
                    ),
                    onChanged: (_) => _apply(),
                  ),
                  const SizedBox(height: 12),

                  // Répétitions et transition
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _repeatCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Répétitions',
                          ),
                          onChanged: (_) => _apply(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _transitionCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Transition (sec)',
                          ),
                          onChanged: (_) => _apply(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  const Text(
                    'Mode de repos',
                    style: AppTypography.labelMedium,
                  ),
                  const SizedBox(height: 8),
                  _RestModeSelector(
                    usesPreciseRest: usesPreciseRest,
                    onChanged: _setPreciseRestMode,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    usesPreciseRest
                        ? 'Tu peux définir un temps de repos différent à chaque étape.'
                        : 'Le même repos est appliqué par tranche de reps.',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (usesPreciseRest)
                    _PreciseRestEditor(
                      sequence: b.sequence,
                      repeatCount: b.repeatCount,
                      preciseRests: b.restPerSet!,
                      onChanged: (index, seconds) {
                        final rests = List<int>.from(
                          b.restPerSet ??
                              _buildDefaultPreciseRests(
                                sequence: b.sequence,
                                transitionSeconds: b.transitionRestSeconds,
                              ),
                        );
                        if (index >= rests.length) return;
                        rests[index] = seconds;
                        _apply(
                          preciseRests: rests,
                          overridePreciseRests: true,
                        );
                      },
                    )
                  else
                    _RestStrategyEditor(
                      strategy: b.restStrategy,
                      onChanged: (s) => _apply(strategy: s),
                    ),

                  const SizedBox(height: 12),
                  // Supprimer
                  TextButton.icon(
                    onPressed: widget.onDelete,
                    icon: const Icon(Icons.delete_outline,
                        color: AppColors.danger, size: 18),
                    label: const Text(
                      'Supprimer ce bloc',
                      style: TextStyle(color: AppColors.danger),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RestModeSelector extends StatelessWidget {
  final bool usesPreciseRest;
  final void Function(bool enabled) onChanged;

  const _RestModeSelector({
    required this.usesPreciseRest,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ChoiceChip(
          label: const Text('Auto'),
          selected: !usesPreciseRest,
          onSelected: (_) => onChanged(false),
        ),
        ChoiceChip(
          label: const Text('Précis'),
          selected: usesPreciseRest,
          onSelected: (_) => onChanged(true),
        ),
      ],
    );
  }
}

class _PreciseRestEditor extends StatelessWidget {
  final List<int> sequence;
  final int repeatCount;
  final List<int> preciseRests;
  final void Function(int index, int seconds) onChanged;

  const _PreciseRestEditor({
    required this.sequence,
    required this.repeatCount,
    required this.preciseRests,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final showCycleRest = repeatCount > 1;
    final visibleCount = showCycleRest
        ? sequence.length
        : (sequence.length - 1).clamp(0, sequence.length);
    final visibleIndices = List<int>.generate(visibleCount, (index) => index);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Repos précis (secondes)',
          style: AppTypography.labelMedium,
        ),
        const SizedBox(height: 8),
        if (visibleIndices.isEmpty)
          Text(
            'Ce bloc n\'a pas de repos intermédiaire à configurer.',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textMuted,
            ),
          )
        else
          ...visibleIndices.map((index) {
            final reps = sequence[index];
            final label = index == sequence.length - 1 && showCycleRest
                ? 'Après $reps ${reps == 1 ? 'rep' : 'reps'} (entre cycles)'
                : 'Après $reps ${reps == 1 ? 'rep' : 'reps'}';

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _PreciseRestRow(
                label: label,
                value: index < preciseRests.length ? preciseRests[index] : 0,
                onChanged: (seconds) => onChanged(index, seconds),
              ),
            );
          }),
        const SizedBox(height: 4),
        Text(
          showCycleRest
              ? 'Le dernier champ sert au repos entre deux répétitions du bloc. La transition ci-dessus s\'applique après le dernier cycle.'
              : 'La dernière série du bloc utilise la transition ci-dessus.',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}

class _RestStrategyEditor extends StatelessWidget {
  final RestStrategy strategy;
  final void Function(RestStrategy) onChanged;

  const _RestStrategyEditor({required this.strategy, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Repos (secondes)',
          style: AppTypography.labelMedium,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _RestInput(
              label: '1-3 reps',
              value: strategy.smallSetRestSeconds,
              onChanged: (v) =>
                  onChanged(strategy.copyWith(smallSetRestSeconds: v)),
            ),
            const SizedBox(width: 8),
            _RestInput(
              label: '4-6 reps',
              value: strategy.mediumSetRestSeconds,
              onChanged: (v) =>
                  onChanged(strategy.copyWith(mediumSetRestSeconds: v)),
            ),
            const SizedBox(width: 8),
            _RestInput(
              label: '7-9 reps',
              value: strategy.largeSetRestSeconds,
              onChanged: (v) =>
                  onChanged(strategy.copyWith(largeSetRestSeconds: v)),
            ),
            const SizedBox(width: 8),
            _RestInput(
              label: '10+ reps',
              value: strategy.peakSetRestSeconds,
              onChanged: (v) =>
                  onChanged(strategy.copyWith(peakSetRestSeconds: v)),
            ),
          ],
        ),
      ],
    );
  }
}

class _PreciseRestRow extends StatelessWidget {
  final String label;
  final int value;
  final void Function(int seconds) onChanged;

  const _PreciseRestRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: AppTypography.bodyMedium,
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 84,
          child: _RestValueInput(
            value: value,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

class _RestInput extends StatefulWidget {
  final String label;
  final int value;
  final void Function(int) onChanged;

  const _RestInput({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  State<_RestInput> createState() => _RestInputState();
}

class _RestInputState extends State<_RestInput> {
  late final TextEditingController _ctrl;
  late final FocusNode _focus;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.value.toString());
    _focus = FocusNode();
  }

  @override
  void didUpdateWidget(_RestInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && !_focus.hasFocus) {
      _ctrl.text = widget.value.toString();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: TextField(
        controller: _ctrl,
        focusNode: _focus,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        decoration: InputDecoration(
          labelText: widget.label,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        ),
        onChanged: (v) {
          final n = int.tryParse(v);
          if (n != null && n >= 0) {
            widget.onChanged(n.clamp(0, 600));
          }
        },
      ),
    );
  }
}

class _RestValueInput extends StatefulWidget {
  final int value;
  final void Function(int seconds) onChanged;

  const _RestValueInput({
    required this.value,
    required this.onChanged,
  });

  @override
  State<_RestValueInput> createState() => _RestValueInputState();
}

class _RestValueInputState extends State<_RestValueInput> {
  late final TextEditingController _ctrl;
  late final FocusNode _focus;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.value.toString());
    _focus = FocusNode();
  }

  @override
  void didUpdateWidget(_RestValueInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && !_focus.hasFocus) {
      _ctrl.text = widget.value.toString();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _ctrl,
      focusNode: _focus,
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      decoration: const InputDecoration(
        isDense: true,
        suffixText: 's',
        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      ),
      onChanged: (v) {
        final n = int.tryParse(v);
        if (n != null && n >= 0) {
          widget.onChanged(n.clamp(0, 600));
        }
      },
    );
  }
}
