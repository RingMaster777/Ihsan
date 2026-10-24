import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:tasks_for_allah/core/theme/app_palette.dart';
import 'package:tasks_for_allah/core/utils/date_helpers.dart';
import 'package:tasks_for_allah/core/widgets/animated_counter.dart';
import 'package:tasks_for_allah/core/widgets/app_card.dart';
import 'package:tasks_for_allah/core/widgets/entrance_animation.dart';
import 'package:tasks_for_allah/core/widgets/gradient_button.dart';
import 'package:tasks_for_allah/core/widgets/progress_ring.dart';
import 'package:tasks_for_allah/core/widgets/tfa_header.dart';
import 'package:tasks_for_allah/features/profile/domain/person.dart';
import 'package:tasks_for_allah/features/profile/presentation/widgets/person_avatar.dart';
import 'package:tasks_for_allah/features/tracker/application/tracker_providers.dart';
import 'package:tasks_for_allah/features/tracker/domain/scoring.dart';
import 'package:tasks_for_allah/features/tracker/domain/stats.dart';
import 'package:tasks_for_allah/features/tracker/presentation/widgets/prayer_ui.dart';
import 'package:tasks_for_allah/features/tracker/presentation/widgets/week_chart.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final person = ref.watch(activeProfileProvider);
    if (person == null) return const SizedBox.shrink();

    final p = context.palette;
    final today = ref.watch(todayProvider);
    final summary = ref.watch(monthSummaryProvider((year: today.year, month: today.month)));
    final streak = ref.watch(streakProvider);
    final week = ref.watch(lastDaysProvider(7));
    final family = ref.watch(familyMonthPointsProvider);
    final monthName = formatMonth(today.year, today.month);

    final withPoints = family.entries.where((e) => e.value > 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final sections = <Widget>[
      _HeroCard(summary: summary, monthName: monthName),
      Row(
        children: [
          Expanded(
            child: _StatTile(
              icon: Icons.event_available_rounded,
              value: summary.daysLogged,
              label: 'Days logged',
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _StatTile(
              icon: Icons.local_fire_department_rounded,
              iconColor: const Color(0xFFF0731A),
              value: streak,
              label: 'Day streak',
            ),
          ),
        ],
      ),
      Row(
        children: [
          Expanded(
            child: _StatTile(
              icon: Icons.track_changes_rounded,
              value: summary.achievementPercent,
              suffix: '%',
              label: 'Achievement',
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _StatTile(
              icon: Icons.trending_up_rounded,
              value: summary.average,
              label: 'Avg pts / day',
            ),
          ),
        ],
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
            WeekChart(days: week, maxPoints: ScoringRules.maxDailyPoints(person.id)),
          ],
        ),
      ),
      _BreakdownCard(summary: summary, person: person),
      if (withPoints.length > 1) _FamilyBoard(rows: withPoints),
      _ShareCard(
        person: person,
        monthName: monthName,
        points: summary.points,
        streak: streak,
      ),
    ];

    return Column(
      children: [
        TfaHeader(subtitle: 'My Stats · $monthName'),
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

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.summary, required this.monthName});
  final MonthSummary summary;
  final String monthName;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: p.headerGradient,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: p.headerGradient.first.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            bottom: -24,
            child: Icon(Icons.auto_awesome_rounded,
                size: 120, color: Colors.white.withOpacity(0.07)),
          ),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnimatedCounter(
                        value: summary.points,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 54,
                          fontWeight: FontWeight.w800,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Points this month',
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        monthName,
                        style: const TextStyle(color: Colors.white60, fontSize: 11.5),
                      ),
                    ],
                  ),
                ),
                ProgressRing(
                  size: 92,
                  strokeWidth: 9,
                  progress: summary.achievementPercent / 100,
                  trackColor: Colors.white.withOpacity(0.2),
                  gradient: const [Colors.white, Color(0xFF9AF0E4)],
                  child: AnimatedCounter(
                    value: summary.achievementPercent,
                    suffix: '%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.value,
    required this.label,
    this.suffix = '',
    this.iconColor,
  });

  final IconData icon;
  final int value;
  final String label;
  final String suffix;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(color: p.chip, borderRadius: BorderRadius.circular(13)),
            child: Icon(icon, size: 22, color: iconColor ?? p.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedCounter(
                  value: value,
                  suffix: suffix,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: p.primaryStrong,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: p.textMuted, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BreakdownCard extends StatelessWidget {
  const _BreakdownCard({required this.summary, required this.person});
  final MonthSummary summary;
  final Person person;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.donut_small_rounded, color: p.primary, size: 20),
              const SizedBox(width: 8),
              const Text('Prayer Breakdown',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < summary.breakdown.length; i++)
            _BreakdownRow(item: summary.breakdown[i], index: i),
          if (person.id == PersonId.faisal && summary.prayedTotal > 0) ...[
            const Divider(height: 24),
            Row(
              children: [
                Icon(Icons.groups_rounded, size: 20, color: p.jamaat.fg),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${summary.jamaatCount} of ${summary.prayedTotal} prayers in congregation',
                    style: TextStyle(fontSize: 12.5, color: p.textBody),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({required this.item, required this.index});
  final PrayerBreakdown item;
  final int index;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final prayer = item.prayer;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: prayer.tint.withOpacity(0.16),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(prayer.icon, size: 18, color: prayer.tint),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 62,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(prayer.english,
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                Text(prayer.arabic, style: TextStyle(fontSize: 10.5, color: p.textMuted)),
              ],
            ),
          ),
          Expanded(
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: item.rate),
              duration: Duration(milliseconds: 700 + index * 90),
              curve: Curves.easeOutCubic,
              builder: (context, v, _) => Container(
                height: 9,
                margin: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: p.track,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: v.clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: p.ctaGradient),
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            width: 52,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${item.points} pts',
                    style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w800, color: p.primaryStrong)),
                Text('${(item.rate * 100).round()}%',
                    style: TextStyle(fontSize: 10.5, color: p.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FamilyBoard extends StatelessWidget {
  const _FamilyBoard({required this.rows});
  final List<MapEntry<PersonId, int>> rows;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    const medals = [Color(0xFFE0A800), Color(0xFF9AA5AB), Color(0xFFC17F4E)];
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.emoji_events_rounded, color: p.primary, size: 20),
              const SizedBox(width: 8),
              const Text('Family Board',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 10),
          for (var i = 0; i < rows.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Icon(Icons.workspace_premium_rounded,
                      color: medals[i.clamp(0, 2)], size: 24),
                  const SizedBox(width: 10),
                  PersonAvatar(
                    person: Person.of(rows[i].key),
                    size: 34,
                    borderWidth: 2,
                    shadow: false,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      Person.of(rows[i].key).name,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ),
                  Text(
                    '${rows[i].value} pts',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: p.primaryStrong,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ShareCard extends StatelessWidget {
  const _ShareCard({
    required this.person,
    required this.monthName,
    required this.points,
    required this.streak,
  });

  final Person person;
  final String monthName;
  final int points;
  final int streak;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AppCard(
      gradient: LinearGradient(colors: [p.chip, p.chip.withOpacity(0.6)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.diversity_3_rounded, color: p.primary, size: 20),
              const SizedBox(width: 8),
              Text('Family Comparison',
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700, color: p.primaryStrong)),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${person.name} — $monthName\n$points points',
            style: const TextStyle(fontSize: 15, height: 1.5),
          ),
          const SizedBox(height: 14),
          GradientButton(
            label: 'Share my progress',
            icon: Icons.ios_share_rounded,
            height: 46,
            onPressed: () => SharePlus.instance.share(
              ShareParams(
                text: '🌙 Tasks for Allah — ${person.name}\n'
                    '$monthName: $points points\n'
                    'Streak: $streak ${streak == 1 ? 'day' : 'days'} 🔥',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
