import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'schedule.dart';

const coursesKey = 'courses';

/// Null means this phone has never saved a week. An empty list is a real saved week.
Future<List<Course>?> loadCourses() async {
  final prefs = await SharedPreferences.getInstance();
  final saved = prefs.getString(coursesKey);
  if (saved == null) return null;
  try {
    final list = jsonDecode(saved) as List<dynamic>;
    return [
      for (final item in list) Course.fromJson(item as Map<String, dynamic>),
    ];
  } catch (_) {
    return [];
  }
}

Future<void> saveCourses(List<Course> courses) async {
  final prefs = await SharedPreferences.getInstance();
  final list = [for (final course in courses) course.toJson()];
  await prefs.setString(coursesKey, jsonEncode(list));
}
