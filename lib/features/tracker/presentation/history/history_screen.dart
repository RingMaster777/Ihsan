import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tasks_for_allah/core/router/routes.dart';
import 'package:tasks_for_allah/core/theme/app_palette.dart';
import 'package:tasks_for_allah/core/utils/date_helpers.dart';
import 'package:tasks_for_allah/core/widgets/animated_counter.dart';
import 'package:tasks_for_allah/core/widgets/pressable_scale.dart';
import 'package:tasks_for_allah/core/widgets/tfa_header.dart';
import 'package:tasks_for_allah/features/profile/domain/person.dart';
import 'package:tasks_for_allah/features/tracker/application/tracker_providers.dart';
import 'package:tasks_for_allah/features/tracker/domain/day_entry.dart';
import 'package:tasks_for_allah/features/tracker/domain/prayer.dart';
import 'package:tasks_for_allah/features/tracker/domain/scoring.dart';
import 'package:tasks_for_allah/features/tracker/domain/stats.dart';
import 'package:tasks_for_allah/features/tracker/presentation/widgets/day_row.dart';

enum _HistoryView { calendar, list }

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  late int _year;
  late int _month;
  int _direction = 1;
  _HistoryView _view = _HistoryView.calendar;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _year = now.year;
    _month = now.month;
  }

  bool _isCurrentMonth(DateTime today) => _year == today.year && _month == today.month;

  void _shift(int delta) {
    HapticFeedback.selectionClick();
    setState(() {
      _direction = delta;
      var m = _month + delta;
      var y = _year;
      if (m < 1) {
        m = 12;
        y--;
      } else if (m > 12) {
        m = 1;
        y++;
      }
      _year = y;
      _month = m;
    });
  }

  @override
  Widget build(BuildContext context) {
    final person = ref.watch(activeProfileProvider);
    if (person == null) return const SizedBox.shrink();

    final p = context.palette;
    final today = ref.watch(todayProvider);
    final entries = ref.watch(entriesProvider);
    final isCurrent = _isCurrentMonth(today);
    final monthPts = StatsCalculator.monthPoints(person.id, entries, _year, _month);

    void open(DateTime d) => context.push(AppRoutes.entry(toDateKey(d)));

    final content = _view == _HistoryView.calendar
        ? _CalendarGrid(
            year: _year,
            month: _month,
            today: today,
            person: person.id,
            entries: entries,
            onTap: open,
          )
        : _DayList(
            year: _year,
            month: _month,
            today: today,
            person: person.id,
            entries: entries,
            onTap: open,
          );

    return Column(
      children: [
        TfaHeader(subtitle: 'History · ${formatMonth(_year, _month)}'),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(14, 16, 14, 28),
            children: [
              Row(
                children: [
                  _ArrowButton(icon: Icons.chevron_left_rounded, onTap: () => _shift(-1)),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 280),
                      transitionBuilder: (child, anim) => FadeTransition(
                        opacity: anim,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: Offset(0.3 * _direction, 0),
                            end: Offset.zero,
                          ).animate(anim),
                          child: child,
                        ),
                      ),
                      child: Text(
                        formatMonth(_year, _month),
                        key: ValueKey('$_year-$_month'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                  _ArrowButton(
                    icon: Icons.chevron_right_rounded,
                    onTap: isCurrent ? null : () => _shift(1),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: p.chip,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.stars_rounded, size: 17, color: p.primary),
                        const SizedBox(width: 6),
                        AnimatedCounter(
                          value: monthPts,
                          suffix: ' pts',
                          duration: const Duration(milliseconds: 500),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: p.primaryStrong,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  _ViewToggle(
                    value: _view,
                    onChanged: (v) {
                      HapticFeedback.selectionClick();
                      setState(() => _view = v);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 320),
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: Offset(0.08 * _direction, 0),
                      end: Offset.zero,
                    ).animate(anim),
                    child: child,
                  ),
                ),
                child: KeyedSubtree(
                  key: ValueKey('$_year-$_month-${_view.name}'),
                  child: content,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ArrowButton extends StatelessWidget {
  const _ArrowButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AnimatedOpacity(
      opacity: onTap == null ? 0.3 : 1,
      duration: const Duration(milliseconds: 200),
      child: PressableScale(
        onTap: onTap,
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: p.card,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: p.cardBorder),
          ),
          child: Icon(icon, color: p.primary, size: 26),
        ),
      ),
    );
  }
}

class _ViewToggle extends StatelessWidget {
  const _ViewToggle({required this.value, required this.onChanged});
  final _HistoryView value;
  final ValueChanged<_HistoryView> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    Widget item(_HistoryView v, IconData icon, String label) {
      final selected = v == value;
      return GestureDetector(
        onTap: () => onChanged(v),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? p.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 17, color: selected ? Colors.white : p.textMuted),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : p.textMuted,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: p.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          item(_HistoryView.calendar, Icons.grid_view_rounded, 'Calendar'),
          item(_HistoryView.list, Icons.view_list_rounded, 'List'),
        ],
      ),
    );
  }
}

