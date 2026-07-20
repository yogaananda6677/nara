import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nara/core/formatters/currency_formatter.dart';
import 'package:nara/features/finance/application/finance_service.dart';
import 'package:nara/features/finance/domain/entities/finance_account.dart';
import 'package:nara/features/finance/domain/entities/finance_category.dart';
import 'package:nara/features/finance/domain/entities/finance_snapshot.dart';
import 'package:nara/features/finance/domain/entities/finance_transaction.dart';
import 'package:nara/features/finance/domain/entities/saving_goal.dart';
import 'package:nara/features/finance/presentation/providers/finance_providers.dart';

Future<T?> showFinanceForm<T>(BuildContext context, Widget child) {
  final isWide = MediaQuery.sizeOf(context).width >= 700;
  if (isWide) {
    return showDialog<T>(
      context: context,
      builder: (context) => Dialog(
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560, maxHeight: 760),
          child: child,
        ),
      ),
    );
  }

  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (context) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: child,
    ),
  );
}

Future<AccountInput?> showAccountForm(
  BuildContext context, {
  FinanceAccount? existing,
}) {
  return showFinanceForm(context, AccountFormSheet(existing: existing));
}

class AccountFormSheet extends StatefulWidget {
  const AccountFormSheet({this.existing, super.key});

  final FinanceAccount? existing;

  @override
  State<AccountFormSheet> createState() => _AccountFormSheetState();
}

class _AccountFormSheetState extends State<AccountFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _balanceController;
  late FinanceAccountType _type;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existing?.name);
    _balanceController = TextEditingController(
      text: widget.existing == null
          ? ''
          : widget.existing!.openingBalance.toString(),
    );
    _type = widget.existing?.type ?? FinanceAccountType.cash;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      AccountInput(
        name: _nameController.text,
        type: _type,
        openingBalance: CurrencyFormatter.parse(_balanceController.text) ?? 0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _FormShell(
      title: widget.existing == null ? 'Tambah akun' : 'Edit akun',
      actionLabel: 'Simpan akun',
      onSubmit: _submit,
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(
              key: const ValueKey('account-name'),
              controller: _nameController,
              autofocus: true,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Nama akun',
                hintText: 'Contoh: Dompet utama',
                prefixIcon: Icon(Icons.account_balance_wallet_outlined),
              ),
              validator: _required,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<FinanceAccountType>(
              initialValue: _type,
              decoration: const InputDecoration(
                labelText: 'Jenis akun',
                prefixIcon: Icon(Icons.category_outlined),
              ),
              items: FinanceAccountType.values
                  .map(
                    (type) =>
                        DropdownMenuItem(value: type, child: Text(type.label)),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _type = value ?? _type),
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const ValueKey('account-balance'),
              controller: _balanceController,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'Saldo awal',
                prefixText: 'Rp ',
                prefixIcon: Icon(Icons.payments_outlined),
              ),
              validator: _moneyAllowZero,
              onFieldSubmitted: (_) => _submit(),
            ),
          ],
        ),
      ),
    );
  }
}

Future<TransactionInput?> showTransactionForm(
  BuildContext context, {
  required FinanceSnapshot snapshot,
  FinanceTransaction? existing,
}) {
  return showFinanceForm(
    context,
    TransactionFormSheet(snapshot: snapshot, existing: existing),
  );
}

class TransactionFormSheet extends StatefulWidget {
  const TransactionFormSheet({
    required this.snapshot,
    this.existing,
    super.key,
  });

  final FinanceSnapshot snapshot;
  final FinanceTransaction? existing;

  @override
  State<TransactionFormSheet> createState() => _TransactionFormSheetState();
}

