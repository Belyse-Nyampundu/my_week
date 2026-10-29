import 'package:flutter_test/flutter_test.dart';
import 'package:mini_project/courses_api.dart';
import 'package:mini_project/schedule.dart';
import 'package:mini_project/times.dart';

void main() {
  test('back to back courses do not clash and total 3h 30m', () {
    final mobile = Course(
      id: 'mobile',
      name: 'Mobile Programming',
      day: Day.monday,
      startMinutes: minutes(8, 0),
      endMinutes: minutes(10, 0),
    );
    final databases = Course(
      id: 'databases',
      name: 'Databases',
      day: Day.monday,
      startMinutes: minutes(10, 0),
      endMinutes: minutes(11, 30),
    );
    final day = [mobile, databases];
    expect(clashes(mobile, databases), isFalse);
    expect(clashes(databases, mobile), isFalse);
    expect(formatDuration(totalMinutes(day)), '3h 30m');
    expect(clashNames(mobile, day), isEmpty);
    expect(clashNames(databases, day), isEmpty);
  });

  test('an overlap names both courses', () {
    final physics = Course(
      id: 'physics',
      name: 'Physics',
      day: Day.tuesday,
      startMinutes: minutes(9, 0),
      endMinutes: minutes(11, 0),
    );
    final maths = Course(
      id: 'maths',
      name: 'Mathematics',
      day: Day.tuesday,
      startMinutes: minutes(10, 0),
      endMinutes: minutes(12, 0),
    );
    final day = [physics, maths];
    expect(clashes(physics, maths), isTrue);
    expect(clashLabel(clashNames(physics, day)), 'Clashes with Mathematics');
    expect(clashLabel(clashNames(maths, day)), 'Clashes with Physics');
  });

  test('editing away the overlap clears the clash on both', () {
    final physics = Course(
      id: 'physics',
      name: 'Physics',
      day: Day.tuesday,
      startMinutes: minutes(9, 0),
      endMinutes: minutes(11, 0),
    );
    final maths = Course(
      id: 'maths',
      name: 'Mathematics',
      day: Day.tuesday,
      startMinutes: minutes(10, 0),
      endMinutes: minutes(12, 0),
    );
    expect(clashes(physics, maths), isTrue);
    final mathsLater = Course(
      id: maths.id,
      name: maths.name,
      day: maths.day,
      startMinutes: minutes(11, 0),
      endMinutes: minutes(12, 30),
    );
    final day = [physics, mathsLater];
    expect(clashes(physics, mathsLater), isFalse);
    expect(clashNames(physics, day), isEmpty);
    expect(clashNames(mathsLater, day), isEmpty);
  });

  test('courses on different days do not clash', () {
    final monday = Course(
      id: 'a',
      name: 'Lab',
      day: Day.monday,
      startMinutes: minutes(9, 0),
      endMinutes: minutes(11, 0),
    );
    final tuesday = Course(
      id: 'b',
      name: 'Lab',
      day: Day.tuesday,
      startMinutes: minutes(9, 0),
      endMinutes: minutes(11, 0),
    );
    expect(clashes(monday, tuesday), isFalse);
  });

  test('a course does not clash with itself', () {
    final lab = Course(
      id: 'a',
      name: 'Lab',
      day: Day.monday,
      startMinutes: minutes(9, 0),
      endMinutes: minutes(11, 0),
    );
    expect(clashes(lab, lab), isFalse);
  });

  test('an early course is shown before a later one', () {
    final later = Course(
      id: 'l',
      name: 'Later',
      day: Day.friday,
      startMinutes: minutes(15, 0),
      endMinutes: minutes(16, 0),
    );
    final early = Course(
      id: 'e',
      name: 'Early',
      day: Day.friday,
      startMinutes: minutes(8, 0),
      endMinutes: minutes(9, 0),
    );
    expect(
      coursesOn(Day.friday, [later, early]).map((course) => course.name),
      ['Early', 'Later'],
    );
  });

  test('editing the start time reorders the day', () {
    final first = Course(
      id: 'a',
      name: 'Early',
      day: Day.wednesday,
      startMinutes: minutes(8, 0),
      endMinutes: minutes(9, 0),
    );
    final moved = Course(
      id: 'b',
      name: 'Later',
      day: Day.wednesday,
      startMinutes: minutes(7, 0),
      endMinutes: minutes(7, 45),
    );
    expect(
      coursesOn(Day.wednesday, [first, moved]).map((course) => course.name),
      ['Later', 'Early'],
    );
  });

  test('refused times', () {
    final eight = validationError('Lab', '8h', '09:00');
    expect(eight, contains('8h'));
    expect(eight, contains('08:00'));

    final hours = validationError('Lab', '25:00', '26:00');
    expect(hours, contains('25:00'));
    expect(hours, contains('23'));

    final badMinutes = validationError('Lab', '10:75', '11:00');
    expect(badMinutes, contains('10:75'));
    expect(badMinutes, contains('59'));

    expect(
      validationError('Lab', '10:00', '10:00'),
      'End time must be after the start.',
    );
    expect(
      validationError('Lab', '11:00', '10:00'),
      'End time must be after the start.',
    );
    expect(validationError('   ', '08:00', '09:00'), 'Enter a course name.');
    expect(validationError('Lab', '08:00', '10:00'), isNull);
  });

  test('times round trip through minutes', () {
    final parsed = parseTime('08:00');
    expect(parsed, isA<TimeOk>());
    expect((parsed as TimeOk).minutes, 480);
    expect(formatTime(480), '08:00');
    expect(formatTime(minutes(11, 30)), '11:30');
    expect(formatDuration(120), '2h');
    expect(formatDuration(30), '30m');
    expect(formatDuration(0), '0m');
  });

  test('three names are listed in the clash label', () {
    final lab = Course(
      id: 'a',
      name: 'Lab',
      day: Day.monday,
      startMinutes: minutes(9, 0),
      endMinutes: minutes(12, 0),
    );
    final physics = Course(
      id: 'b',
      name: 'Physics',
      day: Day.monday,
      startMinutes: minutes(8, 0),
      endMinutes: minutes(10, 0),
    );
    final maths = Course(
      id: 'c',
      name: 'Mathematics',
      day: Day.monday,
      startMinutes: minutes(10, 0),
      endMinutes: minutes(11, 0),
    );
    final english = Course(
      id: 'd',
      name: 'English',
      day: Day.monday,
      startMinutes: minutes(11, 0),
      endMinutes: minutes(13, 0),
    );
    final names = clashNames(lab, [lab, physics, maths, english]);
    expect(
      clashLabel(names),
      'Clashes with Physics, Mathematics and English',
    );
  });

  test('free gap sits between classes and touching classes have none', () {
    final sample = sampleCourses();
    final free = dayRows(Day.thursday, sample).whereType<FreeRow>().single;
    expect(free.startMinutes, minutes(14, 30));
    expect(free.endMinutes, minutes(16, 0));
    expect(
      'Free: ${formatRange(free.startMinutes, free.endMinutes)}',
      'Free: 14:30–16:00',
    );
    expect(dayRows(Day.monday, sample).whereType<FreeRow>(), isEmpty);
    expect(dayRows(Day.tuesday, sample).whereType<FreeRow>(), isEmpty);
    expect(dayRows(Day.wednesday, sample), isEmpty);
  });

  test('sample covers three days, one clash, and the week total', () {
    final sample = sampleCourses();
    expect(sample.map((course) => course.day).toSet().length, greaterThanOrEqualTo(3));
    expect(
      formatDuration(totalMinutes(coursesOn(Day.monday, sample))),
      '3h 30m',
    );
    expect(
      coursesOn(Day.monday, sample).every(
        (course) => clashNames(course, sample).isEmpty,
      ),
      isTrue,
    );
    final clash = weekClashes(sample).single;
    expect(clash.day, Day.tuesday);
    expect(clash.first, 'Physics');
    expect(clash.second, 'Mathematics');
    expect(formatDuration(totalMinutes(sample)), '10h 30m');
  });

  test('moving a course removes it from the old day', () {
    final sample = sampleCourses();
    final chemistry = sample.firstWhere((course) => course.name == 'Chemistry');
    final moved = Course(
      id: chemistry.id,
      name: chemistry.name,
      day: Day.friday,
      startMinutes: chemistry.startMinutes,
      endMinutes: chemistry.endMinutes,
    );
    final updated = [
      for (final course in sample)
        if (course.id == moved.id) moved else course,
    ];
    expect(
      coursesOn(Day.thursday, updated).any((course) => course.name == 'Chemistry'),
      isFalse,
    );
    expect(coursesOn(Day.friday, updated).single.name, 'Chemistry');
  });

  test('the server body becomes the same week', () {
    const body =
        '[{"id":"mobile","name":"Mobile Programming","day":"monday","start":480,"end":600},'
        '{"id":"databases","name":"Databases","day":"monday","start":600,"end":690}]';
    final loaded = coursesFromJson(body);
    expect(loaded.map((course) => course.name), [
      'Mobile Programming',
      'Databases',
    ]);
    expect(formatDuration(totalMinutes(loaded)), '3h 30m');
    expect(clashes(loaded[0], loaded[1]), isFalse);
  });
}
