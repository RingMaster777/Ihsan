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
import 'package:tasks_for_allah/features/tracker/domain/achievements.dart';
import 'package:tasks_for_allah/features/tracker/domain/scoring.dart';
import 'package:tasks_for_allah/features/tracker/domain/stats.dart';
import 'package:tasks_for_allah/features/tracker/presentation/widgets/prayer_ui.dart';
import 'package:tasks_for_allah/features/tracker/presentation/widgets/week_chart.dart';

/// Monthly points target per profile; `0` means "auto" (a perfect month).
final _goalProvider = StateProvider.family<int, String>((ref, profileId) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return prefs.getInt('tfa_goal_$profileId') ?? 0;
});

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
      _GoalCard(person: person, summary: summary),
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
            WeekChart(days: week, maxPoints: ScoringRules.maxDailyPoints(person)),
          ],
        ),
      ),
      _BreakdownCard(summary: summary, person: person),
      if (withPoints.length > 1) _FamilyBoard(rows: withPoints),
      _AchievementsCard(person: person),
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
                        format: formatPoints,
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

class _GoalCard extends ConsumerWidget {
  const _GoalCard({required this.person, required this.summary});

  final Profile person;
  final MonthSummary summary;

  Future<void> _editGoal(BuildContext context, WidgetRef ref, int current) async {
    final controller = TextEditingController(text: current == 0 ? '' : '$current');
    final auto = (ScoringRules.maxDailyPoints(person) *
            daysInMonth(DateTime.now().year, DateTime.now().month))
        .round();
    final entered = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Monthly goal'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Target points for this month. Leave empty for a '
                'perfect-month goal ($auto pts).'),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Goal points',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(
              int.tryParse(controller.text.trim()) ?? 0,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (entered == null) return;
    ref.read(_goalProvider(person.id).notifier).state = entered;
    await ref
        .read(sharedPreferencesProvider)
        .setInt('tfa_goal_${person.id}', entered);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final rawGoal = ref.watch(_goalProvider(person.id));
    final autoGoal = (ScoringRules.maxDailyPoints(person) *
            daysInMonth(DateTime.now().year, DateTime.now().month))
        .round();
    final goal = rawGoal > 0 ? rawGoal : autoGoal;
    final progress = (summary.points / goal).clamp(0.0, 1.0);
    final done = summary.points >= goal;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.flag_rounded, color: done ? p.primary : p.textMuted, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('Monthly goal',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
              ),
              IconButton(
                tooltip: 'Edit goal',
                icon: Icon(Icons.edit_rounded, size: 18, color: p.textMuted),
                onPressed: () => _editGoal(context, ref, rawGoal),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: progress),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOutCubic,
            builder: (context, v, _) => Container(
              height: 12,
              decoration: BoxDecoration(
                color: p.track,
                borderRadius: BorderRadius.circular(6),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: v,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: p.ctaGradient),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                done ? 'Goal reached — MashaAllah! 🎉' : 'Keep going',
                style: TextStyle(fontSize: 12, color: p.textBody),
              ),
              const Spacer(),
              Text(
                '${formatPoints(summary.points)} / $goal pts',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: done ? p.primaryStrong : p.textBody,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AchievementsCard extends ConsumerWidget {
  const _AchievementsCard({required this.person});

  final Profile person;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final entries = ref.watch(entriesProvider);
    final achievements = Achievements.forProfile(person, entries);
    final unlocked = achievements.where((a) => a.unlocked).length;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.military_tech_rounded, color: p.goldFg, size: 22),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('Achievements',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: p.chip, borderRadius: BorderRadius.circular(10)),
                child: Text(
                  '$unlocked / ${achievements.length}',
                  style: TextStyle(
                      fontSize: 11.5, fontWeight: FontWeight.w800, color: p.primaryStrong),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 10,
            children: [
              for (final a in achievements)
                _AchievementChip(achievement: a),
            ],
          ),
        ],
      ),
    );
  }
}

class _AchievementChip extends StatelessWidget {
  const _AchievementChip({required this.achievement});

  final Achievement achievement;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final a = achievement;
    final icon = switch (a.def.metric) {
      AchievementMetric.loggedDays => Icons.event_available_rounded,
      AchievementMetric.perfectDays => Icons.workspace_premium_rounded,
      AchievementMetric.bestStreak => Icons.local_fire_department_rounded,
      AchievementMetric.fajrDays => Icons.wb_twilight_rounded,
      AchievementMetric.jamaatCount => Icons.groups_rounded,
      AchievementMetric.bonusCount => Icons.star_rounded,
      AchievementMetric.totalPoints => Icons.emoji_events_rounded,
    };

    return Tooltip(
      message: a.def.description,
      child: Container(
        width: 104,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: a.unlocked ? p.chip : p.track.withOpacity(0.3),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: a.unlocked ? p.primary.withOpacity(0.5) : p.cardBorder,
            width: a.unlocked ? 1.6 : 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: a.unlocked ? LinearGradient(colors: p.goldGradient) : null,
                color: a.unlocked ? null : p.track,
              ),
              child: Icon(icon,
                  size: 18,
                  color: a.unlocked ? p.goldFg : p.textMuted),
            ),
            const SizedBox(height: 6),
            Text(
              a.def.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: a.unlocked ? p.primaryStrong : p.textBody,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              a.unlocked ? '✓ done' : '${a.progress}/${a.def.target}',
              style: TextStyle(fontSize: 10, color: p.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

class _BreakdownCard extends StatelessWidget {
  const _BreakdownCard({required this.summary, required this.person});
  final MonthSummary summary;
  final Profile person;

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
          if (person.mode == TrackingMode.jamaat && summary.prayedTotal > 0) ...[
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
  final List<MapEntry<Profile, double>> rows;

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
                    profile: rows[i].key,
                    size: 34,
                    borderWidth: 2,
                    shadow: false,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      rows[i].key.name,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ),
                  Text(
                    '${formatPoints(rows[i].value)} pts',
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

  final Profile person;
  final String monthName;
  final double points;
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
            '${person.name} — $monthName\n${formatPoints(points)} points',
            style: const TextStyle(fontSize: 15, height: 1.5),
          ),
          const SizedBox(height: 14),
          GradientButton(
            label: 'Share my progress',
            icon: Icons.ios_share_rounded,
            height: 46,
            onPressed: () => SharePlus.instance.share(
              ShareParams(
                text: '🌙 Ihsan — ${person.name}\n'
                    '$monthName: ${formatPoints(points)} points\n'
                    'Streak: $streak ${streak == 1 ? 'day' : 'days'} 🔥',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
