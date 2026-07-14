import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:nara/core/formatters/currency_formatter.dart';
import 'package:nara/features/finance/domain/entities/finance_category.dart';
import 'package:nara/features/finance/domain/entities/finance_snapshot.dart';
import 'package:nara/features/finance/domain/entities/finance_transaction.dart';
import 'package:nara/features/finance/presentation/providers/finance_providers.dart';
import 'package:nara/features/smart_scan/application/smart_scan_service.dart';
import 'package:nara/features/smart_scan/domain/entities/smart_scan_entities.dart';
import 'package:nara/features/smart_scan/presentation/providers/smart_scan_providers.dart';

class SmartScanPage extends ConsumerWidget {
  const SmartScanPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scan = ref.watch(smartScanControllerProvider);
    final finance = ref.watch(financeControllerProvider).value?.snapshot;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Scan'),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: Chip(
              avatar: Icon(Icons.offline_bolt, size: 16),
              label: Text('Offline'),
            ),
          ),
        ],
      ),
      body: scan.when(
        loading: () => const _ProcessingState(),
        error: (_, _) => _ScanError(
          message: 'Smart Scan belum dapat dibuka.',
          onRetry: () => ref.invalidate(smartScanControllerProvider),
        ),
        data: (state) {
          if (state.isProcessing) return const _ProcessingState();
          if (state.draft != null && finance != null) {
            return _DraftView(draft: state.draft!, finance: finance);
          }
          return _StartView(
            message: state.message,
            hasAccount: finance?.accounts.isNotEmpty ?? false,
          );
        },
      ),
    );
  }
}

class _StartView extends ConsumerWidget {
  const _StartView({required this.message, required this.hasAccount});
  final String? message;
  final bool hasAccount;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: Column(
          children: [
            Container(
              width: 112,
              height: 112,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.document_scanner_outlined,
                size: 52,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Scan struk atau bukti transfer',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text(
              'OCR dan klasifikasi berjalan langsung di perangkat. Foto dan teks hasil OCR tidak diunggah atau disimpan permanen.',
              textAlign: TextAlign.center,
            ),
            if (message != null) ...[
              const SizedBox(height: 16),
              Card(
                color: Theme.of(context).colorScheme.errorContainer,
                child: ListTile(
                  leading: const Icon(Icons.error_outline),
                  title: Text(message!),
                ),
              ),
            ],
            if (!hasAccount) ...[
              const SizedBox(height: 16),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.account_balance_wallet_outlined),
                  title: const Text('Buat akun Keuangan terlebih dahulu'),
                  subtitle: const Text(
                    'Smart Scan memerlukan akun tujuan untuk menyimpan transaksi.',
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            LayoutBuilder(
              builder: (context, constraints) {
                final buttons = [
                  Expanded(
                    child: FilledButton.icon(
                      key: const ValueKey('scan-camera'),
                      onPressed: hasAccount
                          ? () => ref
                                .read(smartScanControllerProvider.notifier)
                                .scan(ScanSource.camera)
                          : null,
                      icon: const Icon(Icons.camera_alt_outlined),
                      label: const Text('Kamera'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      key: const ValueKey('scan-gallery'),
                      onPressed: hasAccount
                          ? () => ref
                                .read(smartScanControllerProvider.notifier)
                                .scan(ScanSource.gallery)
                          : null,
                      icon: const Icon(Icons.photo_library_outlined),
                      label: const Text('Galeri'),
                    ),
                  ),
                ];
                return Row(children: buttons);
              },
            ),
            const SizedBox(height: 20),
            const _PhotoTips(),
          ],
        ),
      ),
    ),
  );
}

class _PhotoTips extends StatelessWidget {
  const _PhotoTips();
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Agar hasil lebih akurat',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          SizedBox(height: 8),
          Text(
            '• Pastikan seluruh dokumen terlihat\n• Gunakan cahaya yang cukup tanpa pantulan\n• Pegang kamera sejajar dan hindari foto buram',
          ),
        ],
      ),
    ),
  );
}

class _ProcessingState extends StatelessWidget {
  const _ProcessingState();
  @override
  Widget build(BuildContext context) => const Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircularProgressIndicator(),
        SizedBox(height: 18),
        Text('Memproses gambar di perangkat…'),
        SizedBox(height: 6),
        Text('Preprocessing • OCR • Klasifikasi'),
      ],
    ),
  );
}

class _DraftView extends ConsumerStatefulWidget {
  const _DraftView({required this.draft, required this.finance});
  final SmartScanDraft draft;
  final FinanceSnapshot finance;

