import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tasks_for_allah/core/constants/app_constants.dart';
import 'package:tasks_for_allah/core/router/routes.dart';
import 'package:tasks_for_allah/core/theme/app_palette.dart';
import 'package:tasks_for_allah/core/utils/date_helpers.dart';
import 'package:tasks_for_allah/core/widgets/animated_counter.dart';
import 'package:tasks_for_allah/core/widgets/app_card.dart';
import 'package:tasks_for_allah/core/widgets/empty_state.dart';
import 'package:tasks_for_allah/core/widgets/entrance_animation.dart';
import 'package:tasks_for_allah/core/widgets/gradient_button.dart';
import 'package:tasks_for_allah/core/widgets/pressable_scale.dart';
import 'package:tasks_for_allah/core/widgets/progress_ring.dart';
import 'package:tasks_for_allah/core/widgets/tfa_header.dart';
import 'package:tasks_for_allah/features/profile/domain/person.dart';
import 'package:tasks_for_allah/features/settings/application/prayer_settings.dart';
import 'package:tasks_for_allah/features/tracker/application/tracker_providers.dart';
import 'package:tasks_for_allah/features/tracker/domain/day_entry.dart';
import 'package:tasks_for_allah/features/tracker/domain/prayer.dart';
import 'package:tasks_for_allah/features/tracker/domain/scoring.dart';
import 'package:tasks_for_allah/features/tracker/presentation/widgets/day_row.dart';
import 'package:tasks_for_allah/features/tracker/presentation/widgets/prayer_ui.dart';
import 'package:tasks_for_allah/features/tracker/presentation/widgets/week_chart.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final person = ref.watch(activeProfileProvider);
    if (person == null) return const SizedBox.shrink();

    final p = context.palette;
    final now = ref.watch(nowProvider);
    final today = ref.watch(todayProvider);
    final entries = ref.watch(entriesProvider);
    final streak = ref.watch(streakProvider);
    final summary = ref.watch(monthSummaryProvider((year: today.year, month: today.month)));
    final week = ref.watch(lastDaysProvider(7));

    final todayKey = toDateKey(today);
    final todayEntry = entries[todayKey];
    final showReminder = now.hour >= 20 && todayEntry == null;

    final recent = <MapEntry<DateTime, DayEntry>>[
      for (var i = 1; i <= 7; i++)
        if (entries[toDateKey(addDays(today, -i))] != null)
          MapEntry(addDays(today, -i), entries[toDateKey(addDays(today, -i))]!),
    ];

    void openEntry(String key) => context.push(AppRoutes.entry(key));

    final sections = <Widget>[
      if (showReminder)
        _ReminderBanner(name: person.name, onTap: () => openEntry(todayKey)),
      _Greeting(greeting: greetingFor(now), person: person),
      _NextPrayerCard(now: now),
      _TodayCard(
        person: person,
        today: today,
        entry: todayEntry,
        onTap: () => openEntry(todayKey),
      ),
      IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: _MonthCard(points: summary.points)),
            const SizedBox(width: 12),
            _StreakCard(days: streak),
          ],
        ),
      ),
      AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bar_chart_rounded, color: p.primary, size: 20),
                const SizedBox(width: 8),
                const Text('Last 7 days',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 14),
            WeekChart(days: week, maxPoints: ScoringRules.maxDailyPoints(person)),
          ],
        ),
      ),
      if (recent.isNotEmpty)
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 0, 10),
              child: Row(
                children: [
                  Icon(Icons.history_rounded, size: 18, color: p.textMuted),
                  const SizedBox(width: 6),
                  Text(
                    'RECENT',
                    style: TextStyle(
                      fontSize: 11,
                      letterSpacing: 1.1,
                      fontWeight: FontWeight.w700,
                      color: p.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            for (final r in recent)
              DayRow(
                date: r.key,
                entry: r.value,
                person: person,
                onTap: () => openEntry(toDateKey(r.key)),
              ),
          ],
        )
      else if (todayEntry == null)
        const EmptyState(
          icon: Icons.mosque_rounded,
          message: 'No entries yet.\nLog your first prayers to begin your journey.',
        ),
    ];

    return Column(
      children: [
        const TfaHeader(subtitle: AppConstants.taglineShort, big: true),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(14, 16, 14, 28),
            itemCount: sections.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) => EntranceAnimation(
              delay: Duration(milliseconds: 60 * i),
              child: sections[i],
            ),
          ),
        ),
      ],
    );
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting({required this.greeting, required this.person});
  final String greeting;
  final Profile person;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: '$greeting, ', style: TextStyle(color: p.textBody, fontSize: 14)),
                  TextSpan(
                    text: person.name,
                    style: TextStyle(
                      color: p.textStrong,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Icon(Icons.local_florist_rounded, color: Color(0xFFE87BA0), size: 22)
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .rotate(begin: -0.04, end: 0.04, duration: 1800.ms, curve: Curves.easeInOut),
        ],
      ),
    );
  }
}

