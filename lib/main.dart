import 'package:flutter/material.dart';

import 'week_screen.dart';

void main() {
  runApp(const MyWeekApp());
}

class MyWeekApp extends StatelessWidget {
  const MyWeekApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Week',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.blue, useMaterial3: true),
      home: const WeekScreen(),
    );
  }
}
