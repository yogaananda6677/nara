import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nara/core/formatters/currency_formatter.dart';
import 'package:nara/features/finance/domain/entities/finance_account.dart';
import 'package:nara/features/finance/domain/entities/finance_category.dart';
import 'package:nara/features/finance/domain/entities/finance_snapshot.dart';
import 'package:nara/features/finance/domain/entities/finance_transaction.dart';
import 'package:nara/features/finance/domain/entities/saving_goal.dart';
import 'package:nara/features/finance/presentation/providers/finance_providers.dart';
import 'package:nara/features/finance/presentation/widgets/finance_forms.dart';
import 'package:nara/features/smart_scan/presentation/pages/smart_scan_page.dart';

class FinancePage extends ConsumerStatefulWidget {
  const FinancePage({super.key});

  @override
  ConsumerState<FinancePage> createState() => _FinancePageState();
}

class _FinancePageState extends ConsumerState<FinancePage> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _addAccount({FinanceAccount? existing}) async {
    final input = await showAccountForm(context, existing: existing);
    if (input == null) return;
    await ref
        .read(financeControllerProvider.notifier)
        .saveAccount(input, existing: existing);
  }

  Future<void> _addTransaction(
    FinanceSnapshot snapshot, {
    FinanceTransaction? existing,
  }) async {
    final input = await showTransactionForm(
      context,
      snapshot: snapshot,
      existing: existing,
    );
    if (input == null) return;
    await ref
        .read(financeControllerProvider.notifier)
        .saveTransaction(input, existing: existing);
  }

  Future<void> _addTransfer(FinanceSnapshot snapshot) async {
    final input = await showTransferForm(context, snapshot: snapshot);
    if (input == null) return;
    await ref.read(financeControllerProvider.notifier).transfer(input);
  }

  Future<void> _addSavingGoal(
    FinanceSnapshot snapshot, {
    SavingGoal? existing,
  }) async {
    final input = await showSavingGoalForm(
      context,
      snapshot: snapshot,
      existing: existing,
    );
    if (input == null) return;
    await ref
        .read(financeControllerProvider.notifier)
        .saveSavingGoal(input, existing: existing);
  }

  Future<bool> _confirm(String title, String message) async {
    return await showDialog<bool>(
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
                child: const Text('Lanjutkan'),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(financeControllerProvider, (previous, next) {
      final oldMessage = previous?.value?.message;
      final newMessage = next.value?.message;
      if (newMessage != null && newMessage != oldMessage) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(newMessage)));
      }
    });

    final finance = ref.watch(financeControllerProvider);
    return finance.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => _FinanceError(
        onRetry: () => ref.invalidate(financeControllerProvider),
      ),
      data: (state) => Scaffold(
        backgroundColor: Colors.transparent,
        floatingActionButton: state.snapshot.accounts.isEmpty
            ? null
            : FloatingActionButton.extended(
                key: const ValueKey('add-transaction'),
                heroTag: 'finance-add-transaction',
                onPressed: state.isMutating
                    ? null
                    : () => _addTransaction(state.snapshot),
                icon: const Icon(Icons.add),
                label: const Text('Transaksi'),
              ),
        body: RefreshIndicator(
          onRefresh: () =>
              ref.read(financeControllerProvider.notifier).refresh(),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 840;
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  isWide ? 32 : 20,
                  16,
                  isWide ? 32 : 20,
                  104,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1180),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _FinanceHeader(
                          onAddAccount: _addAccount,
                          onSmartScan: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (context) => const SmartScanPage(),
                            ),
                          ),
                          onManageCategories: () => showFinanceForm<void>(
                            context,
                            const CategoryManagerSheet(),
                          ),
                        ),
                        const SizedBox(height: 20),
                        _SummaryPanel(
                          summary: state.snapshot.summary,
                          month: state.month,
                          onPreviousMonth: () => ref
                              .read(financeControllerProvider.notifier)
                              .changeMonth(-1),
                          onNextMonth: () => ref
                              .read(financeControllerProvider.notifier)
                              .changeMonth(1),
                        ),
                        const SizedBox(height: 16),
                        _QuickActions(
                          canTransfer: state.snapshot.accounts.length >= 2,
                          onAccount: _addAccount,
                          onTransfer: () => _addTransfer(state.snapshot),
                          onSaving: () => _addSavingGoal(state.snapshot),
                          onCategory: () => showFinanceForm<void>(
                            context,
                            const CategoryManagerSheet(),
                          ),
                        ),
                        const SizedBox(height: 28),
                        if (isWide)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 360,
                                child: Column(
                                  children: [
                                    _AccountsSection(
                                      accounts: state.snapshot.accounts,
                                      onAdd: _addAccount,
                                      onEdit: (account) =>
                                          _addAccount(existing: account),
                                      onDelete: (account) async {
                                        if (await _confirm(
                                          'Hapus akun?',
                                          'Akun dengan histori akan diarsipkan agar transaksi tetap aman.',
                                        )) {
                                          await ref
                                              .read(
                                                financeControllerProvider
                                                    .notifier,
                                              )
                                              .deleteAccount(account.id);
                                        }
                                      },
                                    ),
                                    const SizedBox(height: 24),
                                    _SavingSection(
                                      goals: state.snapshot.savingGoals,
                                      onAdd: () =>
                                          _addSavingGoal(state.snapshot),
                                      onEdit: (goal) => _addSavingGoal(
                                        state.snapshot,
                                        existing: goal,
                                      ),
                                      onDelete: (goal) async {
                                        if (await _confirm(
                                          'Hapus target?',
                                          'Target tabungan ini akan dihapus.',
                                        )) {
                                          await ref
                                              .read(
                                                financeControllerProvider
                                                    .notifier,
                                              )
                                              .deleteSavingGoal(goal.id);
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 28),
                              Expanded(
                                child: _TransactionsSection(
                                  state: state,
                                  searchController: _searchController,
                                  onEdit: (transaction) => _addTransaction(
                                    state.snapshot,
                                    existing: transaction,
                                  ),
                                  onDelete: (transaction) async {
                                    if (await _confirm(
                                      'Hapus transaksi?',
                                      transaction.type.isTransfer
                                          ? 'Kedua sisi transfer akan dihapus.'
                                          : 'Transaksi ini akan dihapus permanen.',
                                    )) {
                                      await ref
                                          .read(
                                            financeControllerProvider.notifier,
                                          )
                                          .deleteTransaction(transaction.id);
                                    }
                                  },
                                ),
                              ),
                            ],
                          )
                        else ...[
                          _AccountsSection(
                            accounts: state.snapshot.accounts,
                            onAdd: _addAccount,
                            onEdit: (account) => _addAccount(existing: account),
                            onDelete: (account) async {
                              if (await _confirm(
                                'Hapus akun?',
                                'Akun dengan histori akan diarsipkan agar transaksi tetap aman.',
                              )) {
                                await ref
                                    .read(financeControllerProvider.notifier)
                                    .deleteAccount(account.id);
                              }
                            },
                          ),
                          const SizedBox(height: 24),
                          _SavingSection(
                            goals: state.snapshot.savingGoals,
                            onAdd: () => _addSavingGoal(state.snapshot),
                            onEdit: (goal) =>
                                _addSavingGoal(state.snapshot, existing: goal),
                            onDelete: (goal) async {
                              if (await _confirm(
                                'Hapus target?',
                                'Target tabungan ini akan dihapus.',
                              )) {
                                await ref
                                    .read(financeControllerProvider.notifier)
                                    .deleteSavingGoal(goal.id);
                              }
                            },
                          ),
                          const SizedBox(height: 24),
                          _TransactionsSection(
                            state: state,
                            searchController: _searchController,
                            onEdit: (transaction) => _addTransaction(
                              state.snapshot,
                              existing: transaction,
                            ),
                            onDelete: (transaction) async {
                              if (await _confirm(
                                'Hapus transaksi?',
                                transaction.type.isTransfer
                                    ? 'Kedua sisi transfer akan dihapus.'
                                    : 'Transaksi ini akan dihapus permanen.',
                              )) {
                                await ref
                                    .read(financeControllerProvider.notifier)
                                    .deleteTransaction(transaction.id);
                              }
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _FinanceHeader extends StatelessWidget {
  const _FinanceHeader({
    required this.onAddAccount,
    required this.onManageCategories,
    required this.onSmartScan,
  });

  final VoidCallback onAddAccount;
  final VoidCallback onManageCategories;
  final VoidCallback onSmartScan;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Keuangan',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              Text(
                'Kelola uang Anda secara offline',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        IconButton(
          key: const ValueKey('finance-smart-scan'),
          onPressed: onSmartScan,
          tooltip: 'Smart Scan',
          icon: const Icon(Icons.document_scanner_outlined),
        ),
        IconButton(
          onPressed: onManageCategories,
          tooltip: 'Kelola kategori',
          icon: const Icon(Icons.category_outlined),
        ),
        IconButton.filledTonal(
          key: const ValueKey('add-account'),
          onPressed: onAddAccount,
          tooltip: 'Tambah akun',
          icon: const Icon(Icons.add_card),
        ),
      ],
    );
  }
}

class _SummaryPanel extends StatelessWidget {
  const _SummaryPanel({
    required this.summary,
    required this.month,
    required this.onPreviousMonth,
    required this.onNextMonth,
  });

  final FinanceSummary summary;
  final DateTime month;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF8E1717), Color(0xFFD93434)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Total saldo',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
              IconButton(
                onPressed: onPreviousMonth,
                tooltip: 'Bulan sebelumnya',
                color: Colors.white,
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.chevron_left),
              ),
              Text(
                _monthLabel(month),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              IconButton(
                onPressed: onNextMonth,
                tooltip: 'Bulan berikutnya',
                color: Colors.white,
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
          Text(
            CurrencyFormatter.rupiah(summary.totalBalance),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 28,
            runSpacing: 12,
            children: [
              _SummaryValue(
                icon: Icons.south_west,
                label: 'Pemasukan',
                value: summary.monthlyIncome,
              ),
              _SummaryValue(
                icon: Icons.north_east,
                label: 'Pengeluaran',
                value: summary.monthlyExpense,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryValue extends StatelessWidget {
  const _SummaryValue({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.white70)),
            Text(
              CurrencyFormatter.rupiah(value),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.canTransfer,
    required this.onAccount,
    required this.onTransfer,
    required this.onSaving,
    required this.onCategory,
  });

  final bool canTransfer;
  final VoidCallback onAccount;
  final VoidCallback onTransfer;
  final VoidCallback onSaving;
  final VoidCallback onCategory;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _ActionChip(icon: Icons.add_card, label: 'Akun', onTap: onAccount),
          const SizedBox(width: 8),
          _ActionChip(
            icon: Icons.swap_horiz,
            label: 'Transfer',
            onTap: canTransfer ? onTransfer : null,
          ),
          const SizedBox(width: 8),
          _ActionChip(
            icon: Icons.savings_outlined,
            label: 'Tabungan',
            onTap: onSaving,
          ),
          const SizedBox(width: 8),
          _ActionChip(
            icon: Icons.category_outlined,
            label: 'Kategori',
            onTap: onCategory,
          ),
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      onPressed: onTap,
    );
  }
}

class _AccountsSection extends StatelessWidget {
  const _AccountsSection({
    required this.accounts,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  final List<AccountBalance> accounts;
  final VoidCallback onAdd;
  final ValueChanged<FinanceAccount> onEdit;
  final ValueChanged<FinanceAccount> onDelete;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Akun saya',
      action: TextButton.icon(
        onPressed: onAdd,
        icon: const Icon(Icons.add, size: 18),
        label: const Text('Tambah'),
      ),
      child: accounts.isEmpty
          ? _EmptyState(
              icon: Icons.account_balance_wallet_outlined,
              title: 'Belum ada akun',
              description: 'Buat akun pertama untuk mulai mencatat transaksi.',
              actionLabel: 'Buat akun',
              onAction: onAdd,
            )
          : Column(
              children: accounts
                  .map(
                    (item) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        child: Icon(_accountIcon(item.account.type)),
                      ),
                      title: Text(item.account.name),
                      subtitle: Text(item.account.type.label),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            CurrencyFormatter.rupiah(item.balance),
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          PopupMenuButton<String>(
                            tooltip: 'Opsi akun ${item.account.name}',
                            onSelected: (action) {
                              if (action == 'edit') onEdit(item.account);
                              if (action == 'delete') onDelete(item.account);
                            },
                            itemBuilder: (context) => const [
                              PopupMenuItem(value: 'edit', child: Text('Edit')),
                              PopupMenuItem(
                                value: 'delete',
                                child: Text('Hapus/arsipkan'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
    );
  }
}

class _SavingSection extends StatelessWidget {
  const _SavingSection({
    required this.goals,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  final List<SavingGoal> goals;
  final VoidCallback onAdd;
  final ValueChanged<SavingGoal> onEdit;
  final ValueChanged<SavingGoal> onDelete;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Target tabungan',
      action: TextButton.icon(
        onPressed: onAdd,
        icon: const Icon(Icons.add, size: 18),
        label: const Text('Tambah'),
      ),
      child: goals.isEmpty
          ? _EmptyState(
              icon: Icons.savings_outlined,
              title: 'Belum ada target',
              description: 'Buat target agar progres tabungan mudah dipantau.',
              actionLabel: 'Buat target',
              onAction: onAdd,
            )
          : Column(
              children: goals.map((goal) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: InkWell(
                    onTap: () => onEdit(goal),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  goal.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: () => onDelete(goal),
                                tooltip: 'Hapus target ${goal.name}',
                                icon: const Icon(
                                  Icons.delete_outline,
                                  size: 20,
                                ),
                              ),
                            ],
                          ),
                          LinearProgressIndicator(
                            value: goal.progress,
                            minHeight: 8,
                            borderRadius: BorderRadius.circular(99),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${CurrencyFormatter.rupiah(goal.savedAmount)} dari ${CurrencyFormatter.rupiah(goal.targetAmount)}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
    );
  }
}

class _TransactionsSection extends ConsumerWidget {
  const _TransactionsSection({
    required this.state,
    required this.searchController,
    required this.onEdit,
    required this.onDelete,
  });

  final FinanceState state;
  final TextEditingController searchController;
  final ValueChanged<FinanceTransaction> onEdit;
  final ValueChanged<FinanceTransaction> onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = state.snapshot;
    return _SectionCard(
      title: 'Riwayat transaksi',
      child: Column(
        children: [
          TextField(
            controller: searchController,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Cari transaksi…',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: searchController.text.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        searchController.clear();
                        ref
                            .read(financeControllerProvider.notifier)
                            .setSearch('');
                      },
                      tooltip: 'Hapus pencarian',
                      icon: const Icon(Icons.close),
                    ),
            ),
            onChanged: (value) =>
                ref.read(financeControllerProvider.notifier).setSearch(value),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: TransactionFilter.values
                  .map(
                    (filter) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(filter.label),
                        selected: state.filter == filter,
                        onSelected: (_) => ref
                            .read(financeControllerProvider.notifier)
                            .setFilter(filter),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 8),
          if (snapshot.transactions.isEmpty)
            const _EmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'Tidak ada transaksi',
              description: 'Belum ada data yang cocok pada periode ini.',
            )
          else
            ...snapshot.transactions.map((transaction) {
              final account = snapshot.accounts
                  .where((item) => item.account.id == transaction.accountId)
                  .firstOrNull;
              final category = snapshot.categories
                  .where((item) => item.id == transaction.categoryId)
                  .firstOrNull;
              return _TransactionTile(
                transaction: transaction,
                accountName: account?.account.name ?? 'Akun diarsipkan',
                category: category,
                onEdit: transaction.type.isTransfer
                    ? null
                    : () => onEdit(transaction),
                onDelete: () => onDelete(transaction),
              );
            }),
        ],
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({
    required this.transaction,
    required this.accountName,
    required this.category,
    required this.onEdit,
    required this.onDelete,
  });

  final FinanceTransaction transaction;
  final String accountName;
  final FinanceCategory? category;
  final VoidCallback? onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isIncome =
        transaction.type == FinanceTransactionType.income ||
        transaction.type == FinanceTransactionType.transferIn;
    final title = transaction.type.isTransfer
        ? 'Transfer antar akun'
        : transaction.merchant ?? category?.name ?? 'Transaksi';

    return Semantics(
      label:
          '$title, ${isIncome ? 'masuk' : 'keluar'} ${CurrencyFormatter.rupiah(transaction.amount)}',
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: CircleAvatar(
          backgroundColor: isIncome
              ? Colors.green.withValues(alpha: 0.12)
              : Theme.of(context).colorScheme.primaryContainer,
          child: Icon(
            isIncome ? Icons.south_west : Icons.north_east,
            color: isIncome
                ? Colors.green.shade700
                : Theme.of(context).colorScheme.primary,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            const SizedBox(width: 8),
            Text(
              '${isIncome ? '+' : '-'}${CurrencyFormatter.rupiah(transaction.amount)}',
              style: TextStyle(
                color: isIncome
                    ? Colors.green.shade700
                    : Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        subtitle: Text(
          '$accountName • ${_shortDate(transaction.date.toLocal())}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: PopupMenuButton<String>(
          tooltip: 'Opsi transaksi',
          onSelected: (action) {
            if (action == 'edit') onEdit?.call();
            if (action == 'delete') onDelete();
          },
          itemBuilder: (context) => [
            if (onEdit != null)
              const PopupMenuItem(value: 'edit', child: Text('Edit')),
            const PopupMenuItem(value: 'delete', child: Text('Hapus')),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child, this.action});

  final String title;
  final Widget child;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                ...?(action == null ? null : [action!]),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.description,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String description;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Icon(
            icon,
            size: 44,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(description, textAlign: TextAlign.center),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 12),
            FilledButton.tonal(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}

class _FinanceError extends StatelessWidget {
  const _FinanceError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 12),
            const Text('Data keuangan belum dapat dibuka.'),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba lagi'),
            ),
          ],
        ),
      ),
    );
  }
}

IconData _accountIcon(FinanceAccountType type) => switch (type) {
  FinanceAccountType.cash => Icons.payments_outlined,
  FinanceAccountType.bank => Icons.account_balance_outlined,
  FinanceAccountType.ewallet => Icons.phone_android,
};

String _monthLabel(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];
  return '${months[date.month - 1]} ${date.year}';
}

String _shortDate(DateTime date) => '${date.day}/${date.month}/${date.year}';