class _NextPrayerCard extends ConsumerWidget {
  const _NextPrayerCard({required this.now});

  final DateTime now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final settings = ref.watch(prayerSettingsProvider);
    final result = ref.watch(prayerTimesTodayProvider);
    final next = result.nextAfter(now);
    final nextTime = result.timeFor(next);
    final remaining = nextTime.difference(now);
    final allPassed = remaining.isNegative;

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [next.tint.withOpacity(0.3), next.tint.withOpacity(0.12)],
                  ),
                ),
                child: Icon(next.icon, color: next.tint, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'NEXT PRAYER${allPassed ? ' · TOMORROW' : ''}',
                      style: TextStyle(
                        fontSize: 10.5,
                        letterSpacing: 1,
                        fontWeight: FontWeight.w700,
                        color: p.textMuted,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: next.english,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                          ),
                          TextSpan(
                            text: '  ·  ${formatClock(nextTime)}',
                            style: TextStyle(fontSize: 14, color: p.textBody),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: p.chip,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  allPassed ? 'tomorrow' : 'in ${formatCountdown(remaining)}',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: p.primaryStrong,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              for (final prayer in PrayerType.values)
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    decoration: BoxDecoration(
                      color: prayer == next ? p.chip : p.track.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: prayer == next ? p.primary : Colors.transparent,
                        width: 1.4,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          prayer.abbreviation,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: prayer == next ? p.primary : p.textMuted,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          formatClock(result.timeFor(prayer)),
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: prayer == next ? FontWeight.w800 : FontWeight.w600,
                            color: prayer == next ? p.primaryStrong : p.textBody,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '🕌 ${settings.city.name}',
              style: TextStyle(fontSize: 9.5, color: p.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReminderBanner extends StatelessWidget {
  const _ReminderBanner({required this.name, required this.onTap});
  final String name;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: p.headerGradient),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: p.headerGradient.first.withOpacity(0.35),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.nights_stay_rounded, color: Colors.white, size: 28)
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(
                begin: const Offset(1, 1),
                end: const Offset(1.14, 1.14),
                duration: 1100.ms,
                curve: Curves.easeInOut,
              ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Time to record your prayers, $name',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
          ),
          const SizedBox(width: 8),
          PressableScale(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.22),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withOpacity(0.4)),
              ),
              child: const Text(
                'Log now',
                style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TodayCard extends StatelessWidget {
  const _TodayCard({
    required this.person,
    required this.today,
    required this.entry,
    required this.onTap,
  });

  final Profile person;
  final DateTime today;
  final DayEntry? entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final points = ScoringRules.entryPoints(person, entry);
    final maxPoints = ScoringRules.maxDailyPoints(person);
    final progress = maxPoints == 0 ? 0.0 : points / maxPoints;
    final hasEntry = entry != null;

    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          Row(
            children: [
              ProgressRing(
                size: 104,
                strokeWidth: 11,
                progress: progress,
                trackColor: p.track,
                gradient: [p.ctaGradient.first, p.ctaGradient.last, p.greenGradient.last],
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedCounter(
                      value: points,
                      format: formatPoints,
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: p.primaryStrong,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text('of ${formatPoints(maxPoints)}',
                        style: TextStyle(fontSize: 11, color: p.textMuted)),
                  ],
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "TODAY'S PRAYERS",
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 1,
                        fontWeight: FontWeight.w700,
                        color: p.textMuted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatShortDate(today),
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: hasEntry && entry!.isPerfect ? p.solo.bg : p.chip,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            hasEntry && entry!.isPerfect
                                ? Icons.celebration_rounded
                                : Icons.pending_actions_rounded,
                            size: 14,
                            color: hasEntry && entry!.isPerfect ? p.solo.fg : p.chipFg,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            hasEntry
                                ? (entry!.isPerfect
                                    ? 'Perfect day!'
                                    : '${entry!.prayedCount} of 5 prayed')
                                : 'Not logged yet',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: hasEntry && entry!.isPerfect ? p.solo.fg : p.chipFg,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              for (var i = 0; i < PrayerType.values.length; i++)
                Expanded(
                  child: _PrayerChip(
                    prayer: PrayerType.values[i],
                    status: hasEntry ? entry!.statusOf(PrayerType.values[i]) : null,
                    index: i,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          GradientButton(
            label: hasEntry ? "Edit today's entry" : "Log today's prayers",
            icon: hasEntry ? Icons.edit_rounded : Icons.mosque_rounded,
            colors: hasEntry ? p.greenGradient : p.ctaGradient,
            onPressed: onTap,
            height: 50,
          ),
        ],
      ),
    );
  }
}

class _PrayerChip extends StatelessWidget {
  const _PrayerChip({required this.prayer, required this.status, required this.index});

  final PrayerType prayer;
  final PrayerStatus? status;
  final int index;

  @override
  Widget build(BuildContext context) {
    final style = context.palette.styleFor(status);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 3),
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        color: style.bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: style.border, width: 1.4),
      ),
      child: Column(
        children: [
          Icon(prayer.icon, size: 15, color: style.fg.withOpacity(0.75)),
          const SizedBox(height: 3),
          Text(
            prayer.abbreviation,
            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: style.fg),
          ),
          const SizedBox(height: 5),
          Icon(markIcon(status), size: 19, color: style.fg),
        ],
      ),
    ).animate(delay: (280 + 70 * index).ms).scale(
          begin: const Offset(0.6, 0.6),
          end: const Offset(1, 1),
          duration: 420.ms,
          curve: Curves.easeOutBack,
        ).fadeIn(duration: 250.ms);
  }
}