class _TransactionFormSheetState extends State<TransactionFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _merchantController;
  late FinanceTransactionType _type;
  late String _accountId;
  String? _categoryId;
  late DateTime _date;

  List<FinanceCategory> get _categories => widget.snapshot.categories
      .where((category) => category.type.name == _type.name)
      .toList();

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _type = existing?.type == FinanceTransactionType.income
        ? FinanceTransactionType.income
        : FinanceTransactionType.expense;
    _accountId =
        existing?.accountId ?? widget.snapshot.accounts.first.account.id;
    _categoryId = existing?.categoryId;
    _date = existing?.date.toLocal() ?? DateTime.now();
    _amountController = TextEditingController(
      text: existing?.amount.toString() ?? '',
    );
    _descriptionController = TextEditingController(text: existing?.description);
    _merchantController = TextEditingController(text: existing?.merchant);
    if (!_categories.any((category) => category.id == _categoryId)) {
      _categoryId = _categories.firstOrNull?.id;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _merchantController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (selected != null) setState(() => _date = selected);
  }

  void _submit() {
    if (!_formKey.currentState!.validate() || _categoryId == null) return;
    Navigator.pop(
      context,
      TransactionInput(
        accountId: _accountId,
        categoryId: _categoryId!,
        type: _type,
        amount: CurrencyFormatter.parse(_amountController.text)!,
        date: _date,
        description: _descriptionController.text,
        merchant: _merchantController.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _FormShell(
      title: widget.existing == null ? 'Tambah transaksi' : 'Edit transaksi',
      actionLabel: 'Simpan transaksi',
      onSubmit: _submit,
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            SegmentedButton<FinanceTransactionType>(
              segments: const [
                ButtonSegment(
                  value: FinanceTransactionType.expense,
                  icon: Icon(Icons.north_east),
                  label: Text('Pengeluaran'),
                ),
                ButtonSegment(
                  value: FinanceTransactionType.income,
                  icon: Icon(Icons.south_west),
                  label: Text('Pemasukan'),
                ),
              ],
              selected: {_type},
              onSelectionChanged: (value) {
                setState(() {
                  _type = value.single;
                  _categoryId = _categories.firstOrNull?.id;
                });
              },
            ),
            const SizedBox(height: 20),
            TextFormField(
              key: const ValueKey('transaction-amount'),
              controller: _amountController,
              autofocus: true,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Nominal',
                prefixText: 'Rp ',
                prefixIcon: Icon(Icons.payments_outlined),
              ),
              validator: _moneyPositive,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _accountId,
              decoration: const InputDecoration(
                labelText: 'Akun',
                prefixIcon: Icon(Icons.account_balance_wallet_outlined),
              ),
              items: widget.snapshot.accounts
                  .map(
                    (item) => DropdownMenuItem(
                      value: item.account.id,
                      child: Text(item.account.name),
                    ),
                  )
                  .toList(),
              onChanged: (value) => _accountId = value ?? _accountId,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              key: ValueKey('category-${_type.name}'),
              initialValue: _categoryId,
              decoration: const InputDecoration(
                labelText: 'Kategori',
                prefixIcon: Icon(Icons.sell_outlined),
              ),
              items: _categories
                  .map(
                    (category) => DropdownMenuItem(
                      value: category.id,
                      child: Text(category.name),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _categoryId = value),
              validator: (value) => value == null ? 'Pilih kategori.' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _merchantController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Merchant/sumber (opsional)',
                prefixIcon: Icon(Icons.storefront_outlined),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'Catatan (opsional)',
                prefixIcon: Icon(Icons.notes),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today_outlined),
              title: const Text('Tanggal transaksi'),
              subtitle: Text(_dateLabel(_date)),
              trailing: const Icon(Icons.chevron_right),
              onTap: _pickDate,
            ),
          ],
        ),
      ),
    );
  }
}

Future<TransferInput?> showTransferForm(
  BuildContext context, {
  required FinanceSnapshot snapshot,
}) {
  return showFinanceForm(context, TransferFormSheet(snapshot: snapshot));
}

class TransferFormSheet extends StatefulWidget {
  const TransferFormSheet({required this.snapshot, super.key});

  final FinanceSnapshot snapshot;

  @override
  State<TransferFormSheet> createState() => _TransferFormSheetState();
}

class _TransferFormSheetState extends State<TransferFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  late String _fromId;
  late String _toId;

  @override
  void initState() {
    super.initState();
    _fromId = widget.snapshot.accounts.first.account.id;
    _toId = widget.snapshot.accounts[1].account.id;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      TransferInput(
        fromAccountId: _fromId,
        toAccountId: _toId,
        amount: CurrencyFormatter.parse(_amountController.text)!,
        date: DateTime.now(),
        description: _descriptionController.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accounts = widget.snapshot.accounts;
    return _FormShell(
      title: 'Transfer antar akun',
      actionLabel: 'Simpan transfer',
      onSubmit: _submit,
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              initialValue: _fromId,
              decoration: const InputDecoration(
                labelText: 'Dari akun',
                prefixIcon: Icon(Icons.upload),
              ),
              items: accounts
                  .map(
                    (item) => DropdownMenuItem(
                      value: item.account.id,
                      child: Text(item.account.name),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _fromId = value ?? _fromId),
              validator: (_) => _fromId == _toId ? 'Pilih akun berbeda.' : null,
            ),
            const SizedBox(height: 12),
            Icon(
              Icons.arrow_downward,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _toId,
              decoration: const InputDecoration(
                labelText: 'Ke akun',
                prefixIcon: Icon(Icons.download),
              ),
              items: accounts
                  .map(
                    (item) => DropdownMenuItem(
                      value: item.account.id,
                      child: Text(item.account.name),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _toId = value ?? _toId),
              validator: (_) => _fromId == _toId ? 'Pilih akun berbeda.' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Nominal transfer',
                prefixText: 'Rp ',
                prefixIcon: Icon(Icons.payments_outlined),
              ),
              validator: _moneyPositive,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Catatan (opsional)',
                prefixIcon: Icon(Icons.notes),
              ),
              onFieldSubmitted: (_) => _submit(),
            ),
          ],
        ),
      ),
    );
  }
}

