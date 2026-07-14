import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:nara/features/productivity/application/productivity_service.dart';
import 'package:nara/features/productivity/domain/entities/productivity_entities.dart';
import 'package:nara/features/productivity/presentation/providers/productivity_providers.dart';
import 'package:nara/features/productivity/presentation/widgets/productivity_forms.dart';

class TaskPage extends ConsumerStatefulWidget {
  const TaskPage({super.key});

  @override
  ConsumerState<TaskPage> createState() => _TaskPageState();
}

class _TaskPageState extends ConsumerState<TaskPage> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _edit(List<TaskItem> tasks, [TaskItem? existing]) async {
    final input = await showProductivityForm<TaskInput>(
      context,
      TaskForm(tasks: tasks, existing: existing),
    );
    if (input != null) {
      await ref
          .read(productivityControllerProvider.notifier)
          .saveTask(input, existing: existing);
    }
  }

  Future<void> _toggle(TaskItem item) => ref
      .read(productivityControllerProvider.notifier)
      .saveTask(
        TaskInput(
          title: item.title,
          description: item.description,
          category: item.category,
          parentTaskId: item.parentTaskId,
          priority: item.priority,
          status: item.isCompleted ? TaskStatus.pending : TaskStatus.completed,
          dueDate: item.dueDate,
          reminderAt: item.reminderAt,
          repeatRule: item.repeatRule,
        ),
        existing: item,
      );

  @override
  Widget build(BuildContext context) {
    ref.listen(productivityControllerProvider, (previous, next) {
      final message = next.value?.message;
      if (message != null && message != previous?.value?.message) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    });
    final data = ref.watch(productivityControllerProvider);
    return data.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => _ErrorState(
        onRetry: () => ref.invalidate(productivityControllerProvider),
      ),
      data: (state) => Scaffold(
        backgroundColor: Colors.transparent,
        floatingActionButton: FloatingActionButton.extended(
          key: const ValueKey('add-task'),
          heroTag: 'productivity-add-task',
          onPressed: state.isMutating
              ? null
              : () => _edit(state.snapshot.tasks),
          icon: const Icon(Icons.add_task),
          label: const Text('Task'),
        ),
        body: RefreshIndicator(
          onRefresh: () =>
              ref.read(productivityControllerProvider.notifier).refresh(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Task',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      Text(
                        'Atur prioritas, deadline, subtask, dan reminder offline',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 20),
                      _TaskSummary(summary: state.snapshot.summary),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _search,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.search),
                          hintText: 'Cari task…',
                        ),
                        onChanged: ref
                            .read(productivityControllerProvider.notifier)
                            .setTaskSearch,
                      ),
                      const SizedBox(height: 10),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            FilterChip(
                              label: const Text('Semua'),
                              selected: state.taskStatus == null,
                              onSelected: (_) => ref
                                  .read(productivityControllerProvider.notifier)
                                  .setTaskStatus(null),
                            ),
                            const SizedBox(width: 8),
                            ...TaskStatus.values.map(
                              (status) => Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: FilterChip(
                                  label: Text(status.label),
                                  selected: state.taskStatus == status,
                                  onSelected: (_) => ref
                                      .read(
                                        productivityControllerProvider.notifier,
                                      )
                                      .setTaskStatus(status),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (state.snapshot.tasks.isEmpty)
                        _EmptyTask(onAdd: () => _edit(state.snapshot.tasks))
                      else
                        ...state.snapshot.tasks.map(
                          (item) => _TaskCard(
                            item: item,
                            onToggle: () => _toggle(item),
                            onEdit: () => _edit(state.snapshot.tasks, item),
                            onDelete: () async {
                              if (await _confirm(
                                context,
                                'Hapus task?',
                                'Subtask yang terkait juga akan dihapus.',
                              )) {
                                await ref
                                    .read(
                                      productivityControllerProvider.notifier,
                                    )
                                    .deleteTask(item.id);
                              }
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TaskSummary extends StatelessWidget {
  const _TaskSummary({required this.summary});
  final ProductivitySummary summary;

  @override
  Widget build(BuildContext context) => Card(
    color: Theme.of(context).colorScheme.primaryContainer,
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Expanded(
            child: _Metric(label: 'Aktif', value: '${summary.activeTasks}'),
          ),
          Expanded(
            child: _Metric(
              label: 'Selesai',
              value: '${summary.completedTasks}',
            ),
          ),
          Expanded(
            child: _Metric(
              label: 'Jadwal hari ini',
              value: '${summary.todaySchedules}',
            ),
          ),
        ],
      ),
    ),
  );
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(
        value,
        style: Theme.of(
          context,
        ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
      ),
      Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodySmall,
      ),
    ],
  );
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.item,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });
  final TaskItem item;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final overdue =
        item.dueDate != null &&
        item.dueDate!.isBefore(DateTime.now()) &&
        !item.isCompleted;
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(8, 6, 4, 6),
        leading: Checkbox(
          value: item.isCompleted,
          onChanged: (_) => onToggle(),
        ),
        title: Text(
          item.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            decoration: item.isCompleted ? TextDecoration.lineThrough : null,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            _Tag(
              label: item.priority.label,
              color: _priorityColor(item.priority),
            ),
            if (item.category != null)
              _Tag(
                label: item.category!,
                color: Theme.of(context).colorScheme.secondary,
              ),
            if (item.parentTaskId != null)
              const _Tag(label: 'Subtask', color: Colors.blueGrey),
            if (item.dueDate != null)
              Text(
                DateFormat(
                  'd MMM • HH:mm',
                  'id_ID',
                ).format(item.dueDate!.toLocal()),
                style: TextStyle(
                  color: overdue ? Theme.of(context).colorScheme.error : null,
                  fontWeight: overdue ? FontWeight.w700 : null,
                ),
              ),
            if (item.reminderAt != null)
              const Icon(Icons.notifications_active_outlined, size: 16),
          ],
        ),
        trailing: PopupMenuButton<String>(
          tooltip: 'Opsi task',
          onSelected: (value) => value == 'edit' ? onEdit() : onDelete(),
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'edit', child: Text('Edit')),
            PopupMenuItem(value: 'delete', child: Text('Hapus')),
          ],
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label, required this.color});
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .12),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      label,
      style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w700),
    ),
  );
}

Color _priorityColor(TaskPriority priority) => switch (priority) {
  TaskPriority.low => Colors.green,
  TaskPriority.medium => Colors.orange,
  TaskPriority.high => Colors.red,
};

class _EmptyTask extends StatelessWidget {
  const _EmptyTask({required this.onAdd});
  final VoidCallback onAdd;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        children: [
          Icon(
            Icons.task_alt,
            size: 48,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 12),
          Text(
            'Belum ada task',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const Text('Buat task pertama dan atur prioritasnya.'),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Buat task'),
          ),
        ],
      ),
    ),
  );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(
    child: FilledButton.icon(
      onPressed: onRetry,
      icon: const Icon(Icons.refresh),
      label: const Text('Coba lagi'),
    ),
  );
}

Future<bool> _confirm(
  BuildContext context,
  String title,
  String message,
) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    ) ??
    false;