class _CalendarGrid extends StatelessWidget {
  const _CalendarGrid({
    required this.year,
    required this.month,
    required this.today,
    required this.person,
    required this.entries,
    required this.onTap,
  });

  final int year;
  final int month;
  final DateTime today;
  final PersonId person;
  final Map<String, DayEntry> entries;
  final ValueChanged<DateTime> onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final blanks = calendarLeadingBlanks(year, month);
    final days = daysInMonth(year, month);

    return Column(
      children: [
        Row(
          children: [
            for (final h in calendarHeaders())
              Expanded(
                child: Center(
                  child: Text(
                    h,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: p.textMuted,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: blanks + days,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
            childAspectRatio: 0.82,
          ),
          itemBuilder: (context, i) {
            if (i < blanks) return const SizedBox.shrink();
            final day = i - blanks + 1;
            final date = DateTime(year, month, day);
            return _DayCell(
              date: date,
              entry: entries[toDateKey(date)],
              person: person,
              isToday: isSameDay(date, today),
              isFuture: date.isAfter(today),
              index: i,
              onTap: () => onTap(date),
            );
          },
        ),
        const SizedBox(height: 16),
        const _Legend(),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.date,
    required this.entry,
    required this.person,
    required this.isToday,
    required this.isFuture,
    required this.index,
    required this.onTap,
  });

  final DateTime date;
  final DayEntry? entry;
  final PersonId person;
  final bool isToday;
  final bool isFuture;
  final int index;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final e = entry;
    final StatusStyle style;
    if (e == null) {
      style = p.none;
    } else if (person == PersonId.faisal && e.allPrayersAre(PrayerStatus.jamaat)) {
      style = p.jamaat;
    } else if (e.isPerfect) {
      style = p.solo;
    } else if (e.prayedCount == 0) {
      style = p.missed;
    } else {
      style = p.partial;
    }

    final cell = Opacity(
      opacity: isFuture ? 0.35 : 1,
      child: PressableScale(
        onTap: isFuture ? null : onTap,
        pressedScale: 0.92,
        child: Container(
          decoration: BoxDecoration(
            color: style.bg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isToday ? p.primary : style.border.withOpacity(e == null ? 0.5 : 1),
              width: isToday ? 2.2 : 1.2,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${date.day}',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: isToday ? FontWeight.w900 : FontWeight.w700,
                  color: style.fg,
                ),
              ),
              if (e != null)
                Text(
                  '${ScoringRules.entryPoints(person, e)}',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: style.fg.withOpacity(0.8),
                  ),
                ),
            ],
          ),
        ),
      ),
    );

    return cell
        .animate(delay: Duration(milliseconds: 8 * index))
        .fadeIn(duration: 250.ms)
        .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1), duration: 300.ms);
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    Widget item(StatusStyle s, String label) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: s.bg,
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: s.border),
              ),
            ),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 11.5, color: p.textBody)),
          ],
        );

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 14,
      runSpacing: 8,
      children: [
        item(p.solo, 'All five'),
        item(p.partial, 'Some'),
        item(p.missed, 'None'),
        item(p.none, 'Not logged'),
      ],
    );
  }
}

class _DayList extends StatelessWidget {
  const _DayList({
    required this.year,
    required this.month,
    required this.today,
    required this.person,
    required this.entries,
    required this.onTap,
  });

  final int year;
  final int month;
  final DateTime today;
  final PersonId person;
  final Map<String, DayEntry> entries;
  final ValueChanged<DateTime> onTap;

  @override
  Widget build(BuildContext context) {
    final days = daysInMonth(year, month);
    return Column(
      children: [
        for (var d = days; d >= 1; d--)
          Builder(builder: (context) {
            final date = DateTime(year, month, d);
            return DayRow(
              date: date,
              entry: entries[toDateKey(date)],
              person: person,
              isToday: isSameDay(date, today),
              isFuture: date.isAfter(today),
              onTap: () => onTap(date),
            );
          }),
      ],
    );
  }
}
