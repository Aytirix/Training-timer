import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
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

    if (_effectiveSource == ExerciseVideoSource.localFile &&
        widget.video.localPath != null) {
      return _VideoScaffold(
        title: widget.title,
        child: _NativeVideoView(
          source: _NativeVideoSource.file(widget.video.localPath!),
          caption: widget.video.originalFileName,
        ),
      );
    }

    if (_effectiveSource == ExerciseVideoSource.directUrl &&
        widget.video.url != null &&
        ExerciseVideoDetector.isValidDirectVideoUrl(widget.video.url!)) {
      return _VideoScaffold(
        title: widget.title,
        child: _NativeVideoView(
          source: _NativeVideoSource.network(widget.video.url!),
          caption: widget.video.url,
        ),
      );
    }

    if (_effectiveSource == ExerciseVideoSource.platformLink &&
        widget.video.url != null) {
      return _VideoScaffold(
        title: widget.title,
        child: _ExternalLinkView(url: widget.video.url!),
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
    if (source == ExerciseVideoSource.platformLink) {
      return 'Ouvrir le lien externe';
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

// ──────────── Lecteur natif (fichier local + URL directe .mp4) ────────────

class _NativeVideoSource {
  final String? filePath;
  final String? networkUrl;

  const _NativeVideoSource._({this.filePath, this.networkUrl});

  factory _NativeVideoSource.file(String path) =>
      _NativeVideoSource._(filePath: path);
  factory _NativeVideoSource.network(String url) =>
      _NativeVideoSource._(networkUrl: url);
}

class _NativeVideoView extends StatefulWidget {
  final _NativeVideoSource source;
  final String? caption;

  const _NativeVideoView({required this.source, this.caption});

  @override
  State<_NativeVideoView> createState() => _NativeVideoViewState();
}

class _NativeVideoViewState extends State<_NativeVideoView> {
  VideoPlayerController? _controller;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  Future<void> _initController() async {
    try {
      final src = widget.source;
      final controller = src.filePath != null
          ? VideoPlayerController.file(File(src.filePath!))
          : VideoPlayerController.networkUrl(Uri.parse(src.networkUrl!));
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      controller.addListener(() {
        if (mounted) setState(() {});
      });
      await controller.play();
      setState(() => _controller = controller);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Impossible de lire la vidéo : $e');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.danger),
        ),
        child: Text(_error!, style: AppTypography.bodyMedium),
      );
    }
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: AspectRatio(
            aspectRatio: controller.value.aspectRatio,
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                GestureDetector(
                  onTap: () {
                    controller.value.isPlaying
                        ? controller.pause()
                        : controller.play();
                  },
                  child: VideoPlayer(controller),
                ),
                VideoProgressIndicator(
                  controller,
                  allowScrubbing: true,
                  colors: const VideoProgressColors(
                    playedColor: AppColors.accent,
                  ),
                ),
                if (!controller.value.isPlaying)
                  const Center(
                    child: Icon(Icons.play_circle_filled,
                        color: Colors.white70, size: 64),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            IconButton(
              onPressed: () {
                controller.value.isPlaying
                    ? controller.pause()
                    : controller.play();
              },
              icon: Icon(controller.value.isPlaying
                  ? Icons.pause
                  : Icons.play_arrow),
            ),
            IconButton(
              onPressed: () => controller.seekTo(Duration.zero),
              icon: const Icon(Icons.replay),
            ),
            const Spacer(),
            Text(
              '${_fmt(controller.value.position)} / ${_fmt(controller.value.duration)}',
              style: AppTypography.bodySmall,
            ),
          ],
        ),
        if (widget.caption != null && widget.caption!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(widget.caption!, style: AppTypography.bodySmall),
        ],
      ],
    );
  }

  static String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final h = d.inHours;
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }
}

// ──────────── Lien externe (Instagram, TikTok, Vimeo…) ────────────

class _ExternalLinkView extends StatelessWidget {
  final String url;
  const _ExternalLinkView({required this.url});

  Future<void> _open(BuildContext context) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible d\'ouvrir le lien.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.open_in_new, color: AppColors.accent),
          const SizedBox(height: 12),
          const Text(
            'Cette plateforme ne fournit pas de lecteur intégré. La vidéo s\'ouvre dans l\'application native ou le navigateur.',
            style: AppTypography.bodyMedium,
          ),
          const SizedBox(height: 12),
          Text(url, style: AppTypography.bodySmall),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _open(context),
            icon: const Icon(Icons.open_in_new),
            label: const Text('Ouvrir le lien'),
          ),
        ],
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
        'Fichier local introuvable ou non chargé.',
      ExerciseVideoSource.directUrl =>
        'URL vidéo directe invalide. Vérifie qu\'elle pointe vers un fichier .mp4, .webm…',
      ExerciseVideoSource.platformLink =>
        'Lien externe sans URL valide.',
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
