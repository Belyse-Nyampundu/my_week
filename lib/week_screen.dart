import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'course_form.dart';
import 'schedule.dart';
import 'times.dart';

class WeekScreen extends StatefulWidget {
  const WeekScreen({super.key});

  @override
  State<WeekScreen> createState() => _WeekScreenState();
}

class _WeekScreenState extends State<WeekScreen> {
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _courses;
  Day selectedDay = Day.monday;

  @override
  void initState() {
    super.initState();
    _courses = myCourses().orderBy('start').snapshots();
  }

  Future<void> _openForm({Course? existing}) async {
    final day = await Navigator.push<Day>(
      context,
      MaterialPageRoute(
        builder: (context) => CourseFormScreen(
          existing: existing,
          initialDay: existing?.day ?? selectedDay,
        ),
      ),
    );
    if (!mounted || day == null) return;
    setState(() => selectedDay = day);
  }

  Future<void> _delete(Course course) async {
    final sure = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this course?'),
        content: Text(course.name),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (sure != true) return;
    try {
      await myCourses().doc(course.id).delete();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not delete this course.\n$e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _courses,
      builder: (context, snapshot) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('My Week'),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                tooltip: 'Log out',
                onPressed: () => FirebaseAuth.instance.signOut(),
              ),
            ],
          ),
          floatingActionButton: snapshot.hasData
              ? FloatingActionButton(
                  onPressed: () => _openForm(),
                  child: const Icon(Icons.add),
                )
              : null,
          body: _body(snapshot),
        );
      },
    );
  }

  Widget _body(AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> snapshot) {
    if (snapshot.hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Could not load your courses.\n${snapshot.error}',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    if (!snapshot.hasData) {
      return const Center(child: CircularProgressIndicator());
    }
    final courses = snapshot.data!.docs.map(Course.fromDoc).toList();
    if (courses.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Please add your own timetable.\nTap + to add a course.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      children: [
        _weekTotal(courses),
        const SizedBox(height: 12),
        _dayChips(),
        const SizedBox(height: 12),
        _dayBody(courses),
        const SizedBox(height: 16),
        _weekClashes(courses),
      ],
    );
  }

  Widget _weekTotal(List<Course> courses) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.primaryContainer,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Text(
          'This week · ${formatDuration(totalMinutes(courses))}',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: scheme.onPrimaryContainer,
          ),
        ),
      ),
    );
  }

  Widget _dayChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final day in Day.values) ...[
            FilterChip(
              label: Text(day.short),
              selected: day == selectedDay,
              onSelected: (_) => setState(() => selectedDay = day),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  Widget _dayBody(List<Course> courses) {
    final onDay = coursesOn(selectedDay, courses);
    if (onDay.isEmpty) {
      return Text(
        'No classes on ${selectedDay.label}',
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '${selectedDay.label} · ${formatDuration(totalMinutes(onDay))}',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        for (final row in dayRows(selectedDay, courses)) ...[
          switch (row) {
            FreeRow() => _freeSlot(row),
            ClassRow() => _courseCard(row.course, courses),
          },
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _freeSlot(FreeRow row) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Text(
          'Free: ${formatRange(row.startMinutes, row.endMinutes)}',
          style: TextStyle(color: scheme.onSurfaceVariant),
        ),
      ),
    );
  }

  Widget _courseCard(Course course, List<Course> courses) {
    final names = clashNames(course, courses);
    final clashing = names.isNotEmpty;
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: clashing ? scheme.errorContainer : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: clashing ? BorderSide(color: scheme.error) : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _openForm(existing: course),
        onLongPress: () => _delete(course),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                course.name,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: clashing ? scheme.onErrorContainer : null,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${formatRange(course.startMinutes, course.endMinutes)} · ${formatDuration(course.durationMinutes)}',
              ),
              if (clashing) ...[
                const SizedBox(height: 4),
                Text(
                  clashLabel(names),
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _weekClashes(List<Course> courses) {
    final clashes = weekClashes(courses);
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        Text(
          'Clashes this week',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        if (clashes.isEmpty)
          Text(
            'No clashes this week',
            style: TextStyle(color: scheme.onSurfaceVariant),
          )
        else
          for (final clash in clashes)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '${clash.day.label}: ${clash.first} clashes with ${clash.second}',
                style: TextStyle(color: scheme.error),
              ),
            ),
      ],
    );
  }
}
