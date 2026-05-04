import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_selector/file_selector.dart';
import '../../../core/models/gym/exercise_video.dart';
import '../../../core/models/gym/gym_exercise.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../domain/gym_provider.dart';
import '../services/exercise_video_detector.dart';
import '../services/local_video_store.dart';

enum _VideoInputMode { url, local }

/// Écran d'édition / création d'un exercice global.
class ExerciseEditorScreen extends ConsumerStatefulWidget {
  final String? exerciseId;
  final GymExerciseType? initialType;

  const ExerciseEditorScreen({super.key, this.exerciseId, this.initialType});

  @override
  ConsumerState<ExerciseEditorScreen> createState() =>
      _ExerciseEditorScreenState();
}

class _ExerciseEditorScreenState extends ConsumerState<ExerciseEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _instructionsCtrl = TextEditingController();
  final _videoUrlCtrl = TextEditingController();

  GymExerciseType _type = GymExerciseType.poidsRepetitions;
  GymExercise? _existing;
  ExerciseVideo? _localVideo;
  String? _pickedLocalPath;
  String? _pickedLocalName;
  _VideoInputMode _videoMode = _VideoInputMode.url;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.exerciseId != null) {
      final found =
          ref.read(gymExercisesProvider.notifier).findById(widget.exerciseId!);
      if (found != null) {
        _existing = found;
        _nameCtrl.text = found.name;
        _instructionsCtrl.text = found.instructions;
        _type = found.type;
        if (found.video?.source == ExerciseVideoSource.localFile) {
          _videoMode = _VideoInputMode.local;
          _localVideo = found.video;
        } else if (found.video?.url != null) {
          _videoMode = _VideoInputMode.url;
          _videoUrlCtrl.text = found.video!.url!;
        }
      }
    } else if (widget.initialType != null) {
      _type = widget.initialType!;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _instructionsCtrl.dispose();
    _videoUrlCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickLocalVideo() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final file = await openFile(
      acceptedTypeGroups: const [
        XTypeGroup(
          label: 'Vidéos',
          extensions: ['mp4', 'webm', 'mov', 'm4v', 'avi', 'mkv'],
          mimeTypes: ['video/*'],
        ),
      ],
    );
    if (file == null) return;
    setState(() {
      _videoMode = _VideoInputMode.local;
      _pickedLocalPath = file.path;
      _pickedLocalName = file.name;
      _videoUrlCtrl.clear();
    });
  }

  Future<ExerciseVideo?> _buildVideo() async {
    if (_videoMode == _VideoInputMode.local) {
      if (_pickedLocalPath != null && _pickedLocalName != null) {
        return LocalVideoStore.copyIntoAppStorage(
          sourcePath: _pickedLocalPath!,
          originalFileName: _pickedLocalName!,
        );
      }
      return _localVideo;
    }

    final raw = _videoUrlCtrl.text.trim();
    if (raw.isEmpty) return null;
    final detected = ExerciseVideoDetector.detect(raw);
    return ExerciseVideo(source: detected, url: raw);
  }

  Future<void> _save() async {
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) return;

    final video = await _buildVideo();
    if (video != null && video.source == ExerciseVideoSource.directUrl) {
      if (!ExerciseVideoDetector.isValidDirectVideoUrl(video.url!)) {
        setState(() => _error =
            'URL vidéo directe invalide. Doit pointer vers un fichier vidéo lisible (.mp4, .webm…).');
        return;
      }
    }
    if (video != null &&
        video.source == ExerciseVideoSource.youtube &&
        ExerciseVideoDetector.extractYoutubeId(video.url!) == null) {
      setState(() => _error =
          'URL YouTube sans identifiant de vidéo. Colle un lien complet (ex: youtube.com/watch?v=…).');
      return;
    }

    final exercise =
        (_existing ?? GymExercise(name: _nameCtrl.text, type: _type)).copyWith(
      name: _nameCtrl.text.trim(),
      type: _type,
      instructions: _instructionsCtrl.text.trim(),
      video: video,
      clearVideo: video == null,
    );

    try {
      await ref.read(gymExercisesProvider.notifier).save(exercise);
      ref.read(gymSessionsProvider.notifier).refresh();
      if (mounted) Navigator.of(context).pop(exercise);
    } on DuplicateExerciseException catch (e) {
      setState(() => _error = e.toString());
    } catch (e) {
      setState(() => _error = 'Erreur : $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = _existing != null;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text(isEdit ? 'Modifier exercice' : 'Nouvel exercice'),
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: Form(
          key: _formKey,
          child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.all(20),
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Nom *'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Nom obligatoire' : null,
                textCapitalization: TextCapitalization.sentences,
                onTapOutside: (_) =>
                    FocusManager.instance.primaryFocus?.unfocus(),
              ),
              const SizedBox(height: 16),
              const Text('Type *', style: AppTypography.labelMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: GymExerciseType.values
                    .map((t) => ChoiceChip(
                          label: Text(t.label),
                          selected: _type == t,
                          onSelected: (s) {
                            if (s) setState(() => _type = t);
                          },
                        ))
                    .toList(),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _instructionsCtrl,
                decoration: const InputDecoration(labelText: 'Instructions'),
                maxLines: 4,
                onTapOutside: (_) =>
                    FocusManager.instance.primaryFocus?.unfocus(),
              ),
              const SizedBox(height: 16),
              const Text('Vidéo', style: AppTypography.labelMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('URL de la vidéo'),
                    selected: _videoMode == _VideoInputMode.url,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _videoMode = _VideoInputMode.url);
                      }
                    },
                  ),
                  ChoiceChip(
                    label: const Text('Vidéo locale'),
                    selected: _videoMode == _VideoInputMode.local,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _videoMode = _VideoInputMode.local);
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_videoMode == _VideoInputMode.url) ...[
                TextFormField(
                  controller: _videoUrlCtrl,
                  decoration: const InputDecoration(
                    labelText: 'URL de la vidéo',
                    hintText: 'https://… (.mp4, YouTube, Instagram, TikTok)',
                  ),
                  keyboardType: TextInputType.url,
                  onChanged: (_) => setState(() {}),
                  onTapOutside: (_) =>
                      FocusManager.instance.primaryFocus?.unfocus(),
                ),
                const SizedBox(height: 8),
                _VideoUrlHint(url: _videoUrlCtrl.text),
              ] else
                _LocalVideoPicker(
                  fileName: _pickedLocalName ?? _localVideo?.originalFileName,
                  onPick: _pickLocalVideo,
                  onClear: () {
                    setState(() {
                      _pickedLocalPath = null;
                      _pickedLocalName = null;
                      _localVideo = null;
                    });
                  },
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
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _save,
                child: Text(isEdit ? 'Enregistrer' : 'Créer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VideoUrlHint extends StatelessWidget {
  final String url;
  const _VideoUrlHint({required this.url});

  @override
  Widget build(BuildContext context) {
    if (url.trim().isEmpty) {
      return const SizedBox.shrink();
    }
    final source = ExerciseVideoDetector.detect(url);
    String message;
    Color color = AppColors.textSecondary;
    switch (source) {
      case ExerciseVideoSource.directUrl:
        if (ExerciseVideoDetector.isValidDirectVideoUrl(url)) {
          message = 'Cette vidéo sera lue dans l\'application.';
          color = AppColors.active;
        } else {
          message = 'Cette URL vidéo directe n\'est pas lisible.';
          color = AppColors.danger;
        }
        break;
      case ExerciseVideoSource.youtube:
        if (ExerciseVideoDetector.extractYoutubeId(url) == null) {
          message =
              'URL YouTube sans identifiant de vidéo. Colle un lien complet (ex: youtube.com/watch?v=…).';
          color = AppColors.danger;
        } else {
          message = 'Cette vidéo YouTube sera affichée via le player YouTube.';
          color = AppColors.active;
        }
        break;
      case ExerciseVideoSource.platformLink:
        message =
            'Ce lien sera ouvert dans une vue web ou une application externe.';
        color = AppColors.resting;
        break;
      case ExerciseVideoSource.localFile:
        message = 'Fichier local conservé.';
        break;
      case ExerciseVideoSource.unknown:
        message = 'URL non reconnue.';
        color = AppColors.danger;
        break;
    }
    return Text(message, style: AppTypography.bodySmall.copyWith(color: color));
  }
}

class _LocalVideoPicker extends StatelessWidget {
  final String? fileName;
  final VoidCallback onPick;
  final VoidCallback onClear;

  const _LocalVideoPicker({
    required this.fileName,
    required this.onPick,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final hasFile = fileName != null && fileName!.isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            hasFile ? fileName! : 'Aucune vidéo locale sélectionnée',
            style: AppTypography.bodyMedium,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: onPick,
                icon: const Icon(Icons.video_library_outlined),
                label: Text(hasFile ? 'Changer la vidéo' : 'Choisir une vidéo'),
              ),
              if (hasFile)
                TextButton.icon(
                  onPressed: onClear,
                  icon: const Icon(Icons.close),
                  label: const Text('Retirer'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
