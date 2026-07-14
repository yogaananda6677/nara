import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nara/features/productivity/application/productivity_service.dart';
import 'package:nara/features/productivity/domain/entities/productivity_entities.dart';

Future<T?> showProductivityForm<T>(BuildContext context, Widget child) {
  if (MediaQuery.sizeOf(context).width >= 700) {
    return showDialog<T>(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620, maxHeight: 760),
          child: child,
        ),
      ),
    );
  }
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => child,
  );
}

class TaskForm extends StatefulWidget {
  const TaskForm({required this.tasks, this.existing, super.key});

  final List<TaskItem> tasks;
  final TaskItem? existing;

  @override
  State<TaskForm> createState() => _TaskFormState();
}

class _TaskFormState extends State<TaskForm> {
  final _key = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _description;
  late final TextEditingController _category;
  late TaskPriority _priority;
  late TaskStatus _status;
  late RepeatRule _repeat;
  String? _parentId;
  DateTime? _dueDate;
  DateTime? _reminderAt;

  @override
  void initState() {
    super.initState();
    final item = widget.existing;
    _title = TextEditingController(text: item?.title);
    _description = TextEditingController(text: item?.description);
    _category = TextEditingController(text: item?.category);
    _priority = item?.priority ?? TaskPriority.medium;
    _status = item?.status ?? TaskStatus.pending;
    _repeat = item?.repeatRule ?? RepeatRule.none;
    _parentId = item?.parentTaskId;
    _dueDate = item?.dueDate?.toLocal();
    _reminderAt = item?.reminderAt?.toLocal();
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _category.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_key.currentState!.validate()) return;
    Navigator.pop(
      context,
      TaskInput(
        title: _title.text,
        description: _description.text,
        category: _category.text,
        parentTaskId: _parentId,
        priority: _priority,
        status: _status,
        dueDate: _dueDate,
        reminderAt: _reminderAt,
        repeatRule: _repeat,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final parentOptions = widget.tasks
        .where(
          (item) => item.parentTaskId == null && item.id != widget.existing?.id,
        )
        .toList();
    return _FormFrame(
      title: widget.existing == null ? 'Task baru' : 'Edit task',
      actionLabel: 'Simpan task',
      onSubmit: _submit,
      child: Form(
        key: _key,
        child: Column(
          children: [
            TextFormField(
              key: const ValueKey('task-title'),
              controller: _title,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Judul task',
                prefixIcon: Icon(Icons.task_alt),
              ),
              validator: _required,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _description,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Deskripsi (opsional)',
                prefixIcon: Icon(Icons.notes),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _category,
              decoration: const InputDecoration(
                labelText: 'Kategori (opsional)',
                prefixIcon: Icon(Icons.label_outline),
              ),
            ),
            if (parentOptions.isNotEmpty) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _parentId ?? '',
                decoration: const InputDecoration(
                  labelText: 'Subtask dari (opsional)',
                  prefixIcon: Icon(Icons.account_tree_outlined),
                ),
                items: [
                  const DropdownMenuItem(value: '', child: Text('Task utama')),
                  ...parentOptions.map(
                    (item) => DropdownMenuItem(
                      value: item.id,
                      child: Text(item.title),
                    ),
                  ),
                ],
                onChanged: (value) =>
                    setState(() => _parentId = value!.isEmpty ? null : value),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<TaskPriority>(
                    initialValue: _priority,
                    decoration: const InputDecoration(labelText: 'Prioritas'),
                    items: TaskPriority.values
                        .map(
                          (item) => DropdownMenuItem(
                            value: item,
                            child: Text(item.label),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(() => _priority = value!),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<TaskStatus>(
                    initialValue: _status,
                    decoration: const InputDecoration(labelText: 'Status'),
                    items: TaskStatus.values
                        .map(
                          (item) => DropdownMenuItem(
                            value: item,
                            child: Text(item.label),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(() => _status = value!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<RepeatRule>(
              initialValue: _repeat,
              decoration: const InputDecoration(
                labelText: 'Pengulangan',
                prefixIcon: Icon(Icons.repeat),
              ),
              items: RepeatRule.values
                  .map(
                    (item) =>
                        DropdownMenuItem(value: item, child: Text(item.label)),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _repeat = value!),
            ),
            const SizedBox(height: 8),
            _DateTimeTile(
              icon: Icons.event_outlined,
              label: 'Deadline',
              value: _dueDate,
              onPick: () async {
                final value = await _pickDateTime(context, _dueDate);
                if (value != null) setState(() => _dueDate = value);
              },
              onClear: _dueDate == null
                  ? null
                  : () => setState(() => _dueDate = null),
            ),
            _DateTimeTile(
              icon: Icons.notifications_outlined,
              label: 'Reminder',
              value: _reminderAt,
              onPick: () async {
                final value = await _pickDateTime(context, _reminderAt);
                if (value != null) setState(() => _reminderAt = value);
              },
              onClear: _reminderAt == null
                  ? null
                  : () => setState(() => _reminderAt = null),
            ),
          ],
        ),
      ),
    );
  }
}

class ScheduleForm extends StatefulWidget {
  const ScheduleForm({this.existing, super.key});
  final ScheduleItem? existing;

  @override
  State<ScheduleForm> createState() => _ScheduleFormState();
}

class _ScheduleFormState extends State<ScheduleForm> {
  final _key = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _description;
  late final TextEditingController _location;
  late DateTime _start;
  late DateTime _end;
  DateTime? _reminder;
  late RepeatRule _repeat;

  @override
  void initState() {
    super.initState();
    final item = widget.existing;
    _title = TextEditingController(text: item?.title);
    _description = TextEditingController(text: item?.description);
    _location = TextEditingController(text: item?.location);
    _start =
        item?.startAt.toLocal() ?? DateTime.now().add(const Duration(hours: 1));
    _end = item?.endAt.toLocal() ?? _start.add(const Duration(hours: 1));
    _reminder = item?.reminderAt?.toLocal();
    _repeat = item?.repeatRule ?? RepeatRule.none;
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _location.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_key.currentState!.validate()) return;
    Navigator.pop(
      context,
      ScheduleInput(
        title: _title.text,
        description: _description.text,
        location: _location.text,
        startAt: _start,
        endAt: _end,
        reminderAt: _reminder,
        repeatRule: _repeat,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => _FormFrame(
    title: widget.existing == null ? 'Jadwal baru' : 'Edit jadwal',
    actionLabel: 'Simpan jadwal',
    onSubmit: _submit,
    child: Form(
      key: _key,
      child: Column(
        children: [
          TextFormField(
            key: const ValueKey('schedule-title'),
            controller: _title,
            decoration: const InputDecoration(
              labelText: 'Judul kegiatan',
              prefixIcon: Icon(Icons.event),
            ),
            validator: _required,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _location,
            decoration: const InputDecoration(
              labelText: 'Lokasi (opsional)',
              prefixIcon: Icon(Icons.place_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _description,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Catatan (opsional)',
              prefixIcon: Icon(Icons.notes),
            ),
          ),
          const SizedBox(height: 8),
          _DateTimeTile(
            icon: Icons.play_circle_outline,
            label: 'Mulai',
            value: _start,
            onPick: () async {
              final value = await _pickDateTime(context, _start);
              if (value != null) setState(() => _start = value);
            },
          ),
          _DateTimeTile(
            icon: Icons.stop_circle_outlined,
            label: 'Selesai',
            value: _end,
            onPick: () async {
              final value = await _pickDateTime(context, _end);
              if (value != null) setState(() => _end = value);
            },
          ),
          _DateTimeTile(
            icon: Icons.notifications_outlined,
            label: 'Reminder',
            value: _reminder,
            onPick: () async {
              final value = await _pickDateTime(
                context,
                _reminder ?? _start.subtract(const Duration(minutes: 15)),
              );
              if (value != null) setState(() => _reminder = value);
            },
            onClear: _reminder == null
                ? null
                : () => setState(() => _reminder = null),
          ),
          DropdownButtonFormField<RepeatRule>(
            initialValue: _repeat,
            decoration: const InputDecoration(
              labelText: 'Pengulangan',
              prefixIcon: Icon(Icons.repeat),
            ),
            items: RepeatRule.values
                .map(
                  (item) =>
                      DropdownMenuItem(value: item, child: Text(item.label)),
                )
                .toList(),
            onChanged: (value) => setState(() => _repeat = value!),
          ),
        ],
      ),
    ),
  );
}

class ActivityForm extends StatefulWidget {
  const ActivityForm({this.existing, super.key});
  final ActivityItem? existing;

  @override
  State<ActivityForm> createState() => _ActivityFormState();
}

class _ActivityFormState extends State<ActivityForm> {
  final _key = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _category;
  late final TextEditingController _notes;
  late DateTime _start;
  DateTime? _end;
  String? _mood;

  @override
  void initState() {
    super.initState();
    final item = widget.existing;
    _title = TextEditingController(text: item?.title);
    _category = TextEditingController(text: item?.category);
    _notes = TextEditingController(text: item?.notes);
    _start = item?.startAt.toLocal() ?? DateTime.now();
    _end = item?.endAt?.toLocal();
    _mood = item?.mood;
  }

  @override
  void dispose() {
    _title.dispose();
    _category.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_key.currentState!.validate()) return;
    Navigator.pop(
      context,
      ActivityInput(
        title: _title.text,
        category: _category.text,
        notes: _notes.text,
        mood: _mood,
        startAt: _start,
        endAt: _end,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => _FormFrame(
    title: widget.existing == null ? 'Catat aktivitas' : 'Edit aktivitas',
    actionLabel: 'Simpan aktivitas',
    onSubmit: _submit,
    child: Form(
      key: _key,
      child: Column(
        children: [
          TextFormField(
            key: const ValueKey('activity-title'),
            controller: _title,
            decoration: const InputDecoration(
              labelText: 'Aktivitas',
              prefixIcon: Icon(Icons.directions_run),
            ),
            validator: _required,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _category,
            decoration: const InputDecoration(
              labelText: 'Kategori (opsional)',
              prefixIcon: Icon(Icons.label_outline),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _notes,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Catatan (opsional)',
              prefixIcon: Icon(Icons.notes),
            ),
          ),
          const SizedBox(height: 8),
          _DateTimeTile(
            icon: Icons.play_circle_outline,
            label: 'Mulai',
            value: _start,
            onPick: () async {
              final value = await _pickDateTime(context, _start);
              if (value != null) setState(() => _start = value);
            },
          ),
          _DateTimeTile(
            icon: Icons.stop_circle_outlined,
            label: 'Selesai (opsional)',
            value: _end,
            onPick: () async {
              final value = await _pickDateTime(
                context,
                _end ?? DateTime.now(),
              );
              if (value != null) setState(() => _end = value);
            },
            onClear: _end == null ? null : () => setState(() => _end = null),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _mood ?? '',
            decoration: const InputDecoration(
              labelText: 'Mood (opsional)',
              prefixIcon: Icon(Icons.mood),
            ),
            items: const [
              DropdownMenuItem(value: '', child: Text('Tidak dicatat')),
              DropdownMenuItem(value: 'senang', child: Text('😊 Senang')),
              DropdownMenuItem(value: 'netral', child: Text('😐 Netral')),
              DropdownMenuItem(value: 'lelah', child: Text('😴 Lelah')),
            ],
            onChanged: (value) =>
                setState(() => _mood = value!.isEmpty ? null : value),
          ),
        ],
      ),
    ),
  );
}

class _FormFrame extends StatelessWidget {
  const _FormFrame({
    required this.title,
    required this.actionLabel,
    required this.onSubmit,
    required this.child,
  });
  final String title;
  final String actionLabel;
  final VoidCallback onSubmit;
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      20,
      20,
      20,
      MediaQuery.viewInsetsOf(context).bottom + 20,
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(title, style: Theme.of(context).textTheme.titleLarge),
            ),
            IconButton(
              onPressed: () => Navigator.pop(context),
              tooltip: 'Tutup',
              icon: const Icon(Icons.close),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Flexible(child: SingleChildScrollView(child: child)),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: onSubmit,
          icon: const Icon(Icons.save_outlined),
          label: Text(actionLabel),
        ),
      ],
    ),
  );
}

class _DateTimeTile extends StatelessWidget {
  const _DateTimeTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onPick,
    this.onClear,
  });
  final IconData icon;
  final String label;
  final DateTime? value;
  final VoidCallback onPick;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: Icon(icon),
    title: Text(label),
    subtitle: Text(
      value == null
          ? 'Belum ditentukan'
          : DateFormat('EEE, d MMM yyyy • HH:mm', 'id_ID').format(value!),
    ),
    trailing: onClear == null
        ? const Icon(Icons.chevron_right)
        : IconButton(
            onPressed: onClear,
            tooltip: 'Hapus $label',
            icon: const Icon(Icons.close),
          ),
    onTap: onPick,
  );
}

Future<DateTime?> _pickDateTime(BuildContext context, DateTime? initial) async {
  final base = initial ?? DateTime.now();
  final date = await showDatePicker(
    context: context,
    initialDate: base,
    firstDate: DateTime(2020),
    lastDate: DateTime.now().add(const Duration(days: 3650)),
  );
  if (date == null || !context.mounted) return null;
  final time = await showTimePicker(
    context: context,
    initialTime: TimeOfDay.fromDateTime(base),
  );
  if (time == null) return null;
  return DateTime(date.year, date.month, date.day, time.hour, time.minute);
}

String? _required(String? value) =>
    value == null || value.trim().isEmpty ? 'Wajib diisi.' : null;
