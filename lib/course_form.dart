import 'package:flutter/material.dart';

import 'schedule.dart';
import 'times.dart';

class FormResult {
  const FormResult.saved(this.course) : deleted = false;
  const FormResult.deleted() : course = null, deleted = true;

  final Course? course;
  final bool deleted;
}

class CourseFormScreen extends StatefulWidget {
  const CourseFormScreen({super.key, this.existing, required this.initialDay});

  final Course? existing;
  final Day initialDay;

  @override
  State<CourseFormScreen> createState() => _CourseFormScreenState();
}

class _CourseFormScreenState extends State<CourseFormScreen> {
  late final TextEditingController _name;
  late final TextEditingController _start;
  late final TextEditingController _end;
  late Day _day;
  String? _error;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _name = TextEditingController(text: existing?.name ?? '');
    _start = TextEditingController(
      text: existing == null ? '' : formatTime(existing.startMinutes),
    );
    _end = TextEditingController(
      text: existing == null ? '' : formatTime(existing.endMinutes),
    );
    _day = existing?.day ?? widget.initialDay;
  }

  @override
  void dispose() {
    _name.dispose();
    _start.dispose();
    _end.dispose();
    super.dispose();
  }

  void _clearError(String _) {
    if (_error != null) setState(() => _error = null);
  }

  void _save() {
    final error = validationError(_name.text, _start.text, _end.text);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    final start = parseTime(_start.text) as TimeOk;
    final end = parseTime(_end.text) as TimeOk;
    final course = Course(
      id: widget.existing?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      name: _name.text.trim(),
      day: _day,
      startMinutes: start.minutes,
      endMinutes: end.minutes,
    );
    Navigator.pop(context, FormResult.saved(course));
  }

  Future<void> _confirmDelete() async {
    final typed = _name.text.trim();
    final name = typed.isEmpty ? 'this course' : typed;
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Are you sure?'),
          content: Text('Delete $name?'),
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
        );
      },
    );
    if (yes == true && mounted) {
      Navigator.pop(context, const FormResult.deleted());
    }
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.existing != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(editing ? 'Edit course' : 'Add course'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Course name',
              border: OutlineInputBorder(),
            ),
            onChanged: _clearError,
          ),
          const SizedBox(height: 16),
          Text('Day', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final day in Day.values) ...[
                  FilterChip(
                    label: Text(day.short),
                    selected: _day == day,
                    onSelected: (_) => setState(() => _day = day),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _start,
                  decoration: const InputDecoration(
                    labelText: 'Start',
                    hintText: '08:00',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: _clearError,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _end,
                  decoration: const InputDecoration(
                    labelText: 'End',
                    hintText: '10:00',
                    border: OutlineInputBorder(),
                  ),
                  textInputAction: TextInputAction.done,
                  onChanged: _clearError,
                  onSubmitted: (_) => _save(),
                ),
              ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 16),
          FilledButton(onPressed: _save, child: const Text('Save')),
          if (editing) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _confirmDelete,
              icon: const Icon(Icons.delete),
              label: const Text('Delete'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