Future<SavingGoalInput?> showSavingGoalForm(
  BuildContext context, {
  required FinanceSnapshot snapshot,
  SavingGoal? existing,
}) {
  return showFinanceForm(
    context,
    SavingGoalFormSheet(snapshot: snapshot, existing: existing),
  );
}

class SavingGoalFormSheet extends StatefulWidget {
  const SavingGoalFormSheet({required this.snapshot, this.existing, super.key});

  final FinanceSnapshot snapshot;
  final SavingGoal? existing;

  @override
  State<SavingGoalFormSheet> createState() => _SavingGoalFormSheetState();
}

class _SavingGoalFormSheetState extends State<SavingGoalFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _targetController;
  late final TextEditingController _savedController;
  String? _accountId;
  DateTime? _targetDate;
  bool get _usesLinkedAccount => _accountId != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _nameController = TextEditingController(text: existing?.name);
    _targetController = TextEditingController(
      text: existing?.targetAmount.toString() ?? '',
    );
    _savedController = TextEditingController(
      text: existing?.savedAmount.toString() ?? '0',
    );
    _accountId = existing?.accountId;
    _targetDate = existing?.targetDate?.toLocal();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _targetController.dispose();
    _savedController.dispose();
    super.dispose();
  }

  Future<void> _pickTargetDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _targetDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (selected != null) setState(() => _targetDate = selected);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      SavingGoalInput(
        name: _nameController.text,
        targetAmount: CurrencyFormatter.parse(_targetController.text)!,
        savedAmount: _usesLinkedAccount
            ? 0
            : CurrencyFormatter.parse(_savedController.text) ?? 0,
        accountId: _accountId,
        targetDate: _targetDate,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _FormShell(
      title: widget.existing == null ? 'Target tabungan' : 'Edit tabungan',
      actionLabel: 'Simpan target',
      onSubmit: _submit,
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(
              controller: _nameController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Nama target',
                hintText: 'Contoh: Dana darurat',
                prefixIcon: Icon(Icons.flag_outlined),
              ),
              validator: _required,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _targetController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Nominal target',
                prefixText: 'Rp ',
                prefixIcon: Icon(Icons.savings_outlined),
              ),
              validator: _moneyPositive,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _accountId ?? '',
              decoration: const InputDecoration(
                labelText: 'Hubungkan ke akun/dompet (opsional)',
                prefixIcon: Icon(Icons.account_balance_wallet_outlined),
              ),
              items: [
                const DropdownMenuItem<String>(
                  value: '',
                  child: Text('Tanpa akun khusus'),
                ),
                ...widget.snapshot.accounts.map(
                  (item) => DropdownMenuItem<String>(
                    value: item.account.id,
                    child: Text(item.account.name),
                  ),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _accountId = value == null || value.isEmpty ? null : value;
                  if (_usesLinkedAccount) _savedController.text = '0';
                });
              },
            ),
            const SizedBox(height: 16),
            if (!_usesLinkedAccount) ...[
              TextFormField(
                controller: _savedController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Sudah terkumpul',
                  prefixText: 'Rp ',
                  prefixIcon: Icon(Icons.account_balance_outlined),
                ),
                validator: (value) {
                  final saved = CurrencyFormatter.parse(value ?? '') ?? 0;
                  final target = CurrencyFormatter.parse(
                    _targetController.text,
                  );
                  if (target != null && saved > target) {
                    return 'Dana terkumpul melebihi target.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
            ] else ...[
              _LinkedAccountNotice(
                accountId: _accountId!,
                snapshot: widget.snapshot,
              ),
              const SizedBox(height: 16),
            ],
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event_outlined),
              title: const Text('Target tanggal (opsional)'),
              subtitle: Text(
                _targetDate == null
                    ? 'Belum ditentukan'
                    : _dateLabel(_targetDate!),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: _pickTargetDate,
            ),
          ],
        ),
      ),
    );
  }
}

class _LinkedAccountNotice extends StatelessWidget {
  const _LinkedAccountNotice({required this.accountId, required this.snapshot});

