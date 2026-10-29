/// A clock time as minutes from midnight, or why the typed text was refused.
sealed class TimeResult {
  const TimeResult();
}

class TimeOk extends TimeResult {
  const TimeOk(this.minutes);
  final int minutes;
}

class TimeErr extends TimeResult {
  const TimeErr(this.message);
  final String message;
}

int minutes(int hour, int minute) => hour * 60 + minute;

/// Accepts only HH:MM. 8h, 25:00 and 10:75 are refused.
TimeResult parseTime(String text) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) {
    return const TimeErr('Enter a time like 08:00.');
  }
  final match = RegExp(r'^(\d{2}):(\d{2})$').firstMatch(trimmed);
  if (match == null) {
    return TimeErr('$trimmed is not a valid time. Use HH:MM, like 08:00.');
  }
  final hour = int.parse(match.group(1)!);
  final minute = int.parse(match.group(2)!);
  if (hour > 23) {
    return TimeErr('$trimmed is not a real time. Hours must be from 00 to 23.');
  }
  if (minute > 59) {
    return TimeErr('$trimmed is not a real time. Minutes must be from 00 to 59.');
  }
  return TimeOk(hour * 60 + minute);
}

String formatTime(int totalMinutes) {
  final hours = totalMinutes ~/ 60;
  final mins = totalMinutes % 60;
  return '${hours.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')}';
}

/// 210 minutes is "3h 30m". Exact hours drop the minutes.
String formatDuration(int totalMinutes) {
  final hours = totalMinutes ~/ 60;
  final mins = totalMinutes % 60;
  if (hours == 0) return '${mins}m';
  if (mins == 0) return '${hours}h';
  return '${hours}h ${mins}m';
}

String formatRange(int startMinutes, int endMinutes) {
  return '${formatTime(startMinutes)}–${formatTime(endMinutes)}';
}

/// Blank name, a bad time, or an end that is not after the start.
String? validationError(String name, String startText, String endText) {
  if (name.trim().isEmpty) return 'Enter a course name.';
  switch (parseTime(startText)) {
    case TimeErr(:final message):
      return message;
    case TimeOk(minutes: final startMinutes):
      switch (parseTime(endText)) {
        case TimeErr(:final message):
          return message;
        case TimeOk(minutes: final endMinutes):
          if (endMinutes <= startMinutes) {
            return 'End time must be after the start.';
          }
          return null;
      }
  }
}
