// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../data/gym_import_service.dart';
import '../data/gym_session_json_codec.dart';
import '../domain/gym_provider.dart';

class GymJsonImportScreen extends ConsumerStatefulWidget {
  const GymJsonImportScreen({super.key});

  @override
  ConsumerState<GymJsonImportScreen> createState() =>
      _GymJsonImportScreenState();
}

class _GymJsonImportScreenState extends ConsumerState<GymJsonImportScreen> {
  final _ctrl = TextEditingController();
  ImportPlan? _plan;
  String? _error;
  final Map<String, ImportConflictAction> _decisions = {};
  final Map<String, TextEditingController> _renameCtrls = {};

  @override
  void dispose() {
    _ctrl.dispose();
    for (final c in _renameCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _analyze() {
    setState(() {
      _error = null;
      _plan = null;
      _decisions.clear();
      for (final c in _renameCtrls.values) {
        c.dispose();
      }
      _renameCtrls.clear();
    });
    final repo = ref.read(gymRepositoryProvider);
    final service = GymImportService(repo);
    try {
      final plan = service.prepare(_ctrl.text);
      setState(() {
        _plan = plan;
        for (final c in plan.conflicts) {
          _decisions[c.existing.id] = ImportConflictAction.keepExisting;
          _renameCtrls[c.existing.id] =
              TextEditingController(text: '${c.imported.name} (importé)');
        }
      });
    } on GymImportException catch (e) {
      setState(() => _error = e.toString());
    } catch (e) {
      setState(() => _error = 'Erreur : $e');
    }
  }

  Future<void> _confirm() async {
    final plan = _plan;
    if (plan == null) return;
    final repo = ref.read(gymRepositoryProvider);
    final service = GymImportService(repo);
    try {
      final renameMap = <String, String>{};
      for (final entry in _decisions.entries) {
        if (entry.value == ImportConflictAction.createNew) {
          renameMap[entry.key] = _renameCtrls[entry.key]?.text.trim() ?? '';
        }
      }
      await service.apply(plan, decisions: _decisions, renameMap: renameMap);
      ref.read(gymExercisesProvider.notifier).refresh();
      ref.read(gymSessionsProvider.notifier).refresh();
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      setState(() => _error = 'Erreur : $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        title: const Text('Importer une séance'),
      ),
      body: SafeArea(
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Collez ici le JSON de la séance.',
                    style: AppTypography.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _ctrl,
                    maxLines: 10,
                    minLines: 8,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textPrimary,
                      fontFamily: 'monospace',
                    ),
                    cursorColor: AppColors.accent,
                    decoration: const InputDecoration(
                      hintText: '{\n  "version": 1,\n  "session": ...\n}',
                    ),
                    onTapOutside: (_) =>
                        FocusManager.instance.primaryFocus?.unfocus(),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _analyze,
                        icon: const Icon(Icons.search),
                        label: const Text('Analyser'),
                      ),
                      if (_plan != null)
                        ElevatedButton.icon(
                          onPressed: _confirm,
                          icon: const Icon(Icons.check),
                          label: const Text('Importer'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.danger.withAlpha(40),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(_error!,
                    style: AppTypography.bodyMedium
                        .copyWith(color: AppColors.danger)),
              ),
            ],
            if (_plan != null) ..._buildPlanView(_plan!),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildPlanView(ImportPlan plan) {
    return [
      const SizedBox(height: 24),
      Text('Séance : ${plan.imported.name}', style: AppTypography.headingSmall),
      Text('${plan.imported.exerciseItems.length} exercice(s)',
          style: AppTypography.bodySmall),
      const SizedBox(height: 12),
      if (plan.toCreate.isNotEmpty) ...[
        const Text('À créer', style: AppTypography.labelMedium),
        for (final spec in plan.toCreate)
          ListTile(
            leading: const Icon(Icons.add, color: AppColors.active),
            title: Text(spec.name),
            subtitle: Text(spec.type.label),
          ),
      ],
      if (plan.reused.isNotEmpty) ...[
        const SizedBox(height: 8),
        const Text('Réutilisés', style: AppTypography.labelMedium),
        for (final ex in plan.reused)
          ListTile(
            leading: const Icon(Icons.check, color: AppColors.resting),
            title: Text(ex.name),
            subtitle: Text(ex.type.label),
          ),
      ],
      if (plan.hasConflicts) ...[
        const SizedBox(height: 8),
        const Text('Conflits — décide pour chaque exercice :',
            style: AppTypography.labelMedium),
        for (final c in plan.conflicts) _buildConflictTile(c),
      ],
    ];
  }

  Widget _buildConflictTile(ImportConflict c) {
    final action =
        _decisions[c.existing.id] ?? ImportConflictAction.keepExisting;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.countdown),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('« ${c.existing.name} » (${c.existing.type.label})',
              style: AppTypography.headingSmall),
          Text('Différences : ${c.differences.join(", ")}',
              style: AppTypography.bodySmall),
          const SizedBox(height: 8),
          for (final a in ImportConflictAction.values)
            RadioListTile<ImportConflictAction>(
              value: a,
              groupValue: action,
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text(_labelForAction(a)),
              onChanged: (v) {
                if (v == null) return;
                setState(() => _decisions[c.existing.id] = v);
              },
            ),
          if (action == ImportConflictAction.createNew)
            TextField(
              controller: _renameCtrls[c.existing.id],
              decoration: const InputDecoration(labelText: 'Nouveau nom'),
            ),
        ],
      ),
    );
  }

  String _labelForAction(ImportConflictAction a) {
    switch (a) {
      case ImportConflictAction.keepExisting:
        return 'Garder l\'existant';
      case ImportConflictAction.updateExisting:
        return 'Mettre à jour l\'existant';
      case ImportConflictAction.createNew:
        return 'Créer un nouvel exercice (renommer)';
    }
  }
}
