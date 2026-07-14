import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nara/core/formatters/currency_formatter.dart';
import 'package:nara/features/finance/domain/entities/finance_snapshot.dart';
import 'package:nara/features/finance/presentation/providers/finance_providers.dart';
import 'package:nara/features/foundation/presentation/providers/foundation_providers.dart';
import 'package:nara/features/productivity/domain/entities/productivity_entities.dart';
import 'package:nara/features/productivity/presentation/providers/productivity_providers.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({
    required this.onOpenFinance,
    required this.onOpenSchedule,
    required this.onOpenTasks,
    required this.onOpenSmartScan,
    required this.onOpenSettings,
    super.key,
  });

  final VoidCallback onOpenFinance;
  final VoidCallback onOpenSchedule;
  final VoidCallback onOpenTasks;
  final VoidCallback onOpenSmartScan;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final foundation = ref.watch(foundationControllerProvider).value;
    final assistantName = foundation?.profile?.assistantName ?? 'Nara';
    final userName = foundation?.profile?.name ?? 'Pengguna';
    final textTheme = Theme.of(context).textTheme;
    final financeSummary = ref
        .watch(financeControllerProvider)
        .value
        ?.snapshot
        .summary;
    final productivitySummary = ref
        .watch(productivityControllerProvider)
        .value
        ?.snapshot
        .summary;

    return LayoutBuilder(
      builder: (context, constraints) => ListView(
        padding: EdgeInsets.fromLTRB(
          constraints.maxWidth >= 800 ? 32 : 20,
          16,
          constraints.maxWidth >= 800 ? 32 : 20,
          32,
        ),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Halo, $userName',
                              style: textTheme.titleMedium,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              assistantName,
                              style: textTheme.headlineMedium,
                            ),
                          ],
                        ),
                      ),
                      const _OfflineBadge(),
                      const SizedBox(width: 4),
                      IconButton(
                        key: const ValueKey('open-settings'),
                        onPressed: onOpenSettings,
                        tooltip: 'Buka pengaturan',
                        icon: const Icon(Icons.settings_outlined),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _FinanceOverview(
                    summary:
                        financeSummary ??
                        const FinanceSummary(
                          totalBalance: 0,
                          monthlyIncome: 0,
                          monthlyExpense: 0,
                        ),
                  ),
                  const SizedBox(height: 28),
                  Text('Menu utama', style: textTheme.titleLarge),
                  const SizedBox(height: 12),
                  _MainMenuGrid(
                    onOpenFinance: onOpenFinance,
                    onOpenSchedule: onOpenSchedule,
                    onOpenTasks: onOpenTasks,
                    onOpenSmartScan: onOpenSmartScan,
                  ),
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      Expanded(
                        child: Text('Hari ini', style: textTheme.titleLarge),
                      ),
                      Flexible(
                        child: Text(
                          'Ringkasan aktivitas',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.end,
                          style: textTheme.bodySmall?.copyWith(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _TodayCard(
                          icon: Icons.task_alt,
                          value: '${productivitySummary?.activeTasks ?? 0}',
                          label: 'Task aktif',
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: _TodayCard(
                          icon: Icons.event_available_outlined,
                          value: '${productivitySummary?.todaySchedules ?? 0}',
                          label: 'Jadwal',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _ReminderCard(
                    summary:
                        productivitySummary ??
                        const ProductivitySummary(
                          activeTasks: 0,
                          completedTasks: 0,
                          todaySchedules: 0,
                          todayActivityMinutes: 0,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(
                            Icons.shield_outlined,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Privasi terjaga',
                                  style: TextStyle(fontWeight: FontWeight.w700),
                                ),
                                SizedBox(height: 3),
                                Text(
                                  'Semua data V1 tersimpan di perangkat Anda.',
                                ),
                              ],
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
        ],
      ),
    );
  }
}

class _ReminderCard extends StatelessWidget {
  const _ReminderCard({required this.summary});

  final ProductivitySummary summary;

  @override
  Widget build(BuildContext context) {
    final reminder = summary.nextReminder?.toLocal();
    final label = reminder == null
        ? 'Belum ada reminder berikutnya'
        : 'Reminder berikutnya: ${reminder.day}/${reminder.month} • ${reminder.hour.toString().padLeft(2, '0')}:${reminder.minute.toString().padLeft(2, '0')}';
    return Card(
      child: ListTile(
        leading: Icon(
          Icons.notifications_active_outlined,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: const Text(
          'Produktivitas hari ini',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          '$label • ${summary.todayActivityMinutes} menit aktivitas',
        ),
      ),
    );
  }
}

class _FinanceOverview extends StatelessWidget {
  const _FinanceOverview({required this.summary});

  final FinanceSummary summary;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF9E1B1B), Color(0xFFE53935)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.22),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Total saldo', style: TextStyle(color: Colors.white70)),
          SizedBox(height: 6),
          Text(
            CurrencyFormatter.rupiah(summary.totalBalance),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _BalanceDetail(
                  icon: Icons.south_west,
                  label: 'Pemasukan',
                  value: CurrencyFormatter.rupiah(summary.monthlyIncome),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _BalanceDetail(
                  icon: Icons.north_east,
                  label: 'Pengeluaran',
                  value: CurrencyFormatter.rupiah(summary.monthlyExpense),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BalanceDetail extends StatelessWidget {
  const _BalanceDetail({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.18),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 18, color: Colors.white),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MainMenuGrid extends StatelessWidget {
  const _MainMenuGrid({
    required this.onOpenFinance,
    required this.onOpenSchedule,
    required this.onOpenTasks,
    required this.onOpenSmartScan,
  });

  final VoidCallback onOpenFinance;
  final VoidCallback onOpenSchedule;
  final VoidCallback onOpenTasks;
  final VoidCallback onOpenSmartScan;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = constraints.maxWidth >= 700
            ? 210.0
            : (constraints.maxWidth - 20) / 3;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            SizedBox(
              width: itemWidth,
              child: _DashboardMenu(
                key: const ValueKey('dashboard-finance'),
                icon: Icons.account_balance_wallet_outlined,
                label: 'Keuangan',
                onTap: onOpenFinance,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _DashboardMenu(
                key: const ValueKey('dashboard-smart-scan'),
                icon: Icons.document_scanner_outlined,
                label: 'Smart Scan',
                onTap: onOpenSmartScan,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _DashboardMenu(
                key: const ValueKey('dashboard-schedule'),
                icon: Icons.calendar_month_outlined,
                label: 'Jadwal',
                onTap: onOpenSchedule,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _DashboardMenu(
                key: const ValueKey('dashboard-task'),
                icon: Icons.task_alt_outlined,
                label: 'Task',
                onTap: onOpenTasks,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _DashboardMenu extends StatelessWidget {
  const _DashboardMenu({
    required this.icon,
    required this.label,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
          child: Column(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: colorScheme.primary),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TodayCard extends StatelessWidget {
  const _TodayCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value, style: Theme.of(context).textTheme.titleLarge),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OfflineBadge extends StatelessWidget {
  const _OfflineBadge();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Mode offline aktif',
      child: Chip(
        avatar: const Icon(Icons.offline_bolt, size: 16),
        label: const Text('Offline'),
        visualDensity: VisualDensity.compact,
        side: BorderSide.none,
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
    );
  }
}
