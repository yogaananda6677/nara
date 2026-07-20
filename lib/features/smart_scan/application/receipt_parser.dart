import 'package:nara/features/finance/domain/entities/finance_transaction.dart';
import 'package:nara/features/smart_scan/application/scan_gateways.dart';
import 'package:nara/features/smart_scan/domain/entities/smart_scan_entities.dart';

class ParsedReceipt {
  const ParsedReceipt({
    required this.amount,
    required this.date,
    required this.merchant,
    required this.category,
    required this.suggestedTransactionType,
    required this.confidence,
    required this.warnings,
  });
  final int? amount;
  final DateTime date;
  final String? merchant;
  final String category;
  final FinanceTransactionType suggestedTransactionType;
  final double confidence;
  final List<String> warnings;
}

class LocalReceiptParser {
  const LocalReceiptParser([this._now]);
  final DateTime Function()? _now;

  ParsedReceipt parse(String rawText, DocumentClassification classification) {
    return parseOcr(OcrTextResult.fromText(rawText), classification);
  }

  ParsedReceipt parseOcr(
    OcrTextResult ocr,
    DocumentClassification classification,
  ) {
    final text = _normalize(ocr.text);
    final lines = text
        .split('\n')
        .where((line) => line.trim().isNotEmpty)
        .toList();
    final amount = _amount(ocr, lines, classification.type);
    final date = _date(text) ?? (_now?.call() ?? DateTime.now());
    final merchant = _merchant(lines, classification.type);
    final category = _category(text);
    final suggestedTransactionType = _transactionType(text);
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
    if (!ocr.hasLayout && classification.type == ScanDocumentType.receipt) {
      warnings.add(
        'Posisi teks tidak tersedia; nominal dipilih dari urutan teks OCR.',
      );
    }
    var confidence = classification.confidence * .45;
    if (amount != null) confidence += .3;
    if (merchant != null) confidence += .15;
    if (_date(text) != null) confidence += .1;
    if (ocr.hasLayout && amount != null) confidence += .08;
    return ParsedReceipt(
      amount: amount,
      date: date,
      merchant: merchant,
      category: category,
      suggestedTransactionType: suggestedTransactionType,
      confidence: confidence.clamp(0, 1),
      warnings: warnings,
    );
  }

  String _normalize(String value) => value
      .replaceAll('\r', '')
      .replaceAll(RegExp(r'[|]'), ' ')
      .replaceAll(RegExp(r'[ \t]+'), ' ')
      .replaceAll(RegExp(r'\n{2,}'), '\n')
      .trim();

  int? _amount(
    OcrTextResult ocr,
    List<String> lines,
    ScanDocumentType documentType,
  ) {
    if (ocr.hasLayout && ocr.lines.isNotEmpty) {
      final layoutAmount = _layoutAmount(ocr.lines, documentType);
      if (layoutAmount != null) return layoutAmount;
    }

    const priority = [
      'grand total',
      'total bayar',
      'total pembayaran',
      'total item',
      'rp bayar',
      'jumlah transfer',
      'nominal transfer',
      'total',
      'harga jual',
      'nominal',
      'subtotal',
    ];
    for (final keyword in priority) {
      for (final line in lines.reversed) {
        if (!line.toLowerCase().contains(keyword)) continue;
        if (_isNoiseAmountLine(line.toLowerCase())) continue;
        final values = _moneyValues(line);
        if (values.isNotEmpty) return values.reduce((a, b) => a > b ? a : b);
      }
    }
    final all = lines
        .where((line) => !_isNoiseAmountLine(line.toLowerCase()))
        .expand(_moneyValues)
        .where((value) => value >= 100)
        .toList();
    if (all.isEmpty) return null;
    return all.reduce((a, b) => a > b ? a : b);
  }

