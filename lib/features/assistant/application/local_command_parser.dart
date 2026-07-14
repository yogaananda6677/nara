import 'package:nara/features/assistant/domain/entities/assistant_entities.dart';
import 'package:nara/features/finance/domain/entities/finance_transaction.dart';

class LocalCommandParser {
  const LocalCommandParser([this._now]);

  final DateTime Function()? _now;

  ParseOutcome parse(String rawInput) {
    final input = rawInput.trim();
    final normalized = input.toLowerCase();
    if (input.isEmpty) {
      return const ParseOutcome.response('Tulis perintah yang ingin dibantu.');
    }
    if (input.length > 500) {
      return const ParseOutcome.response(
        'Perintah terlalu panjang. Ringkas menjadi maksimal 500 karakter.',
      );
    }
    if (_containsSafetyBypass(normalized)) {
      return const ParseOutcome.response(
        'Nara tidak dapat melewati konfirmasi atau menjalankan perintah tersembunyi.',
        safety: true,
      );
    }

    if (_containsAny(normalized, [
      'ringkasan keuangan',
      'saldo saya',
      'keuangan bulan',
    ])) {
      return ParseOutcome.draft(
        AssistantDraft(
          tool: AssistantTool.getFinanceSummary,
          arguments: const {},
          originalText: input,
        ),
      );
    }
    if (_containsAny(normalized, ['task saya', 'tugas saya', 'daftar task'])) {
      return ParseOutcome.draft(
        AssistantDraft(
          tool: AssistantTool.getTasks,
          arguments: const {},
          originalText: input,
        ),
      );
    }
    if (_containsAny(normalized, [
      'jadwal saya',
      'agenda hari ini',
      'jadwal hari ini',
    ])) {
      return ParseOutcome.draft(
        AssistantDraft(
          tool: AssistantTool.getSchedule,
          arguments: const {},
          originalText: input,
        ),
      );
    }

    if (_containsAny(normalized, [
      'pengeluaran',
      'pemasukan',
      'pendapatan',
      'catat uang',
    ])) {
      return _transaction(input, normalized);
    }
    if (RegExp(r'\b(task|tugas)\b').hasMatch(normalized)) {
      return _task(input, normalized);
    }
    if (_containsAny(normalized, ['jadwal', 'jadwalkan', 'agenda'])) {
      return _schedule(input, normalized);
    }

    if (_containsAny(normalized, ['halo', 'hai', 'hello'])) {
      return const ParseOutcome.response(
        'Halo! Saya siap membantu secara offline. Coba “catat pengeluaran makan 25 ribu”, “buat task laporan besok”, atau “jadwalkan rapat besok jam 9”.',
      );
    }
    return const ParseOutcome.response(
      'Saya belum memahami perintah itu. Saya dapat mencatat transaksi, membuat task atau jadwal, dan menampilkan ringkasan lokal.',
    );
  }

