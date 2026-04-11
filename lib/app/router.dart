import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/workouts/presentation/home_screen.dart';
import '../features/workouts/presentation/workout_editor_screen.dart';
import '../features/workouts/presentation/workout_type_screen.dart';
import '../features/timer/presentation/active_session_screen.dart';
import '../features/voice/presentation/voice_settings_screen.dart';
import '../core/models/workout_block.dart';

abstract class AppRoutes {
  static const home = '/';
  static const workoutNew = '/workout/new';
  static const workoutNewPyramid = '/workout/new/pyramid';
  static const workoutEdit = '/workout/:id';
  static const session = '/session';
  static const voice = '/voice';
}

final appRouter = GoRouter(
  initialLocation: AppRoutes.home,
  debugLogDiagnostics: false,
  routes: [
    GoRoute(
      path: AppRoutes.home,
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: AppRoutes.workoutNew,
      builder: (context, state) => const WorkoutTypeScreen(),
    ),
    GoRoute(
      path: AppRoutes.workoutNewPyramid,
      builder: (context, state) => const WorkoutEditorScreen(
        initialBlockType: BlockType.pyramid,
      ),
    ),
    GoRoute(
      path: AppRoutes.workoutEdit,
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return WorkoutEditorScreen(sessionId: id);
      },
    ),
    GoRoute(
      path: AppRoutes.session,
      builder: (context, state) => const ActiveSessionScreen(),
    ),
    GoRoute(
      path: AppRoutes.voice,
      builder: (context, state) => const VoiceSettingsScreen(),
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    body: Center(
      child: Text('Page introuvable : ${state.error}'),
    ),
  ),
);

// Helpers de navigation
extension AppNavigation on BuildContext {
  void goHome() => go(AppRoutes.home);
  void goNewWorkout() => push(AppRoutes.workoutNew);
  void goNewPyramidWorkout() => push(AppRoutes.workoutNewPyramid);
  void goEditWorkout(String id) => push('/workout/$id');
  void goSession() => go(AppRoutes.session);
  void goVoice() => go(AppRoutes.voice);
}
