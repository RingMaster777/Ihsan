import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tasks_for_allah/core/constants/app_constants.dart';
import 'package:tasks_for_allah/core/services/prayer_times_service.dart';
import 'package:tasks_for_allah/core/theme/app_palette.dart';
import 'package:tasks_for_allah/core/utils/date_helpers.dart';
import 'package:tasks_for_allah/core/widgets/app_card.dart';
import 'package:tasks_for_allah/core/widgets/app_snack.dart';
import 'package:tasks_for_allah/core/widgets/entrance_animation.dart';
import 'package:tasks_for_allah/core/widgets/tfa_header.dart';
import 'package:tasks_for_allah/features/profile/domain/person.dart';
import 'package:tasks_for_allah/features/profile/presentation/profile_edit_sheet.dart';
import 'package:tasks_for_allah/features/profile/presentation/widgets/person_avatar.dart';
import 'package:tasks_for_allah/features/tracker/domain/prayer.dart';
import 'package:tasks_for_allah/features/settings/application/prayer_settings.dart';
import 'package:tasks_for_allah/features/settings/application/reminder.dart';
import 'package:tasks_for_allah/features/settings/data/backup_service.dart';
import 'package:tasks_for_allah/features/tracker/application/tracker_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final person = ref.watch(activeProfileProvider);
    if (person == null) return const SizedBox.shrink();

    final p = context.palette;
    final reminder = ref.watch(reminderProvider);
    final profiles = ref.watch(profilesProvider);
    final prayerSettings = ref.watch(prayerSettingsProvider);
    final prayerTimes = ref.watch(prayerTimesTodayProvider);

    final sections = <Widget>[
      _ProfileCard(
        person: person,
        onSwitch: () async {
          final ok = await _confirm(
            context,
            title: 'Switch person?',
            message: 'Everyone keeps their own records on this device. '
                'Nothing will be deleted.',
            confirmLabel: 'Switch',
          );
          if (ok) await ref.read(trackerProvider.notifier).clearPerson();
        },
        onEdit: () => showProfileEditSheet(context, existing: person),
      ),
      _Section(
        title: 'Family profiles',
        children: [
          for (final profile in profiles)
            _Tile(
              icon: Icons.person_rounded,
              iconColor: p.tone(profile.accent),
              title: profile.name + (profile.id == person.id ? '  ·  using now' : ''),
              subtitle: profile.role,
              leading: PersonAvatar(profile: profile, size: 40, borderWidth: 0, shadow: false),
              onTap: () async {
                if (profile.id == person.id) {
                  showProfileEditSheet(context, existing: profile);
                  return;
                }
                await ref.read(trackerProvider.notifier).selectPerson(profile.id);
                if (context.mounted) {
                  showAppSnack(context, 'Now tracking ${profile.name} 🌸',
                      icon: Icons.swap_horiz_rounded);
                }
              },
              trailing: IconButton(
                tooltip: 'Edit',
                icon: Icon(Icons.edit_rounded,
                    size: 19, color: p.tone(profile.accent)),
                onPressed: () => showProfileEditSheet(context, existing: profile),
              ),
            ),
          _Tile(
            icon: Icons.person_add_rounded,
            title: 'Add profile',
            subtitle: 'Track another family member',
            trailing: Icon(Icons.add_rounded, color: p.textMuted),
            onTap: () => showProfileEditSheet(context),
          ),
        ],
      ),
      _Section(
        title: 'Prayer times',
        children: [
          _Tile(
            icon: Icons.location_on_rounded,
            title: 'City',
            subtitle: '${prayerSettings.city.name}, ${prayerSettings.city.country}',
            trailing: Icon(Icons.chevron_right_rounded, color: p.textMuted),
            onTap: () => _pickCity(context, ref),
          ),
          _Tile(
            icon: Icons.calculate_rounded,
            title: 'Calculation method',
            subtitle: prayerSettings.method.label,
            trailing: Icon(Icons.chevron_right_rounded, color: p.textMuted),
            onTap: () => _pickMethod(context, ref),
          ),
          _Tile(
            icon: Icons.menu_book_rounded,
            title: 'Asr calculation',
            subtitle: prayerSettings.madhab == AsrMadhab.hanafi
                ? 'Hanafi (standard in South Asia)'
                : 'Shafi\'i / Standard',
            trailing: SegmentedButton<AsrMadhab>(
              segments: const [
                ButtonSegment(value: AsrMadhab.hanafi, label: Text('Hanafi')),
                ButtonSegment(value: AsrMadhab.shafi, label: Text('Shafi')),
              ],
              selected: {prayerSettings.madhab},
              showSelectedIcon: false,
              onSelectionChanged: (selection) =>
                  ref.read(prayerSettingsProvider.notifier).setMadhab(selection.first),
            ),
          ),
          _Tile(
            icon: Icons.notifications_active_rounded,
            title: 'Prayer reminders',
            subtitle: 'A nudge at each prayer time',
            trailing: Switch(
              value: prayerSettings.notifyPrayers,
              onChanged: (v) async {
                await ref.read(prayerSettingsProvider.notifier).setNotifyPrayers(v);
                if (v) {
                  await ref.read(notificationServiceProvider).requestPermission();
                }
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (final prayer in PrayerType.values)
                  Column(
                    children: [
                      Text(prayer.abbreviation,
                          style: TextStyle(
                              fontSize: 10, fontWeight: FontWeight.w800, color: p.textMuted)),
                      const SizedBox(height: 2),
                      Text(formatClock(prayerTimes.timeFor(prayer)),
                          style: TextStyle(
                              fontSize: 10.5, fontWeight: FontWeight.w700, color: p.textBody)),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
      _Section(
        title: 'Reminder',
        children: [
          _Tile(
            icon: Icons.notifications_active_rounded,
            title: 'Daily reminder',
            subtitle: 'A gentle nudge if today is not logged yet',
            trailing: Switch(
              value: reminder.enabled,
              onChanged: (v) async {
                await ref.read(reminderProvider.notifier).setEnabled(v);
                if (v) {
                  final granted = await ref.read(notificationServiceProvider).requestPermission();
                  if (!granted && context.mounted) {
                    showAppSnack(
                      context,
                      'Notifications are blocked. Enable them in system settings.',
                      icon: Icons.notifications_off_rounded,
                      error: true,
                    );
                  }
                }
              },
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            child: reminder.enabled
                ? _Tile(
                    icon: Icons.schedule_rounded,
                    title: 'Reminder time',
                    subtitle: reminder.time.format(context),
                    trailing: Icon(Icons.chevron_right_rounded, color: p.textMuted),
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: reminder.time,
                      );
                      if (picked != null) {
                        await ref.read(reminderProvider.notifier).setTime(picked);
                      }
                    },
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
      _Section(
        title: 'Your data',
        children: [
          _Tile(
            icon: Icons.ios_share_rounded,
            title: 'Back up',
            subtitle: 'Export a JSON file you can save or send',
            trailing: Icon(Icons.chevron_right_rounded, color: p.textMuted),
            onTap: () => _backup(context, ref),
          ),
          _Tile(
            icon: Icons.settings_backup_restore_rounded,
            title: 'Restore',
            subtitle: 'Import a backup (also works with the old HTML app)',
            trailing: Icon(Icons.chevron_right_rounded, color: p.textMuted),
            onTap: () => _restore(context, ref),
          ),
          _Tile(
            icon: Icons.delete_forever_rounded,
            iconColor: p.missed.fg,
            title: 'Erase all entries',
            subtitle: 'Removes records for everyone on this device',
            trailing: Icon(Icons.chevron_right_rounded, color: p.textMuted),
            onTap: () async {
              final ok = await _confirm(
                context,
                title: 'Erase everything?',
                message: 'All prayer records for every person on this device will be '
                    'permanently deleted. Consider backing up first.',
                confirmLabel: 'Erase',
                destructive: true,
              );
              if (ok) {
                await ref.read(trackerProvider.notifier).resetAll();
                if (context.mounted) {
                  showAppSnack(context, 'All entries erased', icon: Icons.delete_rounded);
                }
              }
            },
          ),
        ],
      ),
      const _AboutCard(),
    ];

    return Column(
      children: [
        const TfaHeader(subtitle: 'Settings'),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(14, 16, 14, 28),
            itemCount: sections.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (context, i) => EntranceAnimation(
              delay: Duration(milliseconds: 60 * i),
              child: sections[i],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickCity(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(prayerSettingsProvider.notifier);
    final city = await showDialog<City>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Choose your city'),
        children: [
          for (final c in Cities.list)
            SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop(c),
              child: Text('${c.name}  ·  ${c.country}',
                  style: const TextStyle(fontSize: 14.5)),
            ),
        ],
      ),
    );
    if (city != null) await notifier.setCity(city);
  }

  Future<void> _pickMethod(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(prayerSettingsProvider.notifier);
    final method = await showDialog<CalcMethod>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Calculation method'),
        children: [
          for (final m in CalcMethod.values)
            SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop(m),
              child: Text(m.label, style: const TextStyle(fontSize: 14.5)),
            ),
        ],
      ),
    );
    if (method != null) await notifier.setMethod(method);
  }

  Future<void> _backup(BuildContext context, WidgetRef ref) async {    try {
      final repo = ref.read(trackerRepositoryProvider);
      await BackupService(repo).exportAndShare(ref.read(trackerProvider));
    } catch (_) {
      if (context.mounted) {
        showAppSnack(context, 'Could not create the backup', error: true, icon: Icons.error_rounded);
      }
    }
  }

  Future<void> _restore(BuildContext context, WidgetRef ref) async {
    try {
      final repo = ref.read(trackerRepositoryProvider);
      final data = await BackupService(repo).pickBackup();
      if (data == null || !context.mounted) return;
      final ok = await _confirm(
        context,
        title: 'Restore this backup?',
        message: 'It contains ${data.totalEntries} entries. This replaces the records '
            'currently on this device.',
        confirmLabel: 'Restore',
      );
      if (!ok) return;
      await ref.read(trackerProvider.notifier).restore(data);
      if (context.mounted) showAppSnack(context, 'Backup restored');
    } on FormatException {
      if (context.mounted) {
        showAppSnack(context, 'That file is not a valid backup.',
            error: true, icon: Icons.error_rounded);
      }
    } catch (_) {
      if (context.mounted) {
        showAppSnack(context, 'Could not read the file.', error: true, icon: Icons.error_rounded);
      }
    }
  }
}

Future<bool> _confirm(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  bool destructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: destructive
              ? FilledButton.styleFrom(backgroundColor: const Color(0xFFB03838))
              : null,
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.person, required this.onSwitch, required this.onEdit});

  final Profile person;
  final VoidCallback onSwitch;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final accent = p.tone(person.accent);
    return AppCard(
      borderColor: person.accentSoft,
      child: Row(
        children: [
          PersonAvatar(profile: person, size: 64, borderColor: person.accentSoft),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(person.name,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: accent)),
                Text(person.role, style: TextStyle(fontSize: 12.5, color: p.textMuted)),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Edit profile',
            onPressed: onEdit,
            icon: Icon(Icons.edit_rounded, size: 20, color: accent),
          ),
          OutlinedButton.icon(
            onPressed: onSwitch,
            icon: const Icon(Icons.swap_horiz_rounded, size: 18),
            label: const Text('Switch'),
            style: OutlinedButton.styleFrom(
              foregroundColor: accent,
              side: BorderSide(color: person.accentSoft, width: 1.6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(6, 0, 0, 8),
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              letterSpacing: 1.1,
              fontWeight: FontWeight.w700,
              color: p.textMuted,
            ),
          ),
        ),
        AppCard(padding: const EdgeInsets.symmetric(vertical: 6), child: Column(children: children)),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.leading,
    this.onTap,
    this.iconColor,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;

  /// Optional avatar that replaces the default icon box.
  final Widget? leading;
  final VoidCallback? onTap;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              leading ??
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: p.chip,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(icon, size: 21, color: iconColor ?? p.primary),
                  ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: TextStyle(fontSize: 11.5, color: p.textMuted)),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
      ),
    );
  }
}

class _AboutCard extends StatelessWidget {
  const _AboutCard();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Image.asset('assets/images/logo.jpg', width: 58, height: 58),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(AppConstants.appName, style: TextStyle(fontFamily: 'Bliss', fontSize: 20)),
            const SizedBox(width: 8),
            Text(AppConstants.appNameArabic, style: TextStyle(fontSize: 15, color: p.textBody)),
          ],
        ),
        const SizedBox(height: 2),
        Text('Version 1.0.0', style: TextStyle(fontSize: 11.5, color: p.textMuted)),
        const SizedBox(height: 6),
        Text(
          AppConstants.tagline,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11.5, color: p.textBody),
        ),
        const SizedBox(height: 6),
        Text(
          'Made with love for the family 🤍',
          style: TextStyle(fontSize: 12, color: p.textBody),
        ),
      ],
    );
  }
}
