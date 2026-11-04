import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tasks_for_allah/core/constants/app_constants.dart';
import 'package:tasks_for_allah/core/router/app_router.dart';
import 'package:tasks_for_allah/core/services/home_widget_service.dart';
import 'package:tasks_for_allah/core/theme/app_theme.dart';
import 'package:tasks_for_allah/features/settings/application/prayer_settings.dart';
import 'package:tasks_for_allah/features/settings/application/reminder.dart';
import 'package:tasks_for_allah/features/tracker/application/tracker_providers.dart';

class IhsanApp extends ConsumerStatefulWidget {
  const IhsanApp({super.key});

  @override
  ConsumerState<IhsanApp> createState() => _IhsanAppState();
}

class _IhsanAppState extends ConsumerState<IhsanApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _initNotifications());
  }

  Future<void> _initNotifications() async {
    final service = ref.read(notificationServiceProvider);
    await service.init();
    // Paint the home screen widget with whatever data is already on disk.
    await IhsanWidget.update(ref.read(trackerProvider));
    if (!mounted) return;
    if (ref.read(reminderProvider).enabled) {
      await service.requestPermission();
    }
    if (mounted) await ref.read(reminderCoordinatorProvider).sync();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Refresh "today" (the app may have been open across midnight).
      ref.read(nowProvider.notifier).state = DateTime.now();
      ref.read(reminderCoordinatorProvider).sync();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Re-schedule the reminder and refresh the home widget whenever relevant
    // state changes.
    ref.listen(trackerProvider, (_, next) {
      ref.read(reminderCoordinatorProvider).sync();
      IhsanWidget.update(next);
    });
    ref.listen(reminderProvider, (_, __) => ref.read(reminderCoordinatorProvider).sync());
    ref.listen(prayerSettingsProvider, (_, __) => ref.read(reminderCoordinatorProvider).sync());

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      routerConfig: ref.watch(routerProvider),
    );
  }
}
