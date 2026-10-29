enum Day {
  monday('Monday', 'Mon'),
  tuesday('Tuesday', 'Tue'),
  wednesday('Wednesday', 'Wed'),
  thursday('Thursday', 'Thu'),
  friday('Friday', 'Fri');

  const Day(this.label, this.short);
  final String label;
  final String short;
}

class Course {
  const Course({
    required this.id,
    required this.name,
    required this.day,
    required this.startMinutes,
    required this.endMinutes,
  });

  final String id;
  final String name;
  final Day day;
  final int startMinutes;
  final int endMinutes;

  int get durationMinutes => endMinutes - startMinutes;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'day': day.name,
      'start': startMinutes,
      'end': endMinutes,
    };
  }

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['id'] as String,
      name: json['name'] as String,
      day: Day.values.byName(json['day'] as String),
      startMinutes: json['start'] as int,
      endMinutes: json['end'] as int,
    );
  }
}

/// Two courses clash when they share a day and each one starts before the other ends.
/// `<` rather than `<=`, so a course ending at 11:00 and one starting at 11:00 do not clash.
bool clashes(Course a, Course b) {
  if (a.id == b.id || a.day != b.day) return false;
  return a.startMinutes < b.endMinutes && b.startMinutes < a.endMinutes;
}

List<Course> coursesOn(Day day, List<Course> courses) {
  final onDay = courses.where((course) => course.day == day).toList();
  onDay.sort((a, b) {
    final byStart = a.startMinutes.compareTo(b.startMinutes);
    if (byStart != 0) return byStart;
    final byEnd = a.endMinutes.compareTo(b.endMinutes);
    if (byEnd != 0) return byEnd;
    return a.name.compareTo(b.name);
  });
  return onDay;
}

List<String> clashNames(Course course, List<Course> courses) {
  final names = courses.where((other) => clashes(course, other)).toList()
    ..sort((a, b) {
      final byStart = a.startMinutes.compareTo(b.startMinutes);
      if (byStart != 0) return byStart;
      return a.name.compareTo(b.name);
    });
  return names.map((other) => other.name).toList();
}

String clashLabel(List<String> names) {
  if (names.isEmpty) return '';
  final joined = switch (names.length) {
    1 => names[0],
    2 => '${names[0]} and ${names[1]}',
    _ => '${names.sublist(0, names.length - 1).join(', ')} and ${names.last}',
  };
  return 'Clashes with $joined';
}

int totalMinutes(List<Course> courses) {
  return courses.fold(0, (sum, course) => sum + course.durationMinutes);
}

sealed class DayRow {}

class ClassRow extends DayRow {
  ClassRow(this.course);
  final Course course;
}

class FreeRow extends DayRow {
  FreeRow(this.startMinutes, this.endMinutes);
  final int startMinutes;
  final int endMinutes;
}

/// Classes in start-time order, with a free gap where one class ends before the next begins.
List<DayRow> dayRows(Day day, List<Course> courses) {
  final sorted = coursesOn(day, courses);
  final rows = <DayRow>[];
  for (var index = 0; index < sorted.length; index++) {
    if (index > 0) {
      final previousEnd = sorted[index - 1].endMinutes;
      final start = sorted[index].startMinutes;
      if (previousEnd < start) {
        rows.add(FreeRow(previousEnd, start));
      }
    }
    rows.add(ClassRow(sorted[index]));
  }
  return rows;
}

class WeekClash {
  const WeekClash(this.day, this.first, this.second);
  final Day day;
  final String first;
  final String second;
}

List<WeekClash> weekClashes(List<Course> courses) {
  final found = <WeekClash>[];
  for (final day in Day.values) {
    final onDay = coursesOn(day, courses);
    for (var i = 0; i < onDay.length; i++) {
      for (var j = i + 1; j < onDay.length; j++) {
        if (clashes(onDay[i], onDay[j])) {
          found.add(WeekClash(day, onDay[i].name, onDay[j].name));
        }
      }
    }
  }
  return found;
}

/// Three days, one real overlap, and a back-to-back pair that stays normal and totals 3h 30m.
List<Course> sampleCourses() {
  return const [
    Course(
      id: 'mobile',
      name: 'Mobile Programming',
      day: Day.monday,
      startMinutes: 8 * 60,
      endMinutes: 10 * 60,
    ),
    Course(
      id: 'databases',
      name: 'Databases',
      day: Day.monday,
      startMinutes: 10 * 60,
      endMinutes: 11 * 60 + 30,
    ),
    Course(
      id: 'physics',
      name: 'Physics',
      day: Day.tuesday,
      startMinutes: 9 * 60,
      endMinutes: 11 * 60,
    ),
    Course(
      id: 'maths',
      name: 'Mathematics',
      day: Day.tuesday,
      startMinutes: 10 * 60,
      endMinutes: 12 * 60,
    ),
    Course(
      id: 'english',
      name: 'English',
      day: Day.thursday,
      startMinutes: 13 * 60,
      endMinutes: 14 * 60 + 30,
    ),
    Course(
      id: 'chemistry',
      name: 'Chemistry',
      day: Day.thursday,
      startMinutes: 16 * 60,
      endMinutes: 17 * 60 + 30,
    ),
  ];
}
