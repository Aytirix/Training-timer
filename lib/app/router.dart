import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/workouts/presentation/workout_editor_screen.dart';
import '../features/workouts/presentation/workout_type_screen.dart';
import '../features/timer/presentation/active_session_screen.dart';
import '../features/voice/presentation/voice_settings_screen.dart';
import '../features/gym_execution/presentation/active_gym_session_screen.dart';
import '../core/models/workout_block.dart';
import 'main_tab_screen.dart';

abstract class AppRoutes {
  static const home = '/';
  static const workoutNew = '/workout/new';
  static const workoutNewPyramid = '/workout/new/pyramid';
  static const workoutEdit = '/workout/:id';
  static const session = '/session';
  static const voice = '/voice';
  static const gym = '/gym';
  static const gymSession = '/gym/session/:id';
}

final appRouter = GoRouter(
  initialLocation: AppRoutes.home,
  debugLogDiagnostics: false,
  routes: [
    GoRoute(
      path: AppRoutes.home,
      builder: (context, state) => const MainTabScreen(),
    ),
    GoRoute(
      path: AppRoutes.gym,
      builder: (context, state) => const MainTabScreen(initialIndex: 1),
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
    GoRoute(
      path: AppRoutes.gymSession,
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return ActiveGymSessionScreen(sessionId: id);
      },
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    body: Center(
      child: Text('Page introuvable : ${state.error}'),
    ),
  ),
);

extension AppNavigation on BuildContext {
  void goHome() => go(AppRoutes.home);
  void goNewWorkout() => push(AppRoutes.workoutNew);
  void goNewPyramidWorkout() => push(AppRoutes.workoutNewPyramid);
  void goEditWorkout(String id) => push('/workout/$id');
  void goSession() => go(AppRoutes.session);
  void goVoice() => go(AppRoutes.voice);
  void goGym() => go(AppRoutes.gym);
  void goActiveGymSession(String id) => push('/gym/session/$id');
}