  int? _layoutAmount(List<OcrTextLine> sourceLines, ScanDocumentType type) {
    final lines =
        sourceLines.where((line) => line.text.trim().isNotEmpty).toList()
          ..sort((a, b) {
            final top = a.top.compareTo(b.top);
            if (top != 0) return top;
            return a.left.compareTo(b.left);
          });
    if (lines.isEmpty) return null;

    final minTop = lines
        .map((line) => line.top)
        .reduce((a, b) => a < b ? a : b);
    final maxBottom = lines
        .map((line) => line.bottom)
        .reduce((a, b) => a > b ? a : b);
    final height = (maxBottom - minTop).clamp(1, double.infinity);
    final candidates = <_AmountCandidate>[];

    for (var index = 0; index < lines.length; index++) {
      final line = lines[index];
      final lower = line.text.toLowerCase();
      if (_isNoiseAmountLine(lower)) continue;
      final linePosition = ((line.centerY - minTop) / height).clamp(0.0, 1.0);
      final lineAmounts = _amountCandidatesInLine(line);
      for (final amount in lineAmounts) {
        var score = _lineScore(lower, type);
        score += linePosition * 18;
        if (amount.value >= 1000) score += 4;
        if (amount.centerX > _labelCenterX(line, lower)) score += 12;
        if (_hasCurrencyMarker(line.text)) {
          score += 5;
        }
        candidates.add(amount.copyWith(score: score));
      }

      if (lineAmounts.isEmpty && _hasStrongTotalLabel(lower, type)) {
        for (
          var offset = 1;
          offset <= 2 && index + offset < lines.length;
          offset++
        ) {
          for (final amount in _amountCandidatesInLine(lines[index + offset])) {
            candidates.add(
              amount.copyWith(score: 82 - (offset * 8) + linePosition * 12),
            );
          }
        }
      }
    }

    final filtered =
        candidates
            .where((candidate) => candidate.value >= 100)
            .where((candidate) => candidate.score > 0)
            .toList()
          ..sort((a, b) {
            final score = b.score.compareTo(a.score);
            if (score != 0) return score;
            return b.value.compareTo(a.value);
          });
    return filtered.firstOrNull?.value;
  }

  List<_AmountCandidate> _amountCandidatesInLine(OcrTextLine line) {
    final values = <_AmountCandidate>[];
    final text = line.text;
    for (final match in _moneyPattern.allMatches(text)) {
      final value = _moneyValue(match.group(1)!);
      if (value == null) continue;
      final element = _matchingElement(line, match);
      final centerX = element?.centerX ?? _estimatedCenterX(line, match);
      values.add(_AmountCandidate(value: value, centerX: centerX));
    }
    if (line.elements.isNotEmpty) {
      values.addAll(_mergedElementAmountCandidates(line));
      for (var index = 0; index < line.elements.length; index++) {
        final element = line.elements[index];
        for (final match in _moneyPattern.allMatches(element.text)) {
          final value = _moneyValue(match.group(1)!);
          if (value == null) continue;
          if (_looksLikeSeparatedThousandsTail(line.elements, index)) continue;
          values.add(_AmountCandidate(value: value, centerX: element.centerX));
        }
      }
    }
    final seen = <String>{};
    return values.where((candidate) {
      final key = '${candidate.value}:${candidate.centerX.round()}';
      return seen.add(key);
    }).toList();
  }

  List<_AmountCandidate> _mergedElementAmountCandidates(OcrTextLine line) {
    final elements = line.elements;
    final values = <_AmountCandidate>[];
    for (var start = 0; start < elements.length; start++) {
      final buffer = StringBuffer();
      for (var end = start; end < elements.length && end < start + 4; end++) {
        if (buffer.isNotEmpty) buffer.write(' ');
        buffer.write(elements[end].text);
        final merged = buffer.toString();
        for (final match in _moneyPattern.allMatches(merged)) {
          if (match.start != 0 || match.end != merged.length) continue;
          final value = _moneyValue(match.group(1)!);
          if (value == null) continue;
          values.add(
            _AmountCandidate(
              value: value,
              centerX: (elements[start].left + elements[end].right) / 2,
            ),
          );
        }
      }
    }
    return values;
  }

