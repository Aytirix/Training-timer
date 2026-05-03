import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../features/gym/presentation/gym_sessions_screen.dart';
import '../features/workouts/presentation/home_screen.dart';

/// Coquille de navigation à onglets : Minuteurs / Séances.
///
/// Garde l'état des deux onglets via [IndexedStack].
class MainTabScreen extends StatefulWidget {
  final int initialIndex;
  const MainTabScreen({super.key, this.initialIndex = 0});

  @override
  State<MainTabScreen> createState() => _MainTabScreenState();
}

class _MainTabScreenState extends State<MainTabScreen> {
  late int _index = widget.initialIndex;

  static const _pages = <Widget>[
    HomeScreen(),
    GymSessionsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: NavigationBar(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.accentMuted,
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.timer_outlined),
            selectedIcon: Icon(Icons.timer),
            label: 'Minuteurs',
          ),
          NavigationDestination(
            icon: Icon(Icons.fitness_center_outlined),
            selectedIcon: Icon(Icons.fitness_center),
            label: 'Séances',
          ),
        ],
      ),
    );
  }
}
