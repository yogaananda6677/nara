import 'package:nara/features/smart_scan/domain/entities/smart_scan_entities.dart';

class ParsedReceipt {
  const ParsedReceipt({
    required this.amount,
    required this.date,
    required this.merchant,
    required this.category,
    required this.confidence,
    required this.warnings,
  });
  final int? amount;
  final DateTime date;
  final String? merchant;
  final String category;
  final double confidence;
  final List<String> warnings;
}

class LocalReceiptParser {
  const LocalReceiptParser([this._now]);
  final DateTime Function()? _now;

  ParsedReceipt parse(String rawText, DocumentClassification classification) {
    final text = _normalize(rawText);
    final lines = text
        .split('\n')
        .where((line) => line.trim().isNotEmpty)
        .toList();
    final amount = _amount(lines);
    final date = _date(text) ?? (_now?.call() ?? DateTime.now());
    final merchant = _merchant(lines, classification.type);
    final category = _category(text);
    final warnings = <String>[];
    if (classification.type == ScanDocumentType.nonFinancial) {
      warnings.add(
        'Dokumen tidak terdeteksi sebagai struk atau bukti transfer.',
      );
    }
    if (amount == null) {
      warnings.add('Nominal total tidak ditemukan.');
    }
    if (merchant == null) {
      warnings.add('Nama merchant/penerima tidak ditemukan.');
    }
    if (_date(text) == null) {
      warnings.add('Tanggal tidak ditemukan; menggunakan hari ini.');
    }
    var confidence = classification.confidence * .45;
    if (amount != null) confidence += .3;
    if (merchant != null) confidence += .15;
    if (_date(text) != null) confidence += .1;
    return ParsedReceipt(
      amount: amount,
      date: date,
      merchant: merchant,
      category: category,
      confidence: confidence.clamp(0, 1),
      warnings: warnings,
    );
  }

  String _normalize(String value) => value
      .replaceAll('\r', '')
      .replaceAll(RegExp(r'[ \t]+'), ' ')
      .replaceAll(RegExp(r'\n{2,}'), '\n')
      .trim();

  int? _amount(List<String> lines) {
    const priority = [
      'grand total',
      'total bayar',
      'total',
      'jumlah transfer',
      'nominal',
    ];
    for (final keyword in priority) {
      for (final line in lines.reversed) {
        if (!line.toLowerCase().contains(keyword)) continue;
        final values = _moneyValues(line);
        if (values.isNotEmpty) return values.reduce((a, b) => a > b ? a : b);
      }
    }
    final all = lines
        .expand(_moneyValues)
        .where((value) => value >= 100)
        .toList();
    if (all.isEmpty) return null;
    return all.reduce((a, b) => a > b ? a : b);
  }

  Iterable<int> _moneyValues(String line) sync* {
    final matches = RegExp(
      r'(?:rp\.?\s*)?(\d{1,3}(?:[.,]\d{3})+|\d{3,12})(?:[.,]00)?',
      caseSensitive: false,
    ).allMatches(line);
    for (final match in matches) {
      final digits = match.group(1)!.replaceAll(RegExp(r'\D'), '');
      final value = int.tryParse(digits);
      if (value != null && value <= 2000000000) yield value;
    }
  }

  DateTime? _date(String text) {
    final match = RegExp(
      r'\b(\d{1,2})[/-](\d{1,2})[/-](\d{2,4})\b',
    ).firstMatch(text);
    if (match == null) return null;
    final day = int.parse(match.group(1)!);
    final month = int.parse(match.group(2)!);
    var year = int.parse(match.group(3)!);
    if (year < 100) year += 2000;
    if (month > 12 || day > 31) return null;
    return DateTime(year, month, day);
  }

  String? _merchant(List<String> lines, ScanDocumentType type) {
    if (type == ScanDocumentType.transferProof) {
      for (var index = 0; index < lines.length; index++) {
        final line = lines[index];
        if (RegExp(
          r'(penerima|rekening tujuan)',
          caseSensitive: false,
        ).hasMatch(line)) {
          final inline = line.split(':').skip(1).join(':').trim();
          if (inline.length >= 3) return inline;
          if (index + 1 < lines.length) return lines[index + 1].trim();
        }
      }
    }
    for (final line in lines.take(5)) {
      final normalized = line.trim();
      if (normalized.length < 3 || normalized.length > 60) continue;
      if (RegExp(
        r'^(struk|receipt|invoice|tanggal|date|telp|www\.|http|total)',
        caseSensitive: false,
      ).hasMatch(normalized)) {
        continue;
      }
      if (RegExp(r'^\d+[\d .:/-]*$').hasMatch(normalized)) continue;
      return normalized;
    }
    return null;
  }

  String _category(String text) {
    final lower = text.toLowerCase();
    if (RegExp(r'(restaurant|resto|makan|coffee|kopi|cafe)').hasMatch(lower)) {
      return 'Makanan';
    }
    if (RegExp(r'(bensin|pertamina|transport|parkir|tol)').hasMatch(lower)) {
      return 'Transportasi';
    }
    if (RegExp(r'(listrik|internet|tagihan|token)').hasMatch(lower)) {
      return 'Tagihan';
    }
    if (RegExp(r'(apotek|klinik|obat|hospital)').hasMatch(lower)) {
      return 'Kesehatan';
    }
    return 'Belanja';
  }
}
