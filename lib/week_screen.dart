import 'package:flutter/material.dart';

import 'course_form.dart';
import 'courses_api.dart';
import 'schedule.dart';
import 'storage.dart';
import 'times.dart';

class WeekScreen extends StatefulWidget {
  const WeekScreen({super.key});

  @override
  State<WeekScreen> createState() => _WeekScreenState();
}

class _WeekScreenState extends State<WeekScreen> {
  List<Course> courses = [];
  Day selectedDay = Day.monday;
  bool ready = false;
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _start();
  }

  /// initState cannot be async, so it starts this Future and lets the spinner show.
  Future<void> _start() async {
    final saved = await loadCourses();
    if (!mounted) return;
    if (saved != null) {
      setState(() {
        courses = saved;
        ready = true;
        loading = false;
        error = null;
      });
      return;
    }
    await _loadFromApi();
  }

  Future<void> _loadFromApi() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final loaded = await fetchCourses();
      await saveCourses(loaded);
      if (!mounted) return;
      setState(() {
        courses = loaded;
        ready = true;
        loading = false;
        error = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        ready = true;
        loading = false;
        error = 'Could not load your week. Check your internet connection.';
      });
    }
  }

  Future<void> _openForm({Course? existing}) async {
    final result = await Navigator.push<FormResult>(
      context,
      MaterialPageRoute(
        builder: (context) => CourseFormScreen(
          existing: existing,
          initialDay: existing?.day ?? selectedDay,
        ),
      ),
    );
    if (!mounted || result == null) return;
    late final List<Course> updated;
    var day = selectedDay;
    if (result.deleted) {
      updated = [
        for (final course in courses)
          if (course.id != existing!.id) course,
      ];
    } else {
      final course = result.course!;
      day = course.day;
      if (existing == null) {
        updated = [...courses, course];
      } else {
        updated = [
          for (final item in courses)
            if (item.id == course.id) course else item,
        ];
      }
    }
    setState(() {
      courses = updated;
      selectedDay = day;
    });
    await saveCourses(updated);
  }

  @override
  Widget build(BuildContext context) {
    if (!ready || loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Week')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    final message = error;
    if (message != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Week')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.wifi_off, size: 48),
                const SizedBox(height: 12),
                Text(message, textAlign: TextAlign.center),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: _loadFromApi,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('My Week')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
        child: const Icon(Icons.add),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
        children: [
          _weekTotal(),
          const SizedBox(height: 12),
          _dayChips(),
          const SizedBox(height: 12),
          _dayBody(),
          const SizedBox(height: 16),
          _weekClashes(),
        ],
      ),
    );
  }

  Widget _weekTotal() {
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

  Widget _dayBody() {
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
            ClassRow() => _courseCard(row.course),
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

  Widget _courseCard(Course course) {
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

  Widget _weekClashes() {
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