  bool _looksLikeSeparatedThousandsTail(
    List<OcrTextElement> elements,
    int index,
  ) {
    final current = elements[index].text.trim();
    if (!RegExp(r'^\d{3}$').hasMatch(current) || index == 0) return false;
    final previous = elements[index - 1].text.trim();
    return RegExp(r'^\d{1,3}[,.]?$').hasMatch(previous);
  }

  Iterable<int> _moneyValues(String line) sync* {
    final matches = _moneyPattern.allMatches(line);
    for (final match in matches) {
      final value = _moneyValue(match.group(1)!);
      if (value != null && value <= 2000000000) yield value;
    }
  }

  static final _moneyPattern = RegExp(
    r'(?:rp\.?|idr|rp:|idr:)?\s*(?:\.?\s*)?(\d{1,3}(?:(?:[.,]\s*|\s)\d{3})+|\d{4,12})(?:[.,]00)?',
    caseSensitive: false,
  );

  int? _moneyValue(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    final parsed = int.tryParse(digits);
    if (parsed == null || parsed > 2000000000) return null;
    return parsed;
  }

  OcrTextElement? _matchingElement(OcrTextLine line, RegExpMatch match) {
    if (line.elements.isEmpty) return null;
    final matched = match
        .group(0)!
        .replaceAll(RegExp(r'\s+'), '')
        .toLowerCase();
    for (final element in line.elements) {
      final normalized = element.text
          .replaceAll(RegExp(r'\s+'), '')
          .toLowerCase();
      if (matched.contains(normalized) || normalized.contains(matched)) {
        return element;
      }
    }
    return null;
  }

  double _estimatedCenterX(OcrTextLine line, RegExpMatch match) {
    final width = (line.right - line.left).clamp(1, double.infinity);
    final startRatio = match.start / line.text.length.clamp(1, 10000);
    final endRatio = match.end / line.text.length.clamp(1, 10000);
    return line.left + width * ((startRatio + endRatio) / 2);
  }

  double _labelCenterX(OcrTextLine line, String lower) {
    final labelMatch = RegExp(
      r'(grand total|total bayar|total pembayaran|rp bayar|total|jumlah transfer|nominal transfer|nominal|amount|harga jual|diterima|refund)',
      caseSensitive: false,
    ).firstMatch(lower);
    if (labelMatch == null) return line.left;
    final width = (line.right - line.left).clamp(1, double.infinity);
    final centerRatio =
        ((labelMatch.start + labelMatch.end) / 2) /
        lower.length.clamp(1, 10000);
    return line.left + width * centerRatio;
  }

  double _lineScore(String lower, ScanDocumentType type) {
    var score = 0.0;
    if (_hasStrongTotalLabel(lower, type)) score += 90;
    if (RegExp(r'\b(total|amount|nominal|jumlah|bayar)\b').hasMatch(lower)) {
      score += 38;
    }
    if (RegExp(
      r'(diterima|transfer masuk|refund|pengembalian|cashback|setoran)',
    ).hasMatch(lower)) {
      score += 32;
    }
    if (RegExp(
      r'(diskon|discount|voucher|promo|ppn|pajak|tax|biaya admin|admin fee)',
    ).hasMatch(lower)) {
      score -= 48;
    }
    if (RegExp(r'(subtotal|sub total|harga jual)').hasMatch(lower)) {
      score += 12;
    }
    if (RegExp(
      r'(kembali|change|tunai|cash|bayar tunai|uang bayar|cash payment)',
    ).hasMatch(lower)) {
      score -= 62;
    }
    if (RegExp(
      r'(saldo|balance|rekening|nomor referensi|no\.?\s*ref|no\.?|telp|phone|qty|item|meter|token|idpel|id pelanggan)',
    ).hasMatch(lower)) {
      score -= 24;
    }
    return score;
  }

