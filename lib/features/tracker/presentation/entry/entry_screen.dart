import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tasks_for_allah/core/theme/app_palette.dart';
import 'package:tasks_for_allah/core/utils/date_helpers.dart';
import 'package:tasks_for_allah/core/widgets/animated_counter.dart';
import 'package:tasks_for_allah/core/widgets/app_card.dart';
import 'package:tasks_for_allah/core/widgets/app_snack.dart';
import 'package:tasks_for_allah/core/widgets/entrance_animation.dart';
import 'package:tasks_for_allah/core/widgets/floral_background.dart';
import 'package:tasks_for_allah/core/widgets/gradient_button.dart';
import 'package:tasks_for_allah/core/widgets/pressable_scale.dart';
import 'package:tasks_for_allah/core/widgets/progress_ring.dart';
import 'package:tasks_for_allah/features/profile/domain/person.dart';
import 'package:tasks_for_allah/features/profile/presentation/widgets/person_avatar.dart';
import 'package:tasks_for_allah/features/tracker/application/tracker_providers.dart';
import 'package:tasks_for_allah/features/tracker/domain/day_entry.dart';
import 'package:tasks_for_allah/features/tracker/domain/prayer.dart';
import 'package:tasks_for_allah/features/tracker/domain/scoring.dart';
import 'package:tasks_for_allah/features/tracker/presentation/widgets/prayer_ui.dart';

/// Log (or edit) the prayers of one day.
class EntryScreen extends ConsumerStatefulWidget {
  const EntryScreen({super.key, required this.dateKey});

  final String dateKey;

  @override
  ConsumerState<EntryScreen> createState() => _EntryScreenState();
}

class _EntryScreenState extends ConsumerState<EntryScreen> {
  late final PersonId _personId;
  late final DateTime _date;
  late final DayEntry _initial;
  late final bool _existing;
  late DayEntry _draft;

  final ConfettiController _confetti =
      ConfettiController(duration: const Duration(milliseconds: 1600));
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _personId = ref.read(activePersonProvider) ?? PersonId.faisal;
    final today = ref.read(todayProvider);
    final parsed = tryParseDateKey(widget.dateKey);
    // Never allow logging in the future.
    _date = (parsed == null || parsed.isAfter(today)) ? today : parsed;
    final saved = ref.read(entriesProvider)[toDateKey(_date)];
    _existing = saved != null;
    _initial = saved ?? const DayEntry();
    _draft = _initial;
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  bool get _dirty => _draft != _initial;

  void _setStatus(PrayerType prayer, PrayerStatus status) {
    HapticFeedback.selectionClick();
    setState(() => _draft = _draft.withPrayer(prayer, status));
  }

  void _toggleBonus(String id) {
    HapticFeedback.selectionClick();
    setState(() => _draft = _draft.toggleBonus(id));
  }

