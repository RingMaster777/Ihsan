import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tasks_for_allah/core/constants/app_constants.dart';
import 'package:tasks_for_allah/core/router/routes.dart';
import 'package:tasks_for_allah/core/theme/app_palette.dart';
import 'package:tasks_for_allah/core/widgets/pressable_scale.dart';
import 'package:tasks_for_allah/features/profile/presentation/widgets/person_avatar.dart';
import 'package:tasks_for_allah/features/tracker/application/tracker_providers.dart';

/// Gradient app bar shared by the main tabs.
class TfaHeader extends ConsumerWidget {
  const TfaHeader({super.key, this.subtitle, this.big = false});

  final String? subtitle;
  final bool big;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final person = ref.watch(activeProfileProvider);
    final topInset = MediaQuery.paddingOf(context).top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: p.headerGradient,
          ),
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: p.headerGradient.first.withOpacity(0.35),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
          child: Stack(
            children: [
              Positioned(
                right: -34,
                top: -40,
                child: const _Bubble(size: 130, alpha: 0.07),
              ),
              Positioned(
                left: -26,
                bottom: -46,
                child: const _Bubble(size: 110, alpha: 0.06),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(14, topInset + 10, 14, big ? 18 : 14),
                child: Row(
                  children: [
                    SizedBox(
                      width: 96,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: person == null
                            ? const SizedBox.shrink()
                            : PressableScale(
                                onTap: () => context.go(AppRoutes.settings),
                                child: Container(
                                  padding: const EdgeInsets.fromLTRB(3, 3, 10, 3),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.16),
                                    borderRadius: BorderRadius.circular(22),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      PersonAvatar(
                                        profile: person,
                                        size: 28,
                                        borderWidth: 2,
                                        borderColor: Colors.white70,
                                        shadow: false,
                                      ),
                                      const SizedBox(width: 6),
                                      Flexible(
                                        child: Text(
                                          person.name,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            AppConstants.appName,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: AppConstants.titleFont,
                              color: Colors.white,
                              fontSize: big ? 26 : 20,
                              letterSpacing: 0.3,
                            ),
                          ),
                          if (subtitle != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                subtitle!,
                                style: const TextStyle(color: Colors.white70, fontSize: 11),
                              ),
                            ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 96,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.asset('assets/images/logo.jpg', width: 36, height: 36),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.size, required this.alpha});
  final double size;
  final double alpha;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(alpha),
        ),
      );
}
