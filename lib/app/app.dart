import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import 'router.dart';

class TrainingTimerApp extends StatelessWidget {
  const TrainingTimerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Training Timer',
      theme: AppTheme.dark,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        // Force le texte à rester lisible quelle que soit la taille système
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(
              MediaQuery.of(context).textScaler.scale(1.0).clamp(0.8, 1.2),
            ),
          ),
          child: child!,
        );
      },
    );
  }
}