  Future<bool> _confirmDiscard() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.edit_off_rounded),
        title: const Text('Discard changes?'),
        content: const Text('You have unsaved changes to this entry.'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep editing'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    HapticFeedback.mediumImpact();

    final entry = _draft.copyWith(updatedAt: DateTime.now().millisecondsSinceEpoch);
    await ref.read(trackerProvider.notifier).saveEntry(toDateKey(_date), entry);
    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final perfect = entry.isPerfect;
    if (perfect) {
      _confetti.play();
      await Future<void>.delayed(const Duration(milliseconds: 1500));
      if (!mounted) return;
    }
    showAppSnackOn(
      messenger,
      perfect ? 'MashaAllah! A perfect day 🌟' : 'Entry saved',
      icon: perfect ? Icons.celebration_rounded : Icons.check_circle_rounded,
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final person = Person.of(_personId);
    final today = ref.watch(todayProvider);
    final total = ScoringRules.entryPoints(_personId, _draft);
    final maxTotal = ScoringRules.maxDailyPoints(_personId);
    final canSave = _dirty || !_existing;

    final cards = <Widget>[
      for (final prayer in PrayerType.values)
        _PrayerLogCard(
          prayer: prayer,
          personId: _personId,
          chosen: _draft.isChosen(prayer) ? _draft.statusOf(prayer) : null,
          onSelect: (s) => _setStatus(prayer, s),
        ),
      if (ScoringRules.hasBonus(_personId))
        _BonusCard(selected: _draft.bonus, onToggle: _toggleBonus),
      _SummaryCard(
        total: total,
        maxTotal: maxTotal,
        isPerfect: _draft.isPerfect,
        hasBonus: ScoringRules.hasBonus(_personId),
        maxPrayer: ScoringRules.maxPrayerPointsPerDay(_personId),
        maxBonus: ScoringRules.maxBonusPoints,
      ),
    ];

    return PopScope(
      canPop: !_dirty,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final leave = await _confirmDiscard();
        if (leave && mounted) context.pop();
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Scaffold(
          body: FloralBackground(
            child: Stack(
              children: [
                Column(
                  children: [
                    _EntryHeader(
                      person: person,
                      date: _date,
                      today: today,
                      onBack: () => Navigator.of(context).maybePop(),
                    ),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(14, 16, 14, 20),
                        itemCount: cards.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, i) => EntranceAnimation(
                          delay: Duration(milliseconds: 55 * i),
                          offset: const Offset(0, 0.1),
                          child: cards[i],
                        ),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.fromLTRB(
                        16,
                        12,
                        16,
                        12 + MediaQuery.paddingOf(context).bottom,
                      ),
                      decoration: BoxDecoration(
                        color: p.card,
                        border: Border(top: BorderSide(color: p.cardBorder.withOpacity(0.6))),
                        boxShadow: [
                          BoxShadow(color: p.shadow, blurRadius: 16, offset: const Offset(0, -4)),
                        ],
                      ),
                      child: GradientButton(
                        label: _existing ? 'Save changes' : 'Save entry',
                        icon: Icons.check_rounded,
                        loading: _saving,
                        onPressed: canSave ? _save : null,
                      ),
                    ),
                  ],
                ),
                Align(
                  alignment: Alignment.topCenter,
                  child: ConfettiWidget(
                    confettiController: _confetti,
                    blastDirectionality: BlastDirectionality.explosive,
                    shouldLoop: false,
                    numberOfParticles: 28,
                    maxBlastForce: 22,
                    minBlastForce: 8,
                    gravity: 0.25,
                    colors: const [
                      Color(0xFF28A898),
                      Color(0xFF64C8E6),
                      Color(0xFFFFE870),
                      Color(0xFFF0A8B8),
                      Color(0xFF90E0C0),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EntryHeader extends StatelessWidget {
  const _EntryHeader({
    required this.person,
    required this.date,
    required this.today,
    required this.onBack,
  });

  final Person person;
  final DateTime date;
  final DateTime today;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: EdgeInsets.fromLTRB(8, MediaQuery.paddingOf(context).top + 8, 14, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: p.headerGradient,
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: p.headerGradient.first.withOpacity(0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Back',
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          ),
          Expanded(
            child: Column(
              children: [
                const Text(
                  'Prayer Log',
                  style: TextStyle(
                    fontFamily: 'Bliss',
                    color: Colors.white,
                    fontSize: 24,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${relativeDayLabel(date, today)} · ${formatLongDate(date)}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 11.5),
                ),
              ],
            ),
          ),
          PersonAvatar(
            person: person,
            size: 40,
            borderWidth: 2,
            borderColor: Colors.white70,
            shadow: false,
          ),
        ],
      ),
    );
  }
}

class _PrayerLogCard extends StatelessWidget {
  const _PrayerLogCard({
    required this.prayer,
    required this.personId,
    required this.chosen,
    required this.onSelect,
  });

  final PrayerType prayer;
  final PersonId personId;
  final PrayerStatus? chosen;
  final ValueChanged<PrayerStatus> onSelect;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final points = chosen == null ? 0 : ScoringRules.prayerPoints(personId, prayer, chosen!);
    final maxPoints = ScoringRules.maxPrayerPoints(personId, prayer);
    final tint = prayer.tint;

    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [tint.withOpacity(0.28), tint.withOpacity(0.12)],
                  ),
                ),
                child: Icon(prayer.icon, color: tint, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      prayer.english,
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${prayer.arabic} · ${prayer.timeLabel}',
                      style: TextStyle(fontSize: 12, color: p.textMuted),
                    ),
                  ],
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: points > 0 ? p.chip : p.track.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                  child: Text(
                    '$points / $maxPoints pts',
                    key: ValueKey(points),
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: points > 0 ? p.chipFg : p.textMuted,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              for (final status in ScoringRules.optionsFor(personId))
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: _OptionPill(
                      status: status,
                      points: ScoringRules.prayerPoints(personId, prayer, status),
                      selected: chosen == status,
                      onTap: () => onSelect(status),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OptionPill extends StatelessWidget {
  const _OptionPill({
    required this.status,
    required this.points,
    required this.selected,
    required this.onTap,
  });

  final PrayerStatus status;
  final int points;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final style = p.styleFor(status);
    final fg = selected ? style.fg : p.textMuted;

    return PressableScale(
      onTap: onTap,
      pressedScale: 0.94,
      haptic: false,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: selected ? style.bg : p.none.bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? style.border : p.none.border, width: selected ? 1.8 : 1.2),
          boxShadow: selected
              ? [BoxShadow(color: style.border.withOpacity(0.35), blurRadius: 10, offset: const Offset(0, 3))]
              : null,
        ),
        child: Column(
          children: [
            AnimatedScale(
              scale: selected ? 1.18 : 1,
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutBack,
              child: Icon(optionIcon(status), size: 20, color: fg),
            ),
            const SizedBox(height: 4),
            Text(
              status.label,
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: fg),
            ),
            const SizedBox(height: 1),
            Text(
              points > 0 ? '+$points pts' : '0 pts',
              style: TextStyle(fontSize: 10, color: fg.withOpacity(0.8)),
            ),
          ],
        ),
      ),
    );
  }
}