  @override
  ConsumerState<_DraftView> createState() => _DraftViewState();
}

class _DraftViewState extends ConsumerState<_DraftView> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amount;
  late final TextEditingController _merchant;
  late FinanceTransactionType _type;
  late DateTime _date;
  late String _accountId;
  String? _categoryId;

  @override
  void initState() {
    super.initState();
    _amount = TextEditingController(
      text: widget.draft.amount?.toString() ?? '',
    );
    _merchant = TextEditingController(text: widget.draft.merchant);
    _type = FinanceTransactionType.expense;
    _date = widget.draft.date;
    _accountId = widget.finance.accounts.first.account.id;
    _selectSuggestedCategory();
  }

  void _selectSuggestedCategory() {
    final categories = _categories;
    final suggestion = widget.draft.categorySuggestion.toLowerCase();
    _categoryId = categories
        .where((item) => item.name.toLowerCase() == suggestion)
        .firstOrNull
        ?.id;
    _categoryId ??= categories.firstOrNull?.id;
  }

  List<FinanceCategory> get _categories =>
      widget.finance.categories.where((item) {
        return item.type ==
            (_type == FinanceTransactionType.income
                ? FinanceCategoryType.income
                : FinanceCategoryType.expense);
      }).toList();

  Future<void> _confirm() async {
    if (!_formKey.currentState!.validate() || _categoryId == null) return;
    final success = await ref
        .read(smartScanControllerProvider.notifier)
        .confirm(
          SmartScanConfirmInput(
            scanId: widget.draft.id,
            accountId: _accountId,
            categoryId: _categoryId!,
            type: _type,
            amount: CurrencyFormatter.parse(_amount.text)!,
            date: _date,
            merchant: _merchant.text,
            description: '${widget.draft.documentType.label} via Smart Scan',
          ),
        );
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Transaksi Smart Scan berhasil disimpan.'),
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _amount.dispose();
    _merchant.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scanState = ref.watch(smartScanControllerProvider).value;
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 760;
                  final image = _ImagePreview(draft: widget.draft);
                  final form = _DraftForm(
                    draft: widget.draft,
                    finance: widget.finance,
                    amount: _amount,
                    merchant: _merchant,
                    type: _type,
                    date: _date,
                    accountId: _accountId,
                    categoryId: _categoryId,
                    categories: _categories,
                    onTypeChanged: (value) => setState(() {
                      _type = value;
                      _selectSuggestedCategory();
                    }),
                    onAccountChanged: (value) =>
                        setState(() => _accountId = value),
                    onCategoryChanged: (value) =>
                        setState(() => _categoryId = value),
                    onDateChanged: (value) => setState(() => _date = value),
                  );
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Periksa draft',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                          ),
                          Chip(
                            label: Text(
                              '${(widget.draft.confidence * 100).round()}% confidence',
                            ),
                          ),
                        ],
                      ),
                      const Text(
                        'Belum ada transaksi yang disimpan. Periksa semua hasil OCR.',
                      ),
                      const SizedBox(height: 16),
                      if (wide)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: image),
                            const SizedBox(width: 18),
                            Expanded(child: form),
                          ],
                        )
                      else ...[
                        image,
                        const SizedBox(height: 16),
                        form,
                      ],
                      const SizedBox(height: 20),
                      Wrap(
                        alignment: WrapAlignment.end,
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          TextButton(
                            key: const ValueKey('scan-cancel'),
                            onPressed: scanState?.isProcessing ?? false
                                ? null
                                : () => ref
                                      .read(
                                        smartScanControllerProvider.notifier,
                                      )
                                      .cancel(),
                            child: const Text('Batal'),
                          ),
                          FilledButton.icon(
                            key: const ValueKey('scan-confirm'),
                            onPressed:
                                scanState?.isProcessing ??
                                    false || !widget.draft.canConfirm
                                ? null
                                : _confirm,
                            icon: const Icon(Icons.check),
                            label: const Text('Simpan transaksi'),
                          ),
                        ],
                      ),
                      if (scanState?.message != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            scanState!.message!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ImagePreview extends StatelessWidget {
  const _ImagePreview({required this.draft});
  final SmartScanDraft draft;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Image.file(
          File(draft.imagePath),
          height: 300,
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => const SizedBox(
            height: 180,
            child: Center(child: Icon(Icons.broken_image_outlined, size: 48)),
          ),
        ),
      ),
      const SizedBox(height: 10),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          Chip(
            avatar: const Icon(Icons.description_outlined, size: 17),
            label: Text(draft.documentType.label),
          ),
          Chip(
            avatar: Icon(
              draft.source == ScanSource.camera
                  ? Icons.camera_alt_outlined
                  : Icons.photo_library_outlined,
              size: 17,
            ),
            label: Text(draft.source.label),
          ),
        ],
      ),
      if (draft.isLowConfidence || draft.warnings.isNotEmpty)
        Card(
          color: Theme.of(context).colorScheme.errorContainer,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              ['Hasil perlu diperiksa manual.', ...draft.warnings].join('\n'),
            ),
          ),
        ),
      ExpansionTile(
        title: const Text('Lihat teks OCR'),
        subtitle: const Text('Tidak disimpan permanen'),
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: SelectableText(draft.rawText),
          ),
        ],
      ),
    ],
  );
}