class _MonthCard extends StatelessWidget {
  const _MonthCard({required this.points});
  final double points;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: p.chip, borderRadius: BorderRadius.circular(12)),
            child: Icon(Icons.stars_rounded, size: 20, color: p.primary),
          ),
          const SizedBox(height: 12),
          AnimatedCounter(
            value: points,
            format: formatPoints,
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              color: p.primaryStrong,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Points this month',
            style: TextStyle(fontSize: 11.5, color: p.textMuted, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _StreakCard extends StatelessWidget {
  const _StreakCard({required this.days});
  final int days;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final active = days > 0;
    return Container(
      width: 128,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: p.goldGradient,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: p.gold, width: 1.5),
        boxShadow: [BoxShadow(color: p.gold.withOpacity(0.22), blurRadius: 14, offset: const Offset(0, 5))],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Builder(builder: (context) {
            final flame = Icon(
              Icons.local_fire_department_rounded,
              size: 30,
              color: active ? const Color(0xFFF0731A) : p.goldFg.withOpacity(0.4),
            );
            if (!active) return flame;
            return flame
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scale(
                  begin: const Offset(1, 1),
                  end: const Offset(1.18, 1.18),
                  duration: 800.ms,
                  curve: Curves.easeInOut,
                );
          }),
          const SizedBox(height: 4),
          AnimatedCounter(
            value: days,
            style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: p.goldFg, height: 1.1),
          ),
          const SizedBox(height: 3),
          Text(
            'Day streak',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: p.goldFg),
          ),
        ],
      ),
    );
  }
}
