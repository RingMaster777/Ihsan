# Tasks for Allah — Flutter

A family prayer tracker: log the five daily prayers, earn points, build streaks, and see monthly progress.
Ported from the single-file HTML prototype with the same people, scoring rules and data format.

## Quick start

Requires **Flutter 3.22+** (Dart 3.4+).

```bash
./setup.sh        # creates android/ + ios/, patches Android for notifications,
                  # installs packages, generates icon + splash, runs tests
flutter run
```

`setup.sh` only wraps standard steps (`flutter create .`, `flutter pub get`, icon/splash generators).
If you prefer to do it by hand, see `tool/patch_android.py` for the Android manifest/Gradle edits that
`flutter_local_notifications` needs.

**iOS:** open `ios/Runner.xcworkspace` once to set your signing team. For reminders to appear while the
app is open, follow the iOS note in the [flutter_local_notifications readme](https://pub.dev/packages/flutter_local_notifications).

## Features

| Area | What you get |
|---|---|
| Profiles | Faisal, A'araf, Kakon — each with their own records and scoring |
| Home | Animated progress ring, prayer chips, streak, month points, 7-day chart, recent days |
| Log | Per-prayer status pills with live points, bonus activities (A'araf), unsaved-changes guard, confetti on a perfect day |
| History | Month calendar heat-map or list, tap any past day to edit |
| Stats | Hero card, achievement %, averages, per-prayer breakdown, Jamaat ratio (Faisal), family board, share |
| Settings | Switch person, daily reminder + time, backup / restore, erase |
| Polish | Light + dark themes, haptics, staggered entrances, tab/page transitions |

### Scoring (unchanged from the prototype)
- **Faisal:** Alone = 1, Jamaat = 2 per prayer.
- **A'araf:** Fajr 3, Dhuhr 2, Asr 2, Maghrib 2, Isha 3, plus bonus activities (up to +8).
- **Kakon:** Fajr 3, Dhuhr 2, Asr 2, Maghrib 2, Isha 2.

### Differences from the HTML prototype
- **"Save Data" (baking data into the HTML file) is gone** — a real app persists automatically. Use **Back up / Restore**.
- Backups use the **same JSON format**, so a backup from the HTML app restores here.
- The **streak** no longer resets to 0 in the morning before you've logged; it counts from yesterday until today is logged.
- **Achievement %** includes A'araf's bonus points in the maximum, so it can't exceed 100%.
- The reminder is a real scheduled notification (default 8 PM, configurable) and skips today once prayers are logged.

## Architecture

Feature-first, with a thin domain layer that has no Flutter dependencies except `foundation`.

```
lib/
  main.dart / app.dart          bootstrap, lifecycle, reminder sync
  core/
    router/                     go_router config, shell + bottom nav
    theme/                      palette tokens (light/dark) + ThemeData
    widgets/                    AppCard, GradientButton, ProgressRing, AnimatedCounter, …
    services/                   notification service
    utils/ constants/
  features/
    profile/                    Person model, picker screen
    tracker/
      domain/                   DayEntry, ScoringRules, StatsCalculator (pure Dart)
      data/                     TrackerRepository (SharedPreferences JSON)
      application/              Riverpod providers
      presentation/             home · entry · history · stats · widgets
    settings/                   reminder state, backup service, settings screen
test/domain_test.dart           scoring, streak, monthly stats, backup parsing
```

State: **Riverpod** (`Notifier`s). Navigation: **go_router** with a `StatefulShellRoute` (tabs keep state) and a
root-level entry route; the router redirects to the profile picker whenever no one is selected.

## Notes
- The **Emirates** and **Bliss** fonts were extracted from your HTML file into `assets/fonts/`. Check their
  licences before publishing the app publicly.
- Portrait-only (see `main.dart`); remove the orientation lock to support tablets/landscape.
- Targets Android and iOS. Reminders and file sharing aren't wired for web.
