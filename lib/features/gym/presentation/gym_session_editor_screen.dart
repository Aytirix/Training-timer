import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/gym/gym_exercise.dart';
import '../../../core/models/gym/gym_session.dart';
import '../../../core/models/gym/gym_session_item.dart';
import '../../../core/models/gym/gym_set.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../domain/gym_provider.dart';
import 'exercise_library_screen.dart';
import 'widgets/session_set_editor.dart';

/// Écran d'édition d'une séance.
class GymSessionEditorScreen extends ConsumerStatefulWidget {
  final String? sessionId;
  const GymSessionEditorScreen({super.key, this.sessionId});

  @override
  ConsumerState<GymSessionEditorScreen> createState() =>
      _GymSessionEditorScreenState();
}

class _GymSessionEditorScreenState
    extends ConsumerState<GymSessionEditorScreen> {
  final _nameCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final List<GymSessionItem> _items = [];
  String? _id;
  String? _expandedItemId;
  String? _saveError;

  @override
  void initState() {
    super.initState();
    if (widget.sessionId != null) {
      final s =
          ref.read(gymSessionsProvider.notifier).findById(widget.sessionId!);
      if (s != null) {
        _id = s.id;
        _nameCtrl.text = s.name;
        _descriptionCtrl.text = s.description;
        _items.addAll(s.items.map(_cloneItem));
      }
    }
  }

  GymSessionItem _cloneItem(GymSessionItem item) {
    if (item is GymSessionExerciseItem) {
      return GymSessionExerciseItem(
        id: item.id,
        exerciseId: item.exerciseId,
        sets: List.of(item.sets),
        timedSetStartMode: item.timedSetStartMode,
      );
    }
    if (item is GymSessionRestItem) {
      return GymSessionRestItem(
        id: item.id,
        durationSeconds: item.durationSeconds,
      );
    }
    return item;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  Future<void> _addExercise() async {
    final picked = await Navigator.of(context).push<GymExercise>(
      MaterialPageRoute(
        builder: (_) => const ExerciseLibraryScreen(selectionMode: true),
      ),
    );
    if (picked == null) return;
    final defaultMode =
        picked.type.hasDuration ? TimedSetStartMode.manual : null;
    setState(() {
      final item = GymSessionExerciseItem(
        exerciseId: picked.id,
        timedSetStartMode: defaultMode,
        sets: [const GymSet(restAfterSetSeconds: null), const GymSet()],
      );
      _items.add(item);
      _expandedItemId = item.id;
    });
  }

  void _addRest() {
    setState(() {
      _items.add(GymSessionRestItem(durationSeconds: 60));
    });
  }

  void _removeItem(GymSessionItem item) {
    setState(() {
      _items.removeWhere((i) => i.id == item.id);
    });
  }

  void _updateExercise(
      GymSessionExerciseItem old, GymSessionExerciseItem updated) {
    final idx = _items.indexWhere((i) => i.id == old.id);
    if (idx < 0) return;
    setState(() {
      _items[idx] = updated;
    });
  }

  void _updateRest(GymSessionRestItem old, int duration) {
    final idx = _items.indexWhere((i) => i.id == old.id);
    if (idx < 0) return;
    setState(() {
      _items[idx] = old.copyWith(durationSeconds: duration);
    });
  }

  void _reorderItems(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final item = _items.removeAt(oldIndex);
      _items.insert(newIndex, item);
    });
  }

  Future<void> _save() async {
    setState(() => _saveError = null);
    if (_nameCtrl.text.trim().isEmpty) {
      setState(() => _saveError = 'Nom de séance obligatoire');
      return;
    }
    final session = GymSession(
      id: _id,
      name: _nameCtrl.text.trim(),
      description: _descriptionCtrl.text.trim(),
      items: _items,
    );
    await ref.read(gymSessionsProvider.notifier).save(session);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text(_id == null ? 'Nouvelle séance' : 'Modifier séance'),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('Enregistrer'),
          ),
        ],
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Column(
                children: [
                  TextField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(labelText: 'Nom *'),
                    textCapitalization: TextCapitalization.sentences,
                    onTapOutside: (_) =>
                        FocusManager.instance.primaryFocus?.unfocus(),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _descriptionCtrl,
                    decoration: const InputDecoration(labelText: 'Description'),
                    maxLines: 2,
                    onTapOutside: (_) =>
                        FocusManager.instance.primaryFocus?.unfocus(),
                  ),
                  if (_saveError != null) ...[
                    const SizedBox(height: 8),
                    Text(_saveError!,
                        style: AppTypography.bodyMedium
                            .copyWith(color: AppColors.danger)),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _items.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.fitness_center,
                                size: 48, color: AppColors.textMuted),
                            const SizedBox(height: 16),
                            const Text('Aucun item dans la séance',
                                style: AppTypography.bodyMedium),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _addExercise,
                              icon: const Icon(Icons.add),
                              label: const Text('Ajouter un exercice'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ReorderableListView.builder(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                      onReorder: _reorderItems,
                      itemCount: _items.length,
                      itemBuilder: (_, i) {
                        final item = _items[i];
                        if (item is GymSessionRestItem) {
                          return _RestItemCard(
                            key: ValueKey(item.id),
                            item: item,
                            onChanged: (d) => _updateRest(item, d),
                            onDelete: () => _removeItem(item),
                          );
                        }
                        if (item is GymSessionExerciseItem) {
                          final exercise = ref
                              .read(gymExercisesProvider.notifier)
                              .findById(item.exerciseId);
                          return _ExerciseItemCard(
                            key: ValueKey(item.id),
                            item: item,
                            exercise: exercise,
                            expanded: _expandedItemId == item.id,
                            onTapHeader: () => setState(() {
                              _expandedItemId =
                                  _expandedItemId == item.id ? null : item.id;
                            }),
                            onChanged: (u) => _updateExercise(item, u),
                            onDelete: () => _removeItem(item),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: PopupMenuButton<String>(
        icon: const CircleAvatar(
          backgroundColor: AppColors.accent,
          foregroundColor: AppColors.textOnAccent,
          radius: 28,
          child: Icon(Icons.add),
        ),
        color: AppColors.surfaceElevated,
        onSelected: (v) {
          if (v == 'exercise') _addExercise();
          if (v == 'rest') _addRest();
        },
        itemBuilder: (_) => const [
          PopupMenuItem(value: 'exercise', child: Text('Ajouter un exercice')),
          PopupMenuItem(
              value: 'rest', child: Text('Ajouter un repos entre exercices')),
        ],
      ),
    );
  }
}

class _RestItemCard extends StatelessWidget {
  final GymSessionRestItem item;
  final ValueChanged<int> onChanged;
  final VoidCallback onDelete;

  const _RestItemCard({
    super.key,
    required this.item,
    required this.onChanged,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final ctrl = TextEditingController(text: item.durationSeconds.toString());
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.resting),
        ),
        child: Row(
          children: [
            const Icon(Icons.timer, color: AppColors.resting),
            const SizedBox(width: 8),
            const Text('Repos entre exercices',
                style: AppTypography.labelMedium),
            const SizedBox(width: 12),
            SizedBox(
              width: 80,
              child: TextField(
                controller: ctrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(suffix: Text('s')),
                onSubmitted: (v) => onChanged(int.tryParse(v) ?? 0),
                onChanged: (v) => onChanged(int.tryParse(v) ?? 0),
              ),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.close, color: AppColors.danger),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

class _ExerciseItemCard extends StatelessWidget {
  final GymSessionExerciseItem item;
  final GymExercise? exercise;
  final bool expanded;
  final VoidCallback onTapHeader;
  final ValueChanged<GymSessionExerciseItem> onChanged;
  final VoidCallback onDelete;

  const _ExerciseItemCard({
    super.key,
    required this.item,
    required this.exercise,
    required this.expanded,
    required this.onTapHeader,
    required this.onChanged,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final type = exercise?.type;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            ListTile(
              onTap: onTapHeader,
              title: Text(exercise?.name ?? 'Exercice introuvable',
                  style: AppTypography.headingSmall),
              subtitle: Text(
                '${type?.label ?? '???'} • ${item.sets.length} séries',
                style: AppTypography.bodySmall,
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(expanded ? Icons.expand_less : Icons.expand_more,
                      color: AppColors.textSecondary),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.danger),
                    onPressed: onDelete,
                  ),
                ],
              ),
            ),
            if (expanded && type != null) ...[
              const Divider(height: 1, color: AppColors.border),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    if (type.hasDuration) ...[
                      Row(
                        children: [
                          const Text('Démarrage :',
                              style: AppTypography.labelMedium),
                          const SizedBox(width: 12),
                          for (final mode in TimedSetStartMode.values) ...[
                            ChoiceChip(
                              label: Text(mode == TimedSetStartMode.manual
                                  ? 'Manuel'
                                  : 'Automatique'),
                              selected: item.timedSetStartMode == mode,
                              onSelected: (s) {
                                if (s) {
                                  onChanged(
                                      item.copyWith(timedSetStartMode: mode));
                                }
                              },
                            ),
                            const SizedBox(width: 8),
                          ],
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                    for (var i = 0; i < item.sets.length; i++) ...[
                      SessionSetEditor(
                        index: i,
                        total: item.sets.length,
                        type: type,
                        set: item.sets[i],
                        onChanged: (s) {
                          final newSets = List<GymSet>.of(item.sets);
                          newSets[i] = s;
                          onChanged(item.copyWith(sets: newSets));
                        },
                        onDelete: item.sets.length > 1
                            ? () {
                                final newSets = List<GymSet>.of(item.sets)
                                  ..removeAt(i);
                                onChanged(item.copyWith(sets: newSets));
                              }
                            : null,
                      ),
                      const SizedBox(height: 8),
                    ],
                    OutlinedButton.icon(
                      onPressed: () {
                        final newSets = List<GymSet>.of(item.sets)
                          ..add(const GymSet());
                        onChanged(item.copyWith(sets: newSets));
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Ajouter une série'),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