class _DraftForm extends StatelessWidget {
  const _DraftForm({
    required this.draft,
    required this.finance,
    required this.amount,
    required this.merchant,
    required this.type,
    required this.date,
    required this.accountId,
    required this.categoryId,
    required this.categories,
    required this.onTypeChanged,
    required this.onAccountChanged,
    required this.onCategoryChanged,
    required this.onDateChanged,
  });
  final SmartScanDraft draft;
  final FinanceSnapshot finance;
  final TextEditingController amount;
  final TextEditingController merchant;
  final FinanceTransactionType type;
  final DateTime date;
  final String accountId;
  final String? categoryId;
  final List<FinanceCategory> categories;
  final ValueChanged<FinanceTransactionType> onTypeChanged;
  final ValueChanged<String> onAccountChanged;
  final ValueChanged<String?> onCategoryChanged;
  final ValueChanged<DateTime> onDateChanged;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          DropdownButtonFormField<FinanceTransactionType>(
            initialValue: type,
            decoration: const InputDecoration(
              labelText: 'Jenis transaksi',
              prefixIcon: Icon(Icons.swap_vert),
            ),
            items: const [
              DropdownMenuItem(
                value: FinanceTransactionType.expense,
                child: Text('Pengeluaran'),
              ),
              DropdownMenuItem(
                value: FinanceTransactionType.income,
                child: Text('Pemasukan'),
              ),
            ],
            onChanged: (value) => onTypeChanged(value!),
          ),
          const SizedBox(height: 12),
          TextFormField(
            key: const ValueKey('scan-amount'),
            controller: amount,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Nominal',
              prefixText: 'Rp ',
              prefixIcon: Icon(Icons.payments_outlined),
            ),
            validator: (value) =>
                (CurrencyFormatter.parse(value ?? '') ?? 0) <= 0
                ? 'Nominal wajib diperiksa.'
                : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            key: const ValueKey('scan-merchant'),
            controller: merchant,
            decoration: InputDecoration(
              labelText: draft.documentType == ScanDocumentType.transferProof
                  ? 'Penerima/pengirim'
                  : 'Merchant',
              prefixIcon: const Icon(Icons.store_outlined),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: accountId,
            decoration: const InputDecoration(
              labelText: 'Akun',
              prefixIcon: Icon(Icons.account_balance_wallet_outlined),
            ),
            items: finance.accounts
                .map(
                  (item) => DropdownMenuItem(
                    value: item.account.id,
                    child: Text(item.account.name),
                  ),
                )
                .toList(),
            onChanged: (value) => onAccountChanged(value!),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            key: ValueKey('scan-category-${type.name}'),
            initialValue: categoryId,
            decoration: const InputDecoration(
              labelText: 'Kategori',
              prefixIcon: Icon(Icons.category_outlined),
            ),
            items: categories
                .map(
                  (item) =>
                      DropdownMenuItem(value: item.id, child: Text(item.name)),
                )
                .toList(),
            onChanged: onCategoryChanged,
            validator: (value) =>
                value == null ? 'Kategori wajib dipilih.' : null,
          ),
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.event_outlined),
            title: const Text('Tanggal'),
            subtitle: Text(DateFormat('d MMMM yyyy', 'id_ID').format(date)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final selected = await showDatePicker(
                context: context,
                initialDate: date,
                firstDate: DateTime(2020),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (selected != null) onDateChanged(selected);
            },
          ),
        ],
      ),
    ),
  );
}

class _ScanError extends StatelessWidget {
  const _ScanError({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(message),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
          label: const Text('Coba lagi'),
        ),
      ],
    ),
  );
}
