import 'package:flutter/material.dart';
import '../../../../core/services/pyramid_parser.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

/// Champ de saisie rapide de pyramides avec validation en temps réel.
class QuickInputField extends StatefulWidget {
  final String initialText;
  final void Function(ParseResult result) onChanged;
  final void Function(ParseResult result)? onApply;

  const QuickInputField({
    super.key,
    this.initialText = '',
    required this.onChanged,
    this.onApply,
  });

  @override
  State<QuickInputField> createState() => _QuickInputFieldState();
}

class _QuickInputFieldState extends State<QuickInputField> {
  late final TextEditingController _controller;
  ParseResult? _result;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
    if (widget.initialText.isNotEmpty) {
      _parse(widget.initialText);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _parse(String text) {
    final result = PyramidParser.parse(text);
    setState(() => _result = result);
    widget.onChanged(result);
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    final hasContent = _controller.text.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Label ──
        const Text('Saisie rapide', style: AppTypography.labelMedium),
        const SizedBox(height: 8),

        // ── Champ de texte ──
        TextField(
          controller: _controller,
          maxLines: 6,
          minLines: 3,
          onChanged: _parse,
          keyboardType: TextInputType.multiline,
          style: AppTypography.bodyLarge.copyWith(
            fontFamily: 'monospace',
            fontSize: 15,
          ),
          decoration: InputDecoration(
            hintText:
                '1-2-3-4-3-2-1 x3\n2-4-6-8-6-4-2\n2-3-5-3-2 x2',
            hintStyle: AppTypography.bodyMedium.copyWith(
              fontFamily: 'monospace',
            ),
            suffix: hasContent
                ? GestureDetector(
                    onTap: () {
                      _controller.clear();
                      _parse('');
                    },
                    child: const Icon(Icons.clear, size: 18, color: AppColors.textMuted),
                  )
                : null,
          ),
        ),

        const SizedBox(height: 12),

        // ── Résultat du parsing ──
        if (result != null && hasContent) _ParsePreview(result: result),

        // ── Bouton appliquer ──
        if (result != null && result.isValid && widget.onApply != null) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => widget.onApply!(result),
              child: const Text('Appliquer la saisie'),
            ),
          ),
        ],
      ],
    );
  }
}

class _ParsePreview extends StatelessWidget {
  final ParseResult result;

  const _ParsePreview({required this.result});

  @override
  Widget build(BuildContext context) {
    if (result.hasErrors) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: result.errors
            .map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 14,
                      color: AppColors.danger,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        e,
                        style: AppTypography.bodySmall
                            .copyWith(color: AppColors.danger),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.accentMuted,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Blocs détectés
          ...result.blocks.map((b) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline,
                        size: 14, color: AppColors.accent),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${b.sequence.join('-')}${b.repeatCount > 1 ? ' ×${b.repeatCount}' : ''}'
                        '  →  ${b.totalReps} reps, ${b.totalSets} séries',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.accent,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ],
                ),
              )),
          const Divider(color: AppColors.border, height: 16),
          // Total
          Row(
            children: [
              const Text(
                'Total : ',
                style: AppTypography.labelSmall,
              ),
              Text(
                '${result.totalReps} reps',
                style: AppTypography.labelMedium
                    .copyWith(color: AppColors.accent),
              ),
              Text(
                '  •  ${result.totalSets} séries',
                style: AppTypography.labelSmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
