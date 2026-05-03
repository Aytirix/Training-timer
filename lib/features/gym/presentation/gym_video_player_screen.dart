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

  @override
  void initState() {
    super.initState();
    final videoId = widget.video.url == null
        ? null
        : ExerciseVideoDetector.extractYoutubeId(widget.video.url!);
    if (widget.video.source == ExerciseVideoSource.youtube && videoId != null) {
      _youtubeController = YoutubePlayerController(
        initialVideoId: videoId,
        flags: const YoutubePlayerFlags(
          autoPlay: true,
          mute: false,
          enableCaption: true,
          forceHD: false,
        ),
      );
    }
  }

  @override
  void deactivate() {
    _youtubeController?.pause();
    super.deactivate();
  }

  @override
  void dispose() {
    _youtubeController?.dispose();
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _youtubeController;
    if (controller != null) {
      return YoutubePlayerBuilder(
        onExitFullScreen: () {
          SystemChrome.setPreferredOrientations(DeviceOrientation.values);
        },
        player: YoutubePlayer(
          controller: controller,
          showVideoProgressIndicator: true,
          progressIndicatorColor: AppColors.accent,
          progressColors: const ProgressBarColors(
            playedColor: AppColors.accent,
            handleColor: AppColors.accent,
          ),
        ),
        builder: (context, player) => _VideoScaffold(
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
      child: _UnsupportedVideo(video: widget.video),
    );
  }
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
    if (video.source == ExerciseVideoSource.localFile) {
      return video.originalFileName ?? 'Vidéo locale';
    }
    if (video.source == ExerciseVideoSource.youtube) {
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

  const _UnsupportedVideo({required this.video});

  @override
  Widget build(BuildContext context) {
    final message = switch (video.source) {
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
