import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nara/features/smart_scan/application/document_classifier.dart';
import 'package:nara/features/smart_scan/application/receipt_parser.dart';
import 'package:nara/features/smart_scan/domain/entities/smart_scan_entities.dart';

void main() {
  const classifier = LocalDocumentClassifier();
  final parser = LocalReceiptParser(() => DateTime(2026, 7, 15));

  test('mengklasifikasi dan mengekstrak fixture struk anonim', () async {
    final text = await File('test/fixtures/receipt_grocery.txt').readAsString();
    final classification = classifier.classify(text);
    final result = parser.parse(text, classification);

    expect(classification.type, ScanDocumentType.receipt);
    expect(result.amount, 43500);
    expect(result.merchant, 'TOKO NARA MART');
    expect(result.date, DateTime(2026, 7, 14));
    expect(result.confidence, greaterThanOrEqualTo(.65));
  });

  test('mengklasifikasi dan mengekstrak fixture bukti transfer', () async {
    final text = await File('test/fixtures/transfer_proof.txt').readAsString();
    final classification = classifier.classify(text);
    final result = parser.parse(text, classification);

    expect(classification.type, ScanDocumentType.transferProof);
    expect(result.amount, 250000);
    expect(result.merchant, 'BUDI SANTOSO');
  });

  test('dokumen non-financial diberi confidence rendah dan warning', () {
    const text = 'Selamat ulang tahun\nSemoga sehat selalu';
    final classification = classifier.classify(text);
    final result = parser.parse(text, classification);

    expect(classification.type, ScanDocumentType.nonFinancial);
    expect(result.confidence, lessThan(.65));
    expect(result.warnings, isNotEmpty);
  });

  test('classifier dan parser memenuhi latency lokal dasar', () async {
    final text = await File('test/fixtures/receipt_grocery.txt').readAsString();
    final stopwatch = Stopwatch()..start();
    for (var index = 0; index < 200; index++) {
      final classification = classifier.classify(text);
      parser.parse(text, classification);
    }
    stopwatch.stop();

    expect(stopwatch.elapsedMilliseconds, lessThan(500));
  });
}
