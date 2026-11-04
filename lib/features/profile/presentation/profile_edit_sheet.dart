import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tasks_for_allah/core/theme/app_palette.dart';
import 'package:tasks_for_allah/core/widgets/app_snack.dart';
import 'package:tasks_for_allah/core/widgets/gradient_button.dart';
import 'package:tasks_for_allah/features/profile/domain/person.dart';
import 'package:tasks_for_allah/features/tracker/application/tracker_providers.dart';
import 'package:tasks_for_allah/features/tracker/domain/scoring.dart';
import 'package:tasks_for_allah/features/tracker/presentation/widgets/prayer_ui.dart';

/// Bottom sheet that creates a new profile or edits an existing one.
///
/// The tracking mode picks how prayers are logged (Jamaat 1/2 pts vs Simple
/// fixed pts) and resets the bonus list to that mode's defaults.
Future<void> showProfileEditSheet(BuildContext context, {Profile? existing}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _ProfileEditSheet(existing: existing),
  );
}

class _ProfileEditSheet extends ConsumerStatefulWidget {
  const _ProfileEditSheet({this.existing});

  final Profile? existing;

  @override
  ConsumerState<_ProfileEditSheet> createState() => _ProfileEditSheetState();
}

class _ProfileEditSheetState extends ConsumerState<_ProfileEditSheet> {
  late final TextEditingController _name;
  late final TextEditingController _role;
  late TrackingMode _mode;
  late Color _accent;
  late Map<String, double> _bonus;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.name ?? '');
    _role = TextEditingController(text: e?.role ?? '');
    _mode = e?.mode ?? TrackingMode.jamaat;
    _accent = e?.accent ?? ProfilePresets.accentChoices.first;
    _bonus = Map<String, double>.of(e?.bonus ?? ProfilePresets.defaultBonusFor(_mode));
  }

  @override
  void dispose() {
    _name.dispose();
    _role.dispose();
    super.dispose();
  }

  void _setMode(TrackingMode mode) {
    setState(() {
      _mode = mode;
      _bonus = Map<String, double>.of(ProfilePresets.defaultBonusFor(mode));
    });
  }

  void _toggleBonus(String id) {
    setState(() {
      if (_bonus.remove(id) == null) {
        _bonus[id] = BonusCatalog.defaultPoints(id, _mode);
      }
    });
  }

  Future<void> _delete() async {
    final profile = widget.existing;
    if (profile == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Delete ${profile.name}?'),
        content: const Text(
          'Their profile and all their prayer records on this device will be '
          'permanently deleted. Consider backing up first.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFB03838)),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await ref.read(trackerProvider.notifier).deleteProfile(profile.id);
    if (!mounted) return;
    Navigator.of(context).pop();
    showAppSnack(context, '${profile.name} deleted', icon: Icons.delete_rounded);
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      showAppSnack(context, 'Please give the profile a name', error: true);
      return;
    }
    final existing = widget.existing;
    final profile = (existing ?? ProfilePresets.blank(_mode)).copyWith(
      name: name,
      role: _role.text.trim().isEmpty ? 'Family' : _role.text.trim(),
      accent: _accent,
      mode: _mode,
      bonus: _bonus,
    );
    final notifier = ref.read(trackerProvider.notifier);
    if (existing == null) {
      await notifier.addProfile(profile);
    } else {
      await notifier.updateProfile(profile);
    }
    if (!mounted) return;
    Navigator.of(context).pop();
    showAppSnack(
      context,
      existing == null ? 'Welcome, $name! 🌸' : 'Profile updated',
      icon: Icons.favorite_rounded,
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final canDelete =
        widget.existing != null && ref.watch(profilesProvider).length > 1;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        decoration: BoxDecoration(
          color: p.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4.5,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: p.track,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              Text(
                widget.existing == null ? 'New profile' : 'Edit profile',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: p.textStrong),
              ),
              const SizedBox(height: 4),
              Text(
                'One profile per person you track — yourself, your children, anyone.',
                style: TextStyle(fontSize: 12, color: p.textMuted),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                maxLength: 24,
                decoration: InputDecoration(
                  labelText: 'Name',
                  counterText: '',
                  prefixIcon: Icon(Icons.person_rounded, color: _accent),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _role,
                textCapitalization: TextCapitalization.words,
                maxLength: 24,
                decoration: InputDecoration(
                  labelText: 'Role (e.g. Father, Daughter)',
                  counterText: '',
                  prefixIcon: Icon(Icons.family_restroom_rounded, color: _accent),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 20),
              Text('PRAYER LOGGING',
                  style: TextStyle(
                      fontSize: 11, letterSpacing: 1.1, fontWeight: FontWeight.w700, color: p.textMuted)),
              const SizedBox(height: 8),
              Row(
                children: [
                  for (final mode in TrackingMode.values) ...[
                    Expanded(
                      child: _ModeCard(
                        mode: mode,
                        selected: _mode == mode,
                        onTap: () => _setMode(mode),
                      ),
                    ),
                    if (mode != TrackingMode.values.last) const SizedBox(width: 10),
                  ],
                ],
              ),
              const SizedBox(height: 20),
              Text('COLOR',
                  style: TextStyle(
                      fontSize: 11, letterSpacing: 1.1, fontWeight: FontWeight.w700, color: p.textMuted)),
              const SizedBox(height: 10),
              Row(
                children: [
                  for (final color in ProfilePresets.accentChoices)
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: GestureDetector(
                        onTap: () => setState(() => _accent = color),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: color,
                            border: Border.all(
                              color: _accent == color ? p.textStrong : Colors.transparent,
                              width: 3,
                            ),
                          ),
                          child: _accent == color
                              ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
                              : null,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Text('BONUS ACTIVITIES',
                      style: TextStyle(
                          fontSize: 11,
                          letterSpacing: 1.1,
                          fontWeight: FontWeight.w700,
                          color: p.textMuted)),
                  const Spacer(),
                  Text(
                    'up to +${formatPoints(_bonus.values.fold(0.0, (a, b) => a + b))}',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: p.textMuted),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final id in BonusCatalog.ids)
                    _BonusChip(
                      id: id,
                      points: BonusCatalog.defaultPoints(id, _mode),
                      selected: _bonus.containsKey(id),
                      onTap: () => _toggleBonus(id),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              GradientButton(
                label: widget.existing == null ? 'Create profile' : 'Save changes',
                icon: Icons.check_rounded,
                onPressed: _save,
              ),
              if (canDelete) ...[
                const SizedBox(height: 10),
                Center(
                  child: TextButton.icon(
                    onPressed: _delete,
                    icon: const Icon(Icons.delete_forever_rounded,
                        size: 20, color: Color(0xFFB03838)),
                    label: const Text('Delete profile',
                        style: TextStyle(color: Color(0xFFB03838), fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({required this.mode, required this.selected, required this.onTap});

  final TrackingMode mode;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: selected ? p.chip : p.track.withOpacity(0.4),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? p.primary : p.cardBorder, width: selected ? 1.8 : 1.2),
        ),
        child: Column(
          children: [
            Icon(
              mode == TrackingMode.jamaat ? Icons.groups_rounded : Icons.child_care_rounded,
              size: 24,
              color: selected ? p.primary : p.textMuted,
            ),
            const SizedBox(height: 6),
            Text(
              mode == TrackingMode.jamaat ? 'Jamaat' : 'Simple',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                color: selected ? p.primaryStrong : p.textBody,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              mode == TrackingMode.jamaat ? 'Alone 1 · Jamaat 2 pts' : 'Prayed · fixed pts',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 9.5, color: p.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

class _BonusChip extends StatelessWidget {
  const _BonusChip({
    required this.id,
    required this.points,
    required this.selected,
    required this.onTap,
  });

  final String id;
  final double points;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? p.chip : p.track.withOpacity(0.35),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? p.primary : p.cardBorder, width: selected ? 1.6 : 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(bonusIcon(id), size: 16, color: selected ? p.primary : p.textMuted),
            const SizedBox(width: 6),
            Text(
              BonusCatalog.labels[id]!,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: selected ? p.primaryStrong : p.textBody,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              '+${formatPoints(points)}',
              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: p.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
