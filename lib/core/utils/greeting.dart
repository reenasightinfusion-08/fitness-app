/// "Good morning" / "Good afternoon" / "Good evening", same breakpoints as
/// the prototype's `screens.today` (`h<12`, `h<17`).
String greetingForHour(int hour) {
  if (hour < 12) return 'Good morning';
  if (hour < 17) return 'Good afternoon';
  return 'Good evening';
}

const List<String> _weekdayNames = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

const List<String> _monthAbbreviations = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// "Saturday, 26 Sep" — the prototype's
/// `toLocaleDateString('en-IN', {weekday:'long', day:'numeric', month:'short'})`.
String friendlyDate(DateTime date) =>
    '${_weekdayNames[date.weekday - 1]}, '
    '${date.day} ${_monthAbbreviations[date.month - 1]}';
