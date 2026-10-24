import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:tasks_for_allah/core/router/routes.dart';
import 'package:tasks_for_allah/core/theme/app_palette.dart';
import 'package:tasks_for_allah/core/utils/date_helpers.dart';
import 'package:tasks_for_allah/core/widgets/entrance_animation.dart';
import 'package:tasks_for_allah/core/widgets/floral_background.dart';

/// Scaffold with the floral background, bottom navigation and the centre "Log" button.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _select(int index) {
    HapticFeedback.selectionClick();
    navigationShell.goBranch(index, initialLocation: index == navigationShell.currentIndex);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      body: FloralBackground(child: navigationShell),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: EntranceAnimation(
        delay: const Duration(milliseconds: 350),
        duration: const Duration(milliseconds: 700),
        offset: Offset.zero,
        scaleBegin: 0,
        curve: Curves.elasticOut,
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: p.ctaGradient,
            ),
            boxShadow: [
              BoxShadow(
                color: p.ctaGradient.last.withOpacity(0.5),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: FloatingActionButton(
            tooltip: 'Log prayers',
            elevation: 0,
            focusElevation: 0,
            hoverElevation: 0,
            highlightElevation: 0,
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            shape: const CircleBorder(),
            onPressed: () {
              HapticFeedback.mediumImpact();
              context.push(AppRoutes.entry(toDateKey(DateTime.now())));
            },
            child: const Icon(Icons.add_rounded, size: 34),
          ),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        height: 68,
        padding: EdgeInsets.zero,
        color: p.card,
        surfaceTintColor: Colors.transparent,
        shadowColor: p.shadow,
        elevation: 12,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: Row(
          children: [
            _NavItem(
              icon: Icons.home_rounded,
              label: 'Home',
              selected: navigationShell.currentIndex == 0,
              onTap: () => _select(0),
            ),
            _NavItem(
              icon: Icons.calendar_month_rounded,
              label: 'History',
              selected: navigationShell.currentIndex == 1,
              onTap: () => _select(1),
            ),
            const SizedBox(width: 72),
            _NavItem(
              icon: Icons.insights_rounded,
              label: 'Stats',
              selected: navigationShell.currentIndex == 2,
              onTap: () => _select(2),
            ),
            _NavItem(
              icon: Icons.settings_rounded,
              label: 'Settings',
              selected: navigationShell.currentIndex == 3,
              onTap: () => _select(3),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final color = selected ? p.primary : p.textMuted;

    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        child: InkResponse(
          onTap: onTap,
          radius: 36,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                width: selected ? 54 : 34,
                height: 30,
                decoration: BoxDecoration(
                  color: selected ? p.chip : Colors.transparent,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: AnimatedScale(
                  scale: selected ? 1.12 : 1,
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOutBack,
                  child: Icon(icon, size: 23, color: color),
                ),
              ),
              const SizedBox(height: 2),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 250),
                style: TextStyle(
                  fontFamily: 'Emirates',
                  fontSize: 10.5,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: color,
                ),
                child: Text(label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
