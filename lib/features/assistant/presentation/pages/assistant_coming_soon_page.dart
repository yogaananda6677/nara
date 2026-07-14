import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:nara/core/formatters/currency_formatter.dart';
import 'package:nara/features/assistant/domain/entities/assistant_entities.dart';
import 'package:nara/features/assistant/presentation/providers/assistant_providers.dart';

class AssistantPage extends ConsumerStatefulWidget {
  const AssistantPage({super.key});

  @override
  ConsumerState<AssistantPage> createState() => _AssistantPageState();
}

class _AssistantPageState extends ConsumerState<AssistantPage> {
  final _input = TextEditingController();
  final _scroll = ScrollController();

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send([String? example]) async {
    final text = example ?? _input.text;
    if (text.trim().isEmpty) return;
    _input.clear();
    await ref.read(assistantControllerProvider.notifier).submit(text);
    if (mounted) {
      FocusScope.of(context).unfocus();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_scroll.hasClients) return;
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final assistant = ref.watch(assistantControllerProvider);
    return assistant.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => Center(
        child: FilledButton.icon(
          onPressed: () => ref.invalidate(assistantControllerProvider),
          icon: const Icon(Icons.refresh),
          label: const Text('Coba lagi'),
        ),
      ),
      data: (state) => Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(
                children: [
                  _Header(
                    onClear: state.messages.length <= 1
                        ? null
                        : () => _confirmClear(context),
                  ),
                  Expanded(
                    child: ListView(
                      controller: _scroll,
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      children: [
                        if (state.messages.length <= 1)
                          _Examples(onSelect: _send),
                        ...state.messages.map(
                          (message) => _MessageBubble(message: message),
                        ),
                        if (state.pendingDraft != null)
                          _PreviewCard(
                            draft: state.pendingDraft!,
                            isProcessing: state.isProcessing,
                            onConfirm: () => ref
                                .read(assistantControllerProvider.notifier)
                                .confirm(),
                            onCancel: () => ref
                                .read(assistantControllerProvider.notifier)
                                .cancel(),
                            onEdit: () => _editDraft(state.pendingDraft!),
                          ),
                        if (state.isProcessing)
                          const Padding(
                            padding: EdgeInsets.all(16),
                            child: LinearProgressIndicator(),
                          ),
                      ],
                    ),
                  ),
                  _Composer(
                    controller: _input,
                    enabled: !state.isProcessing,
                    onSend: _send,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _editDraft(AssistantDraft draft) async {
    final arguments = await showDialog<Map<String, Object?>>(
      context: context,
      builder: (_) => _EditDraftDialog(draft: draft),
    );
    if (arguments != null) {
      ref.read(assistantControllerProvider.notifier).updatePending(arguments);
    }
  }

  Future<void> _confirmClear(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus riwayat chat?'),
        content: const Text(
          'Data keuangan, task, dan jadwal tidak ikut dihapus.',
        ),
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
    );
    if (confirmed ?? false) {
      await ref.read(assistantControllerProvider.notifier).clearHistory();
    }
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onClear});
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
    child: Row(
      children: [
        CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Icon(
            Icons.auto_awesome,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Asisten Nara',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
              ),
              Row(
                children: [
                  Icon(Icons.offline_bolt, size: 14, color: Colors.green),
                  SizedBox(width: 4),
                  Text('Lokal • Offline', style: TextStyle(fontSize: 12)),
                ],
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: onClear,
          tooltip: 'Hapus riwayat chat',
          icon: const Icon(Icons.delete_sweep_outlined),
        ),
      ],
    ),
  );
}

class _Examples extends StatelessWidget {
  const _Examples({required this.onSelect});
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Coba perintah', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                [
                      'Catat pengeluaran makan 25 ribu',
                      'Buat task laporan besok sore',
                      'Jadwalkan rapat besok jam 9',
                      'Ringkasan keuangan bulan ini',
                    ]
                    .map(
                      (text) => ActionChip(
                        label: Text(text),
                        onPressed: () => onSelect(text),
                      ),
                    )
                    .toList(),
          ),
        ],
      ),
    ),
  );
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});
  final AssistantMessage message;

  @override
  Widget build(BuildContext context) {
    final user = message.role == AssistantRole.user;
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      label: '${user ? 'Anda' : 'Nara'}: ${message.content}',
      child: Align(
        alignment: user ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 640),
          margin: const EdgeInsets.symmetric(vertical: 5),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: user ? colors.primary : colors.surfaceContainerHighest,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(user ? 18 : 4),
              bottomRight: Radius.circular(user ? 4 : 18),
            ),
          ),
          child: Text(
            message.content,
            style: TextStyle(color: user ? colors.onPrimary : null),
          ),
        ),
      ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({
    required this.draft,
    required this.isProcessing,
    required this.onConfirm,
    required this.onCancel,
    required this.onEdit,
  });
  final AssistantDraft draft;
  final bool isProcessing;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) => Card(
    color: Theme.of(context).colorScheme.primaryContainer,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.fact_check_outlined),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Preview • ${_toolLabel(draft.tool)}',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              const Chip(label: Text('BELUM DISIMPAN')),
            ],
          ),
          const Divider(),
          ..._previewRows(draft).map(
            (row) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 92, child: Text(row.$1)),
                  Expanded(
                    child: Text(
                      row.$2,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 8,
            runSpacing: 8,
            children: [
              TextButton(
                key: const ValueKey('assistant-cancel'),
                onPressed: isProcessing ? null : onCancel,
                child: const Text('Batal'),
              ),
              OutlinedButton.icon(
                key: const ValueKey('assistant-edit'),
                onPressed: isProcessing ? null : onEdit,
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Ubah'),
              ),
              FilledButton.icon(
                key: const ValueKey('assistant-confirm'),
                onPressed: isProcessing ? null : onConfirm,
                icon: const Icon(Icons.check),
                label: const Text('Konfirmasi'),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.enabled,
    required this.onSend,
  });
  final TextEditingController controller;
  final bool enabled;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) => Material(
    elevation: 3,
    child: SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                key: const ValueKey('assistant-input'),
                controller: controller,
                enabled: enabled,
                minLines: 1,
                maxLines: 4,
                maxLength: 500,
                decoration: const InputDecoration(
                  hintText: 'Ketik perintah offline…',
                  counterText: '',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                onSubmitted: (_) => onSend(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              key: const ValueKey('assistant-send'),
              onPressed: enabled ? onSend : null,
              tooltip: 'Kirim',
              icon: const Icon(Icons.send),
            ),
          ],
        ),
      ),
    ),
  );
}

