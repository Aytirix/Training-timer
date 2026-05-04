import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../../../core/models/gym/exercise_video.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../services/exercise_video_detector.dart';

class GymVideoPlayerScreen extends StatefulWidget {
  final ExerciseVideo video;
  final String title;

  const GymVideoPlayerScreen({
    super.key,
    required this.video,
    required this.title,
  });

  @override
  State<GymVideoPlayerScreen> createState() => _GymVideoPlayerScreenState();
}

class _GymVideoPlayerScreenState extends State<GymVideoPlayerScreen> {
  YoutubePlayerController? _youtubeController;
  late final ExerciseVideoSource _effectiveSource;
  bool _isFullScreen = false;

  @override
  void initState() {
    super.initState();
    _effectiveSource = _resolveSource(widget.video);
    final videoId = widget.video.url == null
        ? null
        : ExerciseVideoDetector.extractYoutubeId(widget.video.url!);
    if (_effectiveSource == ExerciseVideoSource.youtube && videoId != null) {
      _youtubeController = YoutubePlayerController(
        initialVideoId: videoId,
        flags: const YoutubePlayerFlags(
          autoPlay: true,
          mute: false,
          enableCaption: true,
          forceHD: false,
        ),
      )..addListener(_onControllerChanged);
    }
  }

  @override
  void deactivate() {
    _youtubeController?.pause();
    super.deactivate();
  }

  @override
  void dispose() {
    _youtubeController?.removeListener(_onControllerChanged);
    _youtubeController?.dispose();
    _restorePortraitOnly();
    super.dispose();
  }

  // ── Gestion plein écran custom ──
  //
  // Le `YoutubePlayerBuilder` du package v9 utilise `didChangeMetrics`, qui se
  // déclenche aussi quand les barres système se masquent — donc en portrait
  // pendant la rotation. Résultat : il sort tout seul du plein écran.
  // On se branche directement sur le contrôleur à la place.
  void _onControllerChanged() {
    final c = _youtubeController;
    if (c == null) return;
    final wantsFullScreen = c.value.isFullScreen;
    if (wantsFullScreen == _isFullScreen) return;
    setState(() => _isFullScreen = wantsFullScreen);
    if (wantsFullScreen) {
      SystemChrome.setPreferredOrientations(const [
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      _restorePortraitOnly();
    }
  }

  void _restorePortraitOnly() {
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  @override
  Widget build(BuildContext context) {
    final controller = _youtubeController;
    if (controller != null) {
      final player = YoutubePlayer(
        controller: controller,
        showVideoProgressIndicator: true,
        progressIndicatorColor: AppColors.accent,
        progressColors: const ProgressBarColors(
          playedColor: AppColors.accent,
          handleColor: AppColors.accent,
        ),
      );

      // Intercepte le bouton retour matériel pour sortir du plein écran d'abord.
      return PopScope(
        canPop: !_isFullScreen,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          if (_isFullScreen) controller.toggleFullScreenMode();
        },
        child: _isFullScreen
            ? Scaffold(
                backgroundColor: Colors.black,
                body: Center(child: player),
              )
            : _VideoScaffold(
                title: widget.title,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: player,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.video.url ?? '',
                      style: AppTypography.bodySmall,
                    ),
                  ],
                ),
              ),
      );
    }

    return _VideoScaffold(
      title: widget.title,
      child: _UnsupportedVideo(
        video: widget.video,
        effectiveSource: _effectiveSource,
      ),
    );
  }
}

ExerciseVideoSource _resolveSource(ExerciseVideo video) {
  if (video.source != ExerciseVideoSource.unknown) return video.source;
  final url = video.url;
  if (url == null || url.isEmpty) return ExerciseVideoSource.unknown;
  return ExerciseVideoDetector.detect(url);
}

class GymVideoLauncher extends StatelessWidget {
  final ExerciseVideo video;
  final String title;

  const GymVideoLauncher({
    super.key,
    required this.video,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceElevated,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => GymVideoPlayerScreen(
                video: video,
                title: title,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              const Icon(Icons.play_circle_outline, color: AppColors.accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  videoLabel(video),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySmall,
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }

  static String videoLabel(ExerciseVideo video) {
    final source = _resolveSource(video);
    if (source == ExerciseVideoSource.localFile) {
      return video.originalFileName ?? 'Vidéo locale';
    }
    if (source == ExerciseVideoSource.youtube) {
      return 'Lire la vidéo YouTube';
    }
    return video.url ?? 'Vidéo';
  }
}

class _VideoScaffold extends StatelessWidget {
  final String title;
  final Widget child;

  const _VideoScaffold({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        title: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: child,
        ),
      ),
    );
  }
}

class _UnsupportedVideo extends StatelessWidget {
  final ExerciseVideo video;
  final ExerciseVideoSource effectiveSource;

  const _UnsupportedVideo({
    required this.video,
    required this.effectiveSource,
  });

  @override
  Widget build(BuildContext context) {
    final message = switch (effectiveSource) {
      ExerciseVideoSource.localFile =>
        'La lecture des vidéos locales sera ajoutée avec le lecteur fichier.',
      ExerciseVideoSource.directUrl =>
        'Cette URL directe sera lue avec le lecteur vidéo intégré.',
      ExerciseVideoSource.platformLink =>
        'Cette plateforme ne fournit pas encore de lecteur intégré dans l’app.',
      ExerciseVideoSource.youtube =>
        'Impossible de récupérer l’identifiant de cette vidéo YouTube.',
      ExerciseVideoSource.unknown => 'Type de vidéo non reconnu.',
    };
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.play_disabled_outlined,
              color: AppColors.textSecondary),
          const SizedBox(height: 12),
          Text(message, style: AppTypography.bodyMedium),
          if (video.url != null) ...[
            const SizedBox(height: 12),
            Text(video.url!, style: AppTypography.bodySmall),
          ],
        ],
      ),
    );
  }
}