  ParseOutcome _transaction(String original, String normalized) {
    final amount = _parseAmount(normalized);
    if (amount == null || amount <= 0 || amount > 2000000000) {
      return const ParseOutcome.response(
        'Nominal belum jelas. Contoh: “catat pengeluaran makan 25 ribu”.',
      );
    }
    final type = _containsAny(normalized, ['pemasukan', 'pendapatan', 'gaji'])
        ? FinanceTransactionType.income
        : FinanceTransactionType.expense;
    final category = _category(normalized, type);
    var description = normalized
        .replaceAll(
          RegExp(
            r'\b(catat|tambahkan|buat|pengeluaran|pemasukan|pendapatan)\b',
          ),
          ' ',
        )
        .replaceAll(RegExp(r'\b\d+[\d.,]*\s*(ribu|rb|juta|jt|k)?\b'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (description.isEmpty) description = category;
    return ParseOutcome.draft(
      AssistantDraft(
        tool: AssistantTool.createTransaction,
        arguments: {
          'type': type.name,
          'amount': amount,
          'category': category,
          'description': description,
          'date': (_now?.call() ?? DateTime.now()).toIso8601String(),
        },
        originalText: original,
      ),
    );
  }

  ParseOutcome _task(String original, String normalized) {
    var title = normalized
        .replaceFirst(
          RegExp(r'^(tolong\s+)?(buat|tambahkan|tambah)?\s*(task|tugas)\s*'),
          '',
        )
        .replaceAll(
          RegExp(r'\b(hari ini|besok|lusa)(\s+(pagi|siang|sore|malam))?\b'),
          '',
        )
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (title.isEmpty) {
      return const ParseOutcome.response('Judul task belum jelas.');
    }
    final due = _relativeDateTime(normalized, requireTime: false);
    return ParseOutcome.draft(
      AssistantDraft(
        tool: AssistantTool.createTask,
        arguments: {
          'title': title,
          'priority': _priority(normalized),
          if (due != null) 'dueDate': due.toIso8601String(),
        },
        originalText: original,
      ),
    );
  }

  ParseOutcome _schedule(String original, String normalized) {
    final start = _relativeDateTime(normalized, requireTime: true);
    if (start == null) {
      return const ParseOutcome.response(
        'Tanggal atau jam jadwal belum jelas. Contoh: “jadwalkan rapat besok jam 9”.',
      );
    }
    var title = normalized
        .replaceFirst(
          RegExp(
            r'^(tolong\s+)?(buat\s+jadwal|jadwalkan|tambah\s+jadwal|jadwal)\s*',
          ),
          '',
        )
        .replaceAll(
          RegExp(
            r'\b(hari ini|besok|lusa|senin|selasa|rabu|kamis|jumat|sabtu|minggu)\b',
          ),
          '',
        )
        .replaceAll(RegExp(r'\bjam\s*\d{1,2}([.:]\d{2})?\b'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (title.isEmpty) title = 'Agenda';
    return ParseOutcome.draft(
      AssistantDraft(
        tool: AssistantTool.createSchedule,
        arguments: {
          'title': title,
          'startAt': start.toIso8601String(),
          'endAt': start.add(const Duration(hours: 1)).toIso8601String(),
        },
        originalText: original,
      ),
    );
  }

  int? _parseAmount(String input) {
    final match = RegExp(r'(\d+(?:[.,]\d+)?)\s*(juta|jt|ribu|rb|k)?')
        .allMatches(input)
        .where((item) {
          final suffix = item.group(2);
          final raw = item.group(1)!;
          return suffix != null ||
              raw.replaceAll(RegExp(r'\D'), '').length >= 4;
        })
        .firstOrNull;
    if (match == null) return null;
    final source = match.group(1)!;
    final suffix = match.group(2);
    final hasThousandsSeparator =
        suffix == null && RegExp(r'[.,]\d{3}$').hasMatch(source);
    final raw = hasThousandsSeparator
        ? source.replaceAll(RegExp(r'[.,]'), '')
        : source.replaceAll(',', '.');
    final value = double.tryParse(raw);
    if (value == null) return null;
    final multiplier = switch (suffix) {
      'juta' || 'jt' => 1000000,
      'ribu' || 'rb' || 'k' => 1000,
      _ => 1,
    };
    return (value * multiplier).round();
  }

  DateTime? _relativeDateTime(String input, {required bool requireTime}) {
    final now = _now?.call() ?? DateTime.now();
    var day = DateTime(now.year, now.month, now.day);
    var hasDate = false;
    if (input.contains('besok')) {
      day = day.add(const Duration(days: 1));
      hasDate = true;
    } else if (input.contains('lusa')) {
      day = day.add(const Duration(days: 2));
      hasDate = true;
    } else if (input.contains('hari ini')) {
      hasDate = true;
    } else {
      const weekdays = {
        'senin': DateTime.monday,
        'selasa': DateTime.tuesday,
        'rabu': DateTime.wednesday,
        'kamis': DateTime.thursday,
        'jumat': DateTime.friday,
        'sabtu': DateTime.saturday,
        'minggu': DateTime.sunday,
      };
      for (final entry in weekdays.entries) {
        if (input.contains(entry.key)) {
          var difference = (entry.value - now.weekday) % 7;
          if (difference == 0) difference = 7;
          day = day.add(Duration(days: difference));
          hasDate = true;
          break;
        }
      }
    }
    final timeMatch = RegExp(
      r'\bjam\s*(\d{1,2})(?:[.:](\d{2}))?',
    ).firstMatch(input);
    int? hour = timeMatch == null ? null : int.tryParse(timeMatch.group(1)!);
    final minute = timeMatch?.group(2) == null
        ? 0
        : int.parse(timeMatch!.group(2)!);
    hour ??= switch (true) {
      _ when input.contains('pagi') => 9,
      _ when input.contains('siang') => 13,
      _ when input.contains('sore') => 16,
      _ when input.contains('malam') => 19,
      _ => null,
    };
    if (requireTime && (!hasDate || hour == null)) return null;
    if (!hasDate) return null;
    return DateTime(day.year, day.month, day.day, hour ?? 17, minute);
  }

  String _category(String input, FinanceTransactionType type) {
    if (type == FinanceTransactionType.income) {
      if (input.contains('gaji')) return 'Gaji';
      return 'Pemasukan lain';
    }
    if (_containsAny(input, ['makan', 'minum', 'kopi'])) return 'Makanan';
    if (_containsAny(input, ['bensin', 'ojek', 'transport'])) {
      return 'Transportasi';
    }
    if (_containsAny(input, ['belanja', 'shopping'])) return 'Belanja';
    if (_containsAny(input, ['listrik', 'internet', 'tagihan'])) {
      return 'Tagihan';
    }
    return 'Lainnya';
  }

  String _priority(String input) {
    if (_containsAny(input, ['penting', 'prioritas tinggi', 'urgent'])) {
      return 'high';
    }
    if (input.contains('santai')) return 'low';
    return 'medium';
  }

  bool _containsSafetyBypass(String input) => _containsAny(input, [
    'abaikan konfirmasi',
    'tanpa konfirmasi',
    'hapus semua',
    'jalankan diam-diam',
    'system prompt',
  ]);

  bool _containsAny(String input, List<String> values) =>
      values.any(input.contains);
}