  bool _hasStrongTotalLabel(String lower, ScanDocumentType type) {
    final receipt = RegExp(
      r'(grand total|total bayar|total pembayaran|total item|total belanja|total payment|total amount|amount due|jumlah bayar|rp bayar|harga jual)',
    ).hasMatch(lower);
    final transfer = RegExp(
      r'(jumlah transfer|nominal transfer|nominal|amount|total transfer|total)',
    ).hasMatch(lower);
    return type == ScanDocumentType.transferProof
        ? transfer || receipt
        : receipt;
  }

  bool _hasCurrencyMarker(String text) =>
      RegExp(r'\b(rp|idr)\b|rp\.?|rp:', caseSensitive: false).hasMatch(text);

  bool _isNoiseAmountLine(String lower) {
    if (RegExp(
      r'(nomor referensi|no\.?\s*ref|transaction id|id transaksi|nomor meter|no meter|idpel|id pelanggan|rekening|nomor tujuan|sumber dana|kartu|card|telp|phone|npwp)',
    ).hasMatch(lower)) {
      return true;
    }
    if (RegExp(r'^\s*(\d[\d\s./:-]{6,})\s*$').hasMatch(lower)) return true;
    return false;
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
          r'(nama tujuan|penerima|rekening tujuan|ke rekening|kepada)',
          caseSensitive: false,
        ).hasMatch(line)) {
          final inline = _valueAfterLabel(
            line,
            r'(nama tujuan|penerima|rekening tujuan|ke rekening|kepada)',
          );
          final inlineName = _cleanTransferName(inline);
          if (inlineName != null) return inlineName;
          if (index + 1 < lines.length) {
            final nextName = _cleanTransferName(lines[index + 1]);
            if (nextName != null) return nextName;
          }
        }
        if (RegExp(r'^ke\s+\d{5,}', caseSensitive: false).hasMatch(line)) {
          for (
            var next = index + 1;
            next < lines.length && next <= index + 2;
            next++
          ) {
            final nextName = _cleanTransferName(lines[next]);
            if (nextName != null) return nextName;
          }
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

  String _valueAfterLabel(String line, String labelPattern) {
    final colonValue = line.split(':').skip(1).join(':').trim();
    if (colonValue.isNotEmpty) return colonValue;
    return line
        .replaceFirst(RegExp(labelPattern, caseSensitive: false), '')
        .trim();
  }

  String? _cleanTransferName(String value) {
    var text = value.trim();
    if (text.isEmpty) return null;
    text = text.replaceAll(RegExp(r'\*+'), '').trim();
    text = text.replaceAll(RegExp(r'^\d+'), '').trim();
    text = text
        .replaceAll(
          RegExp(r'^(bank|bri|bca|mandiri|bni)\b', caseSensitive: false),
          '',
        )
        .trim();
    if (text.length < 3 || text.length > 60) return null;
    if (RegExp(
      r'(transfer|berhasil|nominal|tanggal|referensi|rekening|tujuan|sumber dana|bank tujuan|biaya admin|rp\.?\s*\d)',
      caseSensitive: false,
    ).hasMatch(text)) {
      return null;
    }
    if (RegExp(r'^[\d\s./:-]+$').hasMatch(text)) return null;
    return text;
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

  FinanceTransactionType _transactionType(String text) {
    final lower = text.toLowerCase();
    if (RegExp(
      r'(transfer masuk|uang masuk|pemasukan|diterima|refund|pengembalian dana|cashback|setoran)',
    ).hasMatch(lower)) {
      return FinanceTransactionType.income;
    }
    return FinanceTransactionType.expense;
  }
}

class _AmountCandidate {
  const _AmountCandidate({
    required this.value,
    required this.centerX,
    this.score = 0,
  });

  final int value;
  final double centerX;
  final double score;

  _AmountCandidate copyWith({double? score}) => _AmountCandidate(
    value: value,
    centerX: centerX,
    score: score ?? this.score,
  );
}