class _EditDraftDialog extends StatefulWidget {
  const _EditDraftDialog({required this.draft});
  final AssistantDraft draft;

  @override
  State<_EditDraftDialog> createState() => _EditDraftDialogState();
}

class _EditDraftDialogState extends State<_EditDraftDialog> {
  late final TextEditingController _title;
  late final TextEditingController _amount;
  late final TextEditingController _category;
  late final TextEditingController _description;
  late String _priority;

  @override
  void initState() {
    super.initState();
    final args = widget.draft.arguments;
    _title = TextEditingController(text: '${args['title'] ?? ''}');
    _amount = TextEditingController(text: '${args['amount'] ?? ''}');
    _category = TextEditingController(text: '${args['category'] ?? ''}');
    _description = TextEditingController(text: '${args['description'] ?? ''}');
    _priority = '${args['priority'] ?? 'medium'}';
  }

  @override
  void dispose() {
    _title.dispose();
    _amount.dispose();
    _category.dispose();
    _description.dispose();
    super.dispose();
  }

  void _save() {
    final args = {...widget.draft.arguments};
    if (widget.draft.tool == AssistantTool.createTransaction) {
      final amount = int.tryParse(_amount.text.replaceAll(RegExp(r'\D'), ''));
      if (amount == null || amount <= 0) return;
      args['amount'] = amount;
      args['category'] = _category.text.trim();
      args['description'] = _description.text.trim();
    } else {
      if (_title.text.trim().isEmpty) return;
      args['title'] = _title.text.trim();
      if (widget.draft.tool == AssistantTool.createTask) {
        args['priority'] = _priority;
      }
    }
    Navigator.pop(context, args);
  }

  @override
  Widget build(BuildContext context) {
    final transaction = widget.draft.tool == AssistantTool.createTransaction;
    return AlertDialog(
      title: const Text('Ubah preview'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: transaction
              ? [
                  TextField(
                    key: const ValueKey('assistant-edit-amount'),
                    controller: _amount,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Nominal'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _category,
                    decoration: const InputDecoration(labelText: 'Kategori'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _description,
                    decoration: const InputDecoration(labelText: 'Deskripsi'),
                  ),
                ]
              : [
                  TextField(
                    key: const ValueKey('assistant-edit-title'),
                    controller: _title,
                    decoration: const InputDecoration(labelText: 'Judul'),
                  ),
                  if (widget.draft.tool == AssistantTool.createTask) ...[
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _priority,
                      decoration: const InputDecoration(labelText: 'Prioritas'),
                      items: const [
                        DropdownMenuItem(value: 'low', child: Text('Rendah')),
                        DropdownMenuItem(
                          value: 'medium',
                          child: Text('Sedang'),
                        ),
                        DropdownMenuItem(value: 'high', child: Text('Tinggi')),
                      ],
                      onChanged: (value) => _priority = value!,
                    ),
                  ],
                ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        FilledButton(onPressed: _save, child: const Text('Terapkan')),
      ],
    );
  }
}

String _toolLabel(AssistantTool tool) => switch (tool) {
  AssistantTool.createTransaction => 'Transaksi',
  AssistantTool.createTask => 'Task',
  AssistantTool.createSchedule => 'Jadwal',
  AssistantTool.getFinanceSummary => 'Ringkasan keuangan',
  AssistantTool.getTasks => 'Daftar task',
  AssistantTool.getSchedule => 'Jadwal hari ini',
};

List<(String, String)> _previewRows(AssistantDraft draft) {
  final args = draft.arguments;
  return switch (draft.tool) {
    AssistantTool.createTransaction => [
      ('Jenis', args['type'] == 'income' ? 'Pemasukan' : 'Pengeluaran'),
      ('Nominal', CurrencyFormatter.rupiah(args['amount'] as int)),
      ('Kategori', '${args['category']}'),
      ('Catatan', '${args['description']}'),
    ],
    AssistantTool.createTask => [
      ('Judul', '${args['title']}'),
      ('Prioritas', '${args['priority']}'),
      if (args['dueDate'] != null)
        (
          'Deadline',
          DateFormat(
            'd MMM yyyy • HH:mm',
            'id_ID',
          ).format(DateTime.parse('${args['dueDate']}')),
        ),
    ],
    AssistantTool.createSchedule => [
      ('Judul', '${args['title']}'),
      (
        'Mulai',
        DateFormat(
          'd MMM yyyy • HH:mm',
          'id_ID',
        ).format(DateTime.parse('${args['startAt']}')),
      ),
      (
        'Selesai',
        DateFormat(
          'd MMM yyyy • HH:mm',
          'id_ID',
        ).format(DateTime.parse('${args['endAt']}')),
      ),
    ],
    _ => const [],
  };
}
