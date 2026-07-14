import 'package:nara/features/smart_scan/domain/entities/smart_scan_entities.dart';

class LocalDocumentClassifier {
  const LocalDocumentClassifier();

  DocumentClassification classify(String rawText) {
    final text = rawText.toLowerCase();
    final receiptScore = _score(text, const {
      'total': 2,
      'subtotal': 2,
      'tunai': 1,
      'cash': 1,
      'kembali': 1,
      'qty': 1,
      'kasir': 1,
      'receipt': 2,
      'struk': 2,
      'ppn': 1,
    });
    final transferScore = _score(text, const {
      'transfer berhasil': 4,
      'bukti transfer': 4,
      'nomor referensi': 2,
      'no. referensi': 2,
      'rekening tujuan': 2,
      'penerima': 1,
      'pengirim': 1,
      'biaya admin': 1,
      'transaction id': 2,
    });
    if (receiptScore == 0 && transferScore == 0) {
      return const DocumentClassification(
        type: ScanDocumentType.nonFinancial,
        confidence: .35,
      );
    }
    final transfer = transferScore > receiptScore;
    final best = transfer ? transferScore : receiptScore;
    final other = transfer ? receiptScore : transferScore;
    final confidence = (.55 + (best - other) * .06 + best * .025).clamp(
      .45,
      .96,
    );
    return DocumentClassification(
      type: transfer
          ? ScanDocumentType.transferProof
          : ScanDocumentType.receipt,
      confidence: confidence,
    );
  }

  int _score(String text, Map<String, int> keywords) => keywords.entries.fold(
    0,
    (total, item) => total + (text.contains(item.key) ? item.value : 0),
  );
}
