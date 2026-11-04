import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tasks_for_allah/core/constants/app_constants.dart';
import 'package:tasks_for_allah/core/theme/app_palette.dart';
import 'package:tasks_for_allah/core/widgets/floral_background.dart';
import 'package:tasks_for_allah/core/widgets/pressable_scale.dart';
import 'package:tasks_for_allah/features/profile/domain/person.dart';
import 'package:tasks_for_allah/features/profile/presentation/profile_edit_sheet.dart';
import 'package:tasks_for_allah/features/profile/presentation/widgets/person_avatar.dart';
import 'package:tasks_for_allah/features/tracker/application/tracker_providers.dart';

/// "Who is using this device?" screen. Profiles are created by the family —
/// there is no fixed list.
class ProfilePickerScreen extends ConsumerWidget {
  const ProfilePickerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final profiles = ref.watch(profilesProvider);

    final cards = <Widget>[
      for (final profile in profiles)
        _ProfileCard(
          profile: profile,
          onTap: () => ref.read(trackerProvider.notifier).selectPerson(profile.id),
        ),
      _AddProfileCard(
        onTap: () => showProfileEditSheet(context),
      ),
    ];

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
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            AppConstants.appName,
                            style: TextStyle(
                              fontFamily: AppConstants.titleFont,
                              fontSize: 32,
                              color: p.isDark ? p.textStrong : const Color(0xFF0A4848),
                            ),
                          ).animate(delay: 200.ms).fadeIn(duration: 500.ms).slideY(begin: 0.3, end: 0),
                          const SizedBox(width: 10),
                          Text(
                            AppConstants.appNameArabic,
                            style: TextStyle(
                              fontSize: 22,
                              color: p.isDark ? p.textStrong : const Color(0xFF0A4848),
                            ),
                          ).animate(delay: 300.ms).fadeIn(duration: 500.ms),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        AppConstants.tagline,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12.5, color: p.textBody),
                      ).animate(delay: 360.ms).fadeIn(duration: 500.ms),
                      const SizedBox(height: 22),
                      Text(
                        'Who is using this device?',
                        style: TextStyle(fontSize: 14, color: p.textBody),
                      ).animate(delay: 420.ms).fadeIn(duration: 500.ms),
                      const SizedBox(height: 18),
                      ...cards.animate(interval: 110.ms, delay: 520.ms).fadeIn(duration: 400.ms).slideX(
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
  const _ProfileCard({required this.profile, required this.onTap});

  final Profile profile;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final accent = p.tone(profile.accent);

    return PressableScale(
      onTap: onTap,
      pressedScale: 0.97,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: p.card,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: profile.accentSoft, width: 2),
          boxShadow: [BoxShadow(color: p.shadow, blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: Row(
          children: [
            PersonAvatar(profile: profile, size: 62),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.name,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: accent),
                  ),
                  const SizedBox(height: 3),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: profile.accentSoft.withOpacity(0.28),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      profile.role,
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
                color: profile.accentSoft.withOpacity(0.3),
              ),
              child: Icon(Icons.arrow_forward_rounded, color: accent, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddProfileCard extends StatelessWidget {
  const _AddProfileCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return PressableScale(
      onTap: onTap,
      pressedScale: 0.97,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: p.card.withOpacity(0.55),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: p.primary.withOpacity(0.4), width: 1.8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: p.ctaGradient),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            Text(
              'Add a new profile',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: p.primary),
            ),
          ],
        ),
      ),
    );
  }
}