class _BonusCard extends StatelessWidget {
  const _BonusCard({required this.selected, required this.onToggle});

  final Set<String> selected;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AppCard(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: p.goldGradient),
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(color: p.gold),
                ),
                child: Icon(Icons.star_rounded, size: 19, color: p.goldFg),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Bonus Activities',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                'up to +${ScoringRules.maxBonusPoints}',
                style: TextStyle(fontSize: 11.5, color: p.textMuted, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 6),
          for (final b in ScoringRules.bonusActivities)
            _BonusTile(
              activity: b,
              checked: selected.contains(b.id),
              onTap: () => onToggle(b.id),
            ),
        ],
      ),
    );
  }
}

class _BonusTile extends StatelessWidget {
  const _BonusTile({required this.activity, required this.checked, required this.onTap});

  final BonusActivity activity;
  final bool checked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: checked ? p.chip : p.track.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  bonusIcon(activity.id),
                  size: 19,
                  color: checked ? p.primary : p.textMuted,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  activity.label,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: p.chip, borderRadius: BorderRadius.circular(8)),
                child: Text(
                  '+${activity.points}',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: p.chipFg),
                ),
              ),
              const SizedBox(width: 10),
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  gradient: checked ? LinearGradient(colors: p.ctaGradient) : null,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: checked ? p.primary : p.cardBorder,
                    width: 2,
                  ),
                ),
                child: AnimatedScale(
                  scale: checked ? 1 : 0,
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutBack,
                  child: const Icon(Icons.check_rounded, size: 17, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.total,
    required this.maxTotal,
    required this.isPerfect,
    required this.hasBonus,
    required this.maxPrayer,
    required this.maxBonus,
  });

  final int total;
  final int maxTotal;
  final bool isPerfect;
  final bool hasBonus;
  final int maxPrayer;
  final int maxBonus;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AppCard(
      padding: const EdgeInsets.all(18),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [p.chip, p.chip.withOpacity(p.isDark ? 0.5 : 0.7)],
      ),
      child: Row(
        children: [
          ProgressRing(
            size: 108,
            strokeWidth: 11,
            progress: maxTotal == 0 ? 0 : total / maxTotal,
            trackColor: p.card.withOpacity(p.isDark ? 0.4 : 0.8),
            gradient: [p.ctaGradient.first, p.ctaGradient.last, p.greenGradient.last],
            duration: const Duration(milliseconds: 600),
            child: AnimatedCounter(
              value: total,
              duration: const Duration(milliseconds: 450),
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w800,
                color: p.primaryStrong,
              ),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Points for this day',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: p.primaryStrong),
                ),
                const SizedBox(height: 4),
                Text(
                  hasBonus ? '$maxPrayer prayer + $maxBonus bonus pts max' : '$maxTotal pts max',
                  style: TextStyle(fontSize: 11.5, color: p.textBody),
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  child: isPerfect
                      ? Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Row(
                            children: [
                              const Icon(Icons.auto_awesome_rounded,
                                  size: 16, color: Color(0xFFE0A800)),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  'All five prayers — MashaAllah!',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: p.solo.fg,
                                  ),
                                ),
                              ),
                            ],
                          ).animate().fadeIn(duration: 300.ms).slideX(begin: -0.1, end: 0),
                        )
                      : const SizedBox(width: double.infinity),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
