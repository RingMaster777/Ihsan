import 'package:flutter/material.dart';
import 'package:tasks_for_allah/core/theme/app_palette.dart';
import 'package:tasks_for_allah/features/tracker/domain/prayer.dart';
import 'package:tasks_for_allah/features/tracker/presentation/widgets/prayer_ui.dart';

/// Small rounded square showing a prayer's status.
class StatusMark extends StatelessWidget {
  const StatusMark({super.key, required this.status, this.size = 18});

  final PrayerStatus? status;
  final double size;

  @override
  Widget build(BuildContext context) {
    final style = context.palette.styleFor(status);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: style.bg,
        borderRadius: BorderRadius.circular(size * 0.32),
      ),
      child: Icon(markIcon(status), size: size * 0.66, color: style.fg),
    );
  }
}
