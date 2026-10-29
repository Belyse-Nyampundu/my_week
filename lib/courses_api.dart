import 'dart:convert';

import 'package:http/http.dart' as http;

import 'schedule.dart';

/// The week's courses live on a server. The app does not keep its own copy of this list.
const coursesApiUrl = 'https://files.catbox.moe/aoolmw.json';

List<Course> coursesFromJson(String body) {
  final data = jsonDecode(body) as List<dynamic>;
  return [
    for (final item in data) Course.fromJson(item as Map<String, dynamic>),
  ];
}

/// A Future is the course list later. await waits for the server without freezing the screen.
Future<List<Course>> fetchCourses() async {
  final response = await http
      .get(
        Uri.parse(coursesApiUrl),
        headers: const {'User-Agent': 'MyWeek/1.0 (com.example.mini_project)'},
      )
      .timeout(const Duration(seconds: 15));
  if (response.statusCode != 200) {
    throw Exception('The server answered ${response.statusCode}');
  }
  return coursesFromJson(response.body);
}
