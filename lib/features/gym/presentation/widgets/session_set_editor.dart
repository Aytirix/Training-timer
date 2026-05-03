import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/models/gym/gym_exercise.dart';
import '../../../../core/models/gym/gym_set.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

/// Édite une série en fonction du type de l'exercice.
class SessionSetEditor extends StatefulWidget {
  final int index;
  final int total;
  final GymExerciseType type;
  final GymSet set;
  final ValueChanged<GymSet> onChanged;
  final VoidCallback? onDelete;

  const SessionSetEditor({
    super.key,
    required this.index,
    required this.total,
    required this.type,
    required this.set,
    required this.onChanged,
    this.onDelete,
  });

  @override
  State<SessionSetEditor> createState() => _SessionSetEditorState();
}

class _SessionSetEditorState extends State<SessionSetEditor> {
  late TextEditingController _weightCtrl;
  late TextEditingController _repsCtrl;
  late TextEditingController _durationCtrl;
  late TextEditingController _restCtrl;

  @override
  void initState() {
    super.initState();
    _weightCtrl = TextEditingController(
        text: widget.set.weightKg?.toString() ?? '');
    _repsCtrl =
        TextEditingController(text: widget.set.repetitions?.toString() ?? '');
    _durationCtrl = TextEditingController(
        text: widget.set.durationSeconds?.toString() ?? '');
    _restCtrl = TextEditingController(
        text: widget.set.restAfterSetSeconds?.toString() ?? '');
  }

  @override
  void didUpdateWidget(covariant SessionSetEditor old) {
    super.didUpdateWidget(old);
    // Sync external changes (e.g. when set is replaced) only if value differs.
    if (old.set != widget.set) {
      _weightCtrl.text = widget.set.weightKg?.toString() ?? '';
      _repsCtrl.text = widget.set.repetitions?.toString() ?? '';
      _durationCtrl.text = widget.set.durationSeconds?.toString() ?? '';
      _restCtrl.text = widget.set.restAfterSetSeconds?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    _repsCtrl.dispose();
    _durationCtrl.dispose();
    _restCtrl.dispose();
    super.dispose();
  }

  void _emit() {
    widget.onChanged(GymSet(
      weightKg:
          double.tryParse(_weightCtrl.text.replaceAll(',', '.')),
      repetitions: int.tryParse(_repsCtrl.text),
      durationSeconds: int.tryParse(_durationCtrl.text),
      restAfterSetSeconds: int.tryParse(_restCtrl.text),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isLast = widget.index == widget.total - 1;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 32,
                child: Text('#${widget.index + 1}',
                    style: AppTypography.labelMedium),
              ),
              const SizedBox(width: 8),
              if (widget.type.hasWeight)
                Expanded(
                  child: TextField(
                    controller: _weightCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'[0-9.,]'))
                    ],
                    decoration: const InputDecoration(labelText: 'Poids (kg)'),
                    onChanged: (_) => _emit(),
                  ),
                ),
              if (widget.type.hasWeight) const SizedBox(width: 8),
              if (widget.type.hasReps)
                Expanded(
                  child: TextField(
                    controller: _repsCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(labelText: 'Reps'),
                    onChanged: (_) => _emit(),
                  ),
                ),
              if (widget.type.hasDuration)
                Expanded(
                  child: TextField(
                    controller: _durationCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration:
                        const InputDecoration(labelText: 'Durée (s)'),
                    onChanged: (_) => _emit(),
                  ),
                ),
              if (widget.onDelete != null)
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.danger),
                  onPressed: widget.onDelete,
                ),
            ],
          ),
          if (!isLast) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const SizedBox(
                  width: 32,
                  child:
                      Icon(Icons.timer_outlined, color: AppColors.resting),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _restCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                        labelText: 'Repos après cette série (s)'),
                    onChanged: (_) => _emit(),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
