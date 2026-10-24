import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tasks_for_allah/core/constants/app_constants.dart';
import 'package:tasks_for_allah/core/theme/app_palette.dart';
import 'package:tasks_for_allah/core/widgets/floral_background.dart';
import 'package:tasks_for_allah/core/widgets/pressable_scale.dart';
import 'package:tasks_for_allah/features/profile/domain/person.dart';
import 'package:tasks_for_allah/features/profile/presentation/widgets/person_avatar.dart';
import 'package:tasks_for_allah/features/tracker/application/tracker_providers.dart';

/// "Who is using this device?" screen.
class ProfilePickerScreen extends ConsumerWidget {
  const ProfilePickerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: p.isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        body: FloralBackground(
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: p.primary.withOpacity(0.28),
                              blurRadius: 30,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(30),
                          child: Image.asset('assets/images/logo.jpg', width: 104, height: 104),
                        ),
                      )
                          .animate()
                          .scale(
                            begin: const Offset(0.4, 0.4),
                            end: const Offset(1, 1),
                            duration: 900.ms,
                            curve: Curves.elasticOut,
                          )
                          .fadeIn(duration: 300.ms),
                      const SizedBox(height: 18),
                      Text(
                        AppConstants.appName,
                        style: TextStyle(
                          fontFamily: AppConstants.titleFont,
                          fontSize: 32,
                          color: p.isDark ? p.textStrong : const Color(0xFF0A4848),
                        ),
                      ).animate(delay: 200.ms).fadeIn(duration: 500.ms).slideY(begin: 0.3, end: 0),
                      const SizedBox(height: 4),
                      Text(
                        'بسم الله الرحمن الرحيم',
                        style: TextStyle(fontSize: 17, color: p.textBody),
                      ).animate(delay: 320.ms).fadeIn(duration: 500.ms),
                      const SizedBox(height: 22),
                      Text(
                        'Who is using this device?',
                        style: TextStyle(fontSize: 14, color: p.textBody),
                      ).animate(delay: 420.ms).fadeIn(duration: 500.ms),
                      const SizedBox(height: 18),
                      ...[
                        for (final person in Person.list)
                          _ProfileCard(
                            person: person,
                            onTap: () => ref.read(trackerProvider.notifier).selectPerson(person.id),
                          ),
                      ].animate(interval: 110.ms, delay: 520.ms).fadeIn(duration: 400.ms).slideX(
                            begin: 0.25,
                            end: 0,
                            duration: 450.ms,
                            curve: Curves.easeOutCubic,
                          ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.person, required this.onTap});

  final Person person;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final accent = p.tone(person.accent);

    return PressableScale(
      onTap: onTap,
      pressedScale: 0.97,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: p.card,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: person.accentSoft, width: 2),
          boxShadow: [BoxShadow(color: p.shadow, blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: Row(
          children: [
            PersonAvatar(person: person, size: 62),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    person.name,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: accent),
                  ),
                  const SizedBox(height: 3),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: person.accentSoft.withOpacity(0.28),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      person.role,
                      style: TextStyle(fontSize: 12, color: accent, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: person.accentSoft.withOpacity(0.3),
              ),
              child: Icon(Icons.arrow_forward_rounded, color: accent, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}
