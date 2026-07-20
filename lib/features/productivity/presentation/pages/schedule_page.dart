import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:nara/features/productivity/application/productivity_service.dart';
import 'package:nara/features/productivity/domain/entities/productivity_entities.dart';
import 'package:nara/features/productivity/presentation/providers/productivity_providers.dart';
import 'package:nara/features/productivity/presentation/widgets/productivity_forms.dart';

class SchedulePage extends ConsumerWidget {
  const SchedulePage({super.key});

  Future<void> _schedule(
    BuildContext context,
    WidgetRef ref, [
    ScheduleItem? existing,
  ]) async {
    final input = await showProductivityForm<ScheduleInput>(
      context,
      ScheduleForm(existing: existing),
    );
    if (input != null) {
      await ref
          .read(productivityControllerProvider.notifier)
          .saveSchedule(input, existing: existing);
    }
  }

  Future<void> _activity(
    BuildContext context,
    WidgetRef ref, [
    ActivityItem? existing,
  ]) async {
    final input = await showProductivityForm<ActivityInput>(
      context,
      ActivityForm(existing: existing),
    );
    if (input != null) {
      await ref
          .read(productivityControllerProvider.notifier)
          .saveActivity(input, existing: existing);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(productivityControllerProvider);
    return data.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => Center(
        child: FilledButton.icon(
          onPressed: () => ref.invalidate(productivityControllerProvider),
          icon: const Icon(Icons.refresh),
          label: const Text('Coba lagi'),
        ),
      ),
      data: (state) {
        final schedules = state.snapshot.schedules
            .where((item) => _sameDay(item.startAt.toLocal(), state.day))
            .toList();
        final activities = state.snapshot.activities
            .where((item) => _sameDay(item.startAt.toLocal(), state.day))
            .toList();
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: RefreshIndicator(
            onRefresh: () =>
                ref.read(productivityControllerProvider.notifier).refresh(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 100),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1000),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Jadwal & Aktivitas',
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(color: const Color(0xFF001B3D)),
                        ),
                        const Text(
                          'Agenda dan catatan aktivitas tersimpan di perangkat',
                        ),
                        const SizedBox(height: 18),
                        _DayPicker(
                          day: state.day,
                          onPrevious: () => ref
                              .read(productivityControllerProvider.notifier)
                              .changeDay(-1),
                          onNext: () => ref
                              .read(productivityControllerProvider.notifier)
                              .changeDay(1),
                        ),
                        const SizedBox(height: 18),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final wide = constraints.maxWidth >= 760;
                            final agenda = _Section(
                              title: 'Agenda',
                              icon: Icons.calendar_month,
                              actionLabel: 'Tambah jadwal',
                              actionKey: const ValueKey('add-schedule'),
                              onAdd: () => _schedule(context, ref),
                              child: schedules.isEmpty
                                  ? const _Empty(
                                      label: 'Tidak ada jadwal pada hari ini',
                                    )
                                  : Column(
                                      children: schedules
                                          .map(
                                            (item) => _ScheduleTile(
                                              item: item,
                                              onEdit: () =>
                                                  _schedule(context, ref, item),
                                              onDelete: () => ref
                                                  .read(
                                                    productivityControllerProvider
                                                        .notifier,
                                                  )
                                                  .deleteSchedule(item.id),
                                            ),
                                          )
                                          .toList(),
                                    ),
                            );
                            final log = _Section(
                              title: 'Log aktivitas',
                              icon: Icons.history,
                              actionLabel: 'Catat aktivitas',
                              actionKey: const ValueKey('add-activity'),
                              onAdd: () => _activity(context, ref),
                              child: activities.isEmpty
                                  ? const _Empty(
                                      label: 'Belum ada aktivitas yang dicatat',
                                    )
                                  : Column(
                                      children: activities
                                          .map(
                                            (item) => _ActivityTile(
                                              item: item,
                                              onEdit: () =>
                                                  _activity(context, ref, item),
                                              onDelete: () => ref
                                                  .read(
                                                    productivityControllerProvider
                                                        .notifier,
                                                  )
                                                  .deleteActivity(item.id),
                                            ),
                                          )
                                          .toList(),
                                    ),
                            );
                            return wide
                                ? Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(child: agenda),
                                      const SizedBox(width: 16),
                                      Expanded(child: log),
                                    ],
                                  )
                                : Column(
                                    children: [
                                      agenda,
                                      const SizedBox(height: 16),
                                      log,
                                    ],
                                  );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DayPicker extends StatelessWidget {
  const _DayPicker({
    required this.day,
    required this.onPrevious,
    required this.onNext,
  });
  final DateTime day;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      child: Row(
        children: [
          IconButton(
            onPressed: onPrevious,
            tooltip: 'Hari sebelumnya',
            icon: const Icon(Icons.chevron_left),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  DateFormat('EEEE', 'id_ID').format(day),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormat('d MMMM yyyy', 'id_ID').format(day),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onNext,
            tooltip: 'Hari berikutnya',
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    ),
  );
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.icon,
    required this.actionLabel,
    required this.actionKey,
    required this.onAdd,
    required this.child,
  });
  final String title;
  final IconData icon;
  final String actionLabel;
  final Key actionKey;
  final VoidCallback onAdd;
  final Widget child;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton(
                key: actionKey,
                onPressed: onAdd,
                tooltip: actionLabel,
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          const Divider(),
          child,
        ],
      ),
    ),
  );
}

class _ScheduleTile extends StatelessWidget {
  const _ScheduleTile({
    required this.item,
    required this.onEdit,
    required this.onDelete,
  });
  final ScheduleItem item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: const EdgeInsets.symmetric(vertical: 4),
    leading: CircleAvatar(
      backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
      child: Text(
        DateFormat('HH:mm').format(item.startAt.toLocal()),
        style: TextStyle(
          color: Theme.of(context).colorScheme.secondary,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    ),
    title: Text(
      item.title,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(fontWeight: FontWeight.w800),
    ),
    subtitle: Text(
      '${DateFormat('HH:mm').format(item.startAt.toLocal())}–${DateFormat('HH:mm').format(item.endAt.toLocal())}${item.location == null ? '' : ' • ${item.location}'}',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    ),
    trailing: PopupMenuButton<String>(
      onSelected: (value) => value == 'edit' ? onEdit() : onDelete(),
      itemBuilder: (_) => const [
        PopupMenuItem(value: 'edit', child: Text('Edit')),
        PopupMenuItem(value: 'delete', child: Text('Hapus')),
      ],
    ),
  );
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({
    required this.item,
    required this.onEdit,
    required this.onDelete,
  });
  final ActivityItem item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: const CircleAvatar(child: Icon(Icons.directions_run)),
    title: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis),
    subtitle: Text(
      '${DateFormat('HH:mm').format(item.startAt.toLocal())}${item.durationMinutes == null ? '' : ' • ${item.durationMinutes} menit'}${item.mood == null ? '' : ' • ${item.mood}'}',
    ),
    trailing: PopupMenuButton<String>(
      onSelected: (value) => value == 'edit' ? onEdit() : onDelete(),
      itemBuilder: (_) => const [
        PopupMenuItem(value: 'edit', child: Text('Edit')),
        PopupMenuItem(value: 'delete', child: Text('Hapus')),
      ],
    ),
  );
}

class _Empty extends StatelessWidget {
  const _Empty({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 28),
    child: Column(
      children: [
        Icon(
          Icons.inbox_outlined,
          size: 38,
          color: Theme.of(context).colorScheme.outline,
        ),
        const SizedBox(height: 8),
        Text(label, textAlign: TextAlign.center),
      ],
    ),
  );
}

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
