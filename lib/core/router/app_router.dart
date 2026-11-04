import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tasks_for_allah/core/router/app_shell.dart';
import 'package:tasks_for_allah/core/router/routes.dart';
import 'package:tasks_for_allah/features/profile/presentation/profile_picker_screen.dart';
import 'package:tasks_for_allah/features/settings/presentation/settings_screen.dart';
import 'package:tasks_for_allah/features/tracker/application/tracker_providers.dart';
import 'package:tasks_for_allah/features/tracker/presentation/entry/entry_screen.dart';
import 'package:tasks_for_allah/features/tracker/presentation/history/history_screen.dart';
import 'package:tasks_for_allah/features/tracker/presentation/home/home_screen.dart';
import 'package:tasks_for_allah/features/tracker/presentation/stats/stats_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

final routerProvider = Provider<GoRouter>((ref) {
  // Re-run `redirect` whenever the active person changes (pick / switch).
  final refresh = ValueNotifier<int>(0);
  ref.onDispose(refresh.dispose);
  ref.listen<String?>(activePersonProvider, (_, __) => refresh.value++);

  final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.home,
    refreshListenable: refresh,
    redirect: (context, state) {
      final person = ref.read(activePersonProvider);
      final atPicker = state.matchedLocation == AppRoutes.profiles;
      if (person == null) return atPicker ? null : AppRoutes.profiles;
      if (atPicker) return AppRoutes.home;
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.profiles,
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          transitionDuration: const Duration(milliseconds: 450),
          child: const ProfilePickerScreen(),
          transitionsBuilder: (context, animation, secondary, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      ),
      GoRoute(
        path: AppRoutes.entryPattern,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          transitionDuration: const Duration(milliseconds: 380),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          child: EntryScreen(dateKey: state.pathParameters['date'] ?? ''),
          transitionsBuilder: (context, animation, secondary, child) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );
            return SlideTransition(
              position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(curved),
              child: FadeTransition(opacity: curved, child: child),
            );
          },
        ),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: AppRoutes.home, builder: (context, state) => const HomeScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: AppRoutes.history, builder: (context, state) => const HistoryScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: AppRoutes.stats, builder: (context, state) => const StatsScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: AppRoutes.settings, builder: (context, state) => const SettingsScreen()),
          ]),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
