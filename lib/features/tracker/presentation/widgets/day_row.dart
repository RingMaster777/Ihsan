import 'package:flutter/material.dart';
import 'package:tasks_for_allah/core/theme/app_palette.dart';
import 'package:tasks_for_allah/core/utils/date_helpers.dart';
import 'package:tasks_for_allah/core/widgets/pressable_scale.dart';
import 'package:tasks_for_allah/features/profile/domain/person.dart';
import 'package:tasks_for_allah/features/tracker/domain/day_entry.dart';
import 'package:tasks_for_allah/features/tracker/domain/prayer.dart';
import 'package:tasks_for_allah/features/tracker/domain/scoring.dart';
import 'package:tasks_for_allah/features/tracker/presentation/widgets/status_mark.dart';

/// One day as a row: date, five status marks and points.
class DayRow extends StatelessWidget {
  const DayRow({
    super.key,
    required this.date,
    required this.entry,
    required this.person,
    required this.onTap,
    this.isToday = false,
    this.isFuture = false,
  });

  final DateTime date;
  final DayEntry? entry;
  final PersonId person;
  final VoidCallback onTap;
  final bool isToday;
  final bool isFuture;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final points = entry == null ? null : ScoringRules.entryPoints(person, entry);

    return Opacity(
      opacity: isFuture ? 0.4 : 1,
      child: PressableScale(
        onTap: isFuture ? null : onTap,
        pressedScale: 0.98,
        child: Container(
          margin: const EdgeInsets.only(bottom: 7),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: p.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isToday ? p.primary : p.cardBorder.withOpacity(0.5),
              width: isToday ? 1.6 : 1,
            ),
            boxShadow: [
              BoxShadow(color: p.shadow, blurRadius: 10, offset: const Offset(0, 3)),
            ],
          ),
          child: Row(
            children: [
              SizedBox(
                width: 96,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      formatShortDate(date),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    if (isToday)
                      Text(
                        'Today',
                        style: TextStyle(fontSize: 10, color: p.primary, fontWeight: FontWeight.w700),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (final prayer in PrayerType.values)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2.5),
                        child: StatusMark(
                          status: entry == null ? null : entry!.statusOf(prayer),
                          size: 20,
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(
                width: 38,
                child: Text(
                  points == null ? '—' : '$points',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: points == null ? p.textMuted : p.primaryStrong,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
