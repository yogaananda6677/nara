import 'package:nara/features/finance/domain/entities/finance_transaction.dart';

enum ScanSource {
  camera,
  gallery;

  String get label => this == camera ? 'Kamera' : 'Galeri';
}

enum ScanDocumentType {
  receipt,
  transferProof,
  nonFinancial;

  String get label => switch (this) {
    receipt => 'Struk',
    transferProof => 'Bukti transfer',
    nonFinancial => 'Bukan dokumen keuangan',
  };
}

class DocumentClassification {
  const DocumentClassification({required this.type, required this.confidence});
  final ScanDocumentType type;
  final double confidence;
}

class SmartScanDraft {
  const SmartScanDraft({
    required this.id,
    required this.source,
    required this.imagePath,
    required this.documentType,
    required this.confidence,
    required this.rawText,
    required this.amount,
    required this.date,
    required this.suggestedTransactionType,
    required this.categorySuggestion,
    required this.warnings,
    this.merchant,
  });

  final String id;
  final ScanSource source;
  final String imagePath;
  final ScanDocumentType documentType;
  final double confidence;
  final String rawText;
  final int? amount;
  final DateTime date;
  final FinanceTransactionType suggestedTransactionType;
  final String? merchant;
  final String categorySuggestion;
  final List<String> warnings;

  bool get canConfirm =>
      documentType != ScanDocumentType.nonFinancial &&
      amount != null &&
      amount! > 0;
  bool get isLowConfidence => confidence < .65;
}

class SmartScanRecord {
  const SmartScanRecord({
    required this.id,
    required this.source,
    required this.documentType,
    required this.confidence,
    required this.status,
    required this.createdAt,
    this.extractedAmount,
    this.merchant,
    this.confirmedAt,
  });

  final String id;
  final ScanSource source;
  final ScanDocumentType documentType;
  final double confidence;
  final String status;
  final int? extractedAmount;
  final String? merchant;
  final DateTime createdAt;
  final DateTime? confirmedAt;
}