  final String accountId;
  final FinanceSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final account = snapshot.accounts
        .where((item) => item.account.id == accountId)
        .firstOrNull;
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.secondaryContainer.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(Icons.link, color: colors.secondary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              account == null
                  ? 'Progress tabungan akan mengikuti saldo akun terkait.'
                  : 'Progress mengikuti saldo ${account.account.name}: ${CurrencyFormatter.rupiah(account.balance)}.',
              style: TextStyle(
                color: colors.onSecondaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CategoryManagerSheet extends ConsumerStatefulWidget {
  const CategoryManagerSheet({super.key});

  @override
  ConsumerState<CategoryManagerSheet> createState() =>
      _CategoryManagerSheetState();
}

class _CategoryManagerSheetState extends ConsumerState<CategoryManagerSheet> {
  var _type = FinanceCategoryType.expense;

  Future<void> _addOrEdit({FinanceCategory? existing}) async {
    final input = await showFinanceForm<CategoryInput>(
      context,
      CategoryFormSheet(type: _type, existing: existing),
    );
    if (input == null) return;
    await ref
        .read(financeControllerProvider.notifier)
        .saveCategory(input, existing: existing);
  }

  @override
  Widget build(BuildContext context) {
    final finance = ref.watch(financeControllerProvider).value;
    final categories =
        finance?.snapshot.categories
            .where((category) => category.type == _type)
            .toList() ??
        const <FinanceCategory>[];

    return _FormShell(
      title: 'Kelola kategori',
      actionLabel: 'Tambah kategori',
      onSubmit: _addOrEdit,
      child: Column(
        children: [
          SegmentedButton<FinanceCategoryType>(
            segments: const [
              ButtonSegment(
                value: FinanceCategoryType.expense,
                label: Text('Pengeluaran'),
              ),
              ButtonSegment(
                value: FinanceCategoryType.income,
                label: Text('Pemasukan'),
              ),
            ],
            selected: {_type},
            onSelectionChanged: (value) => setState(() => _type = value.single),
          ),
          const SizedBox(height: 16),
          ...categories.map(
            (category) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                child: Icon(
                  category.isSystem ? Icons.sell_outlined : Icons.label_outline,
                ),
              ),
              title: Text(category.name),
              subtitle: Text(
                category.isSystem ? 'Kategori bawaan' : 'Kategori Anda',
              ),
              trailing: category.isSystem
                  ? const Icon(Icons.lock_outline, size: 20)
                  : PopupMenuButton<String>(
                      onSelected: (action) async {
                        if (action == 'edit') {
                          await _addOrEdit(existing: category);
                        }
                        if (action == 'delete') {
                          await ref
                              .read(financeControllerProvider.notifier)
                              .deleteCategory(category.id);
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(value: 'edit', child: Text('Edit')),
                        PopupMenuItem(value: 'delete', child: Text('Hapus')),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class CategoryFormSheet extends StatefulWidget {
  const CategoryFormSheet({required this.type, this.existing, super.key});

  final FinanceCategoryType type;
  final FinanceCategory? existing;

  @override
  State<CategoryFormSheet> createState() => _CategoryFormSheetState();
}

class _CategoryFormSheetState extends State<CategoryFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late FinanceCategoryType _type;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existing?.name);
    _type = widget.existing?.type ?? widget.type;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      CategoryInput(name: _nameController.text, type: _type),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _FormShell(
      title: widget.existing == null ? 'Tambah kategori' : 'Edit kategori',
      actionLabel: 'Simpan kategori',
      onSubmit: _submit,
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(
              controller: _nameController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Nama kategori',
                prefixIcon: Icon(Icons.label_outline),
              ),
              validator: _required,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<FinanceCategoryType>(
              initialValue: _type,
              decoration: const InputDecoration(labelText: 'Jenis kategori'),
              items: FinanceCategoryType.values
                  .map(
                    (type) =>
                        DropdownMenuItem(value: type, child: Text(type.label)),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _type = value ?? _type),
            ),
          ],
        ),
      ),
    );
  }
}

class _FormShell extends StatelessWidget {
  const _FormShell({
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
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.maybePop(context),
                tooltip: 'Tutup',
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
          const SizedBox(height: 24),
          FilledButton(onPressed: onSubmit, child: Text(actionLabel)),
        ],
      ),
    );
  }
}

String? _required(String? value) {
  return value == null || value.trim().isEmpty ? 'Wajib diisi.' : null;
}

String? _moneyPositive(String? value) {
  final amount = CurrencyFormatter.parse(value ?? '');
  return amount == null || amount <= 0 ? 'Masukkan nominal yang valid.' : null;
}

String? _moneyAllowZero(String? value) {
  if (value == null || value.trim().isEmpty) return null;
  return CurrencyFormatter.parse(value) == null ? 'Nominal tidak valid.' : null;
}

String _dateLabel(DateTime value) {
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
  return '${value.day} ${months[value.month - 1]} ${value.year}';
}
