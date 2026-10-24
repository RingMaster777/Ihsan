import 'package:tasks_for_allah/core/constants/app_constants.dart';

const _months = [
  'January', 'February', 'March', 'April', 'May', 'June', 'July', 'August',
  'September', 'October', 'November', 'December',
];
const _monthsShort = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];
const _weekdays = [
  'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
];
const _weekdaysShort = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

String _two(int n) => n.toString().padLeft(2, '0');

/// `yyyy-MM-dd` key used for storage.
String toDateKey(DateTime d) => '${d.year}-${_two(d.month)}-${_two(d.day)}';

DateTime? tryParseDateKey(String key) {
  final parts = key.split('-');
  if (parts.length != 3) return null;
  final y = int.tryParse(parts[0]);
  final m = int.tryParse(parts[1]);
  final d = int.tryParse(parts[2]);
  if (y == null || m == null || d == null) return null;
  if (m < 1 || m > 12 || d < 1 || d > 31) return null;
  return DateTime(y, m, d);
}

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
DateTime addDays(DateTime d, int days) => DateTime(d.year, d.month, d.day + days);
bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// Number of days in [month] (1-based).
int daysInMonth(int year, int month) => DateTime(year, month + 1, 0).day;

String formatShortDate(DateTime d) =>
    '${_weekdaysShort[d.weekday - 1]}, ${_two(d.day)} ${_monthsShort[d.month - 1]}';

String formatLongDate(DateTime d) =>
    '${_weekdays[d.weekday - 1]}, ${d.day} ${_months[d.month - 1]} ${d.year}';

/// [month] is 1-based.
String formatMonth(int year, int month) => '${_months[month - 1]} $year';

String weekdayShort(DateTime d) => _weekdaysShort[d.weekday - 1];
String weekdayInitial(DateTime d) => _weekdaysShort[d.weekday - 1][0];

/// Weekday headers for the calendar grid, honouring [AppConstants.firstDayOfWeek].
List<String> calendarHeaders() => [
      for (var i = 0; i < 7; i++)
        _weekdaysShort[(AppConstants.firstDayOfWeek - 1 + i) % 7],
    ];

/// Leading blank cells before day 1 of the month in the calendar grid.
int calendarLeadingBlanks(int year, int month) {
  final weekday = DateTime(year, month, 1).weekday; // 1 = Monday
  return (weekday - AppConstants.firstDayOfWeek + 7) % 7;
}

String greetingFor(DateTime now) {
  final h = now.hour;
  if (h < 5) return 'Good Night';
  if (h < 12) return 'Good Morning';
  if (h < 17) return 'Good Afternoon';
  return 'Good Evening';
}

String relativeDayLabel(DateTime date, DateTime today) {
  final diff = dateOnly(today).difference(dateOnly(date)).inDays;
  if (diff == 0) return 'Today';
  if (diff == 1) return 'Yesterday';
  return formatShortDate(date);
}
