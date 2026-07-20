import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nara/features/finance/domain/entities/finance_transaction.dart';
import 'package:nara/features/smart_scan/application/document_classifier.dart';
import 'package:nara/features/smart_scan/application/receipt_parser.dart';
import 'package:nara/features/smart_scan/application/scan_gateways.dart';
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

  test(
    'layout struk memilih nominal total di kanan label, bukan tunai terbesar',
    () {
      const classification = DocumentClassification(
        type: ScanDocumentType.receipt,
        confidence: .9,
      );
      final result = parser.parseOcr(
        OcrTextResult(
          hasLayout: true,
          text: [
            'TOKO NARA MART',
            'Subtotal Rp 40.000',
            'PPN Rp 3.500',
            'TOTAL BAYAR Rp 43.500',
            'Tunai Rp 50.000',
            'Kembali Rp 6.500',
          ].join('\n'),
          lines: [
            _line('TOKO NARA MART', 0, 0),
            _line('Subtotal Rp 40.000', 0, 80),
            _line('PPN Rp 3.500', 0, 110),
            _line('TOTAL BAYAR Rp 43.500', 0, 150),
            _line('Tunai Rp 50.000', 0, 180),
            _line('Kembali Rp 6.500', 0, 210),
          ],
        ),
        classification,
      );

      expect(result.amount, 43500);
      expect(result.confidence, greaterThanOrEqualTo(.78));
    },
  );

  test('layout struk membaca nominal pada baris setelah label total', () {
    const classification = DocumentClassification(
      type: ScanDocumentType.receipt,
      confidence: .9,
    );
    final result = parser.parseOcr(
      OcrTextResult(
        hasLayout: true,
        text: 'CAFE NARA\nGRAND TOTAL\nRp 125.000\nTunai Rp 150.000',
        lines: [
          _line('CAFE NARA', 0, 0),
          _line('GRAND TOTAL', 0, 120),
          _line('Rp 125.000', 220, 145),
          _line('Tunai Rp 150.000', 0, 180),
        ],
      ),
      classification,
    );

    expect(result.amount, 125000);
  });

  test('layout struk menyatukan nominal OCR pecah seperti 1, 905', () {
    const classification = DocumentClassification(
      type: ScanDocumentType.receipt,
      confidence: .9,
    );
    final result = parser.parseOcr(
      OcrTextResult(
        hasLayout: true,
        text: 'WARUNG NARA\nTOTAL Rp 1, 905',
        lines: [_line('WARUNG NARA', 0, 0), _line('TOTAL Rp 1, 905', 0, 80)],
      ),
      classification,
    );

    expect(result.amount, 1905);
  });

  test(
    'layout struk tidak memilih tail ribuan 905 saat elemen nominal pecah',
    () {
      const classification = DocumentClassification(
        type: ScanDocumentType.receipt,
        confidence: .9,
      );
      final result = parser.parseOcr(
        OcrTextResult(
          hasLayout: true,
          text: 'WARUNG NARA\nTOTAL Rp 1, 905',
          lines: [
            _line('WARUNG NARA', 0, 0),
            OcrTextLine(
              text: 'TOTAL Rp 1, 905',
              left: 0,
              top: 80,
              right: 130,
              bottom: 98,
              elements: const [
                OcrTextElement(
                  text: 'TOTAL',
                  left: 0,
                  top: 80,
                  right: 40,
                  bottom: 98,
                ),
                OcrTextElement(
                  text: 'Rp',
                  left: 50,
                  top: 80,
                  right: 66,
                  bottom: 98,
                ),
                OcrTextElement(
                  text: '1,',
                  left: 74,
                  top: 80,
                  right: 88,
                  bottom: 98,
                ),
                OcrTextElement(
                  text: '905',
                  left: 94,
                  top: 80,
                  right: 122,
                  bottom: 98,
                ),
              ],
            ),
          ],
        ),
        classification,
      );

      expect(result.amount, 1905);
    },
  );

  test('layout struk refund menyarankan transaksi pemasukan', () {
    const classification = DocumentClassification(
      type: ScanDocumentType.receipt,
      confidence: .86,
    );
    final result = parser.parseOcr(
      OcrTextResult(
        hasLayout: true,
        text: 'TOKO NARA\nREFUND DITERIMA Rp 25.000',
        lines: [
          _line('TOKO NARA', 0, 0),
          _line('REFUND DITERIMA Rp 25.000', 0, 80),
        ],
      ),
      classification,
    );

    expect(result.amount, 25000);
    expect(result.suggestedTransactionType, FinanceTransactionType.income);
  });

  test('layout BRImo mengambil total dan nama tujuan, bukan referensi', () {
    final text = [
      'BRImo',
      'Transaksi Berhasil',
      'Tanggal 2021-01-16 08:34:48 WIB',
      'Nomor Referensi 216585189836',
      'Sumber Dana CEPTARINA PELAWI 3274 **** **** 537',
      'Jenis Transaksi Transfer Bank BRI',
      'Bank Tujuan BANK BRI',
      'Nomor Tujuan 530601034438533',
      'Nama Tujuan CEPTARINA PELAWI',
      'Nominal Rp5.000.000',
      'Biaya Admin Rp0',
      'Total Rp5.000.000',
    ];
    final classification = classifier.classify(text.join('\n'));
    final result = parser.parseOcr(
      OcrTextResult(
        hasLayout: true,
        text: text.join('\n'),
        lines: [
          for (var index = 0; index < text.length; index++)
            _line(text[index], 0, index * 30),
        ],
      ),
      classification,
    );

    expect(classification.type, ScanDocumentType.transferProof);
    expect(result.amount, 5000000);
    expect(result.merchant, 'CEPTARINA PELAWI');
  });

  test(
    'layout m-transfer popup mengambil nominal dan penerima setelah baris Ke',
    () {
      final text = [
        'm-Transfer :',
        'BERHASIL',
        '09/09 19:14:09',
        'Ke 7120502411',
        'CICIH SUMARSIH',
        'Rp. 1,000,000.00',
      ];
      final classification = classifier.classify(text.join('\n'));
      final result = parser.parseOcr(
        OcrTextResult(
          hasLayout: true,
          text: text.join('\n'),
          lines: [
            for (var index = 0; index < text.length; index++)
              _line(text[index], 0, index * 28),
          ],
        ),
        classification,
      );

      expect(classification.type, ScanDocumentType.transferProof);
      expect(result.amount, 1000000);
      expect(result.merchant, 'CICIH SUMARSIH');
    },
  );

  test('layout PLN memilih RP BAYAR dibanding total tagihan dan token', () {
    const classification = DocumentClassification(
      type: ScanDocumentType.receipt,
      confidence: .9,
    );
    final result = parser.parseOcr(
      OcrTextResult(
        hasLayout: true,
        text: [
          'STRUK PEMBELIAN LISTRIK PRABAYAR',
          'NO METER : 32102040683',
          'TOTAL RP TAGIHAN : IDR 91.743,00',
          'PPJ : IDR 8.257,00',
          'RP BAYAR : IDR 102.500',
          'STROOM/TOKEN : 7125 7545 9193 4207 3619',
        ].join('\n'),
        lines: [
          _line('STRUK PEMBELIAN LISTRIK PRABAYAR', 0, 0),
          _line('NO METER : 32102040683', 0, 60),
          _line('TOTAL RP TAGIHAN : IDR 91.743,00', 0, 120),
          _line('PPJ : IDR 8.257,00', 0, 150),
          _line('RP BAYAR : IDR 102.500', 0, 190),
          _line('STROOM/TOKEN : 7125 7545 9193 4207 3619', 0, 230),
        ],
      ),
      classification,
    );

    expect(result.amount, 102500);
    expect(result.category, 'Tagihan');
  });

  test('layout Alfamart memilih Total Item, bukan tunai atau kembalian', () {
    const classification = DocumentClassification(
      type: ScanDocumentType.receipt,
      confidence: .9,
    );
    final result = parser.parseOcr(
      OcrTextResult(
        hasLayout: true,
        text: [
          'ALFAMART RAYA TUGUREJO KEDIRI',
          'ABC CHO 180ML 1 4.500 4.500',
          'KP BRANDING (S) 1 200 200',
          'KP BRANDING (S) -1 200 -200',
          'Total Item 1 4.500',
          'Tunai 20.000',
          'Kembalian 15.500',
          'PPN 445',
        ].join('\n'),
        lines: [
          _line('ALFAMART RAYA TUGUREJO KEDIRI', 0, 0),
          _line('ABC CHO 180ML 1 4.500 4.500', 0, 80),
          _line('KP BRANDING (S) 1 200 200', 0, 110),
          _line('KP BRANDING (S) -1 200 -200', 0, 140),
          _line('Total Item 1 4.500', 0, 190),
          _line('Tunai 20.000', 0, 220),
          _line('Kembalian 15.500', 0, 250),
          _line('PPN 445', 0, 280),
        ],
      ),
      classification,
    );

    expect(result.amount, 4500);
  });

  test('layout kasir subtotal menjadi fallback saat total belum terlihat', () {
    const classification = DocumentClassification(
      type: ScanDocumentType.receipt,
      confidence: .88,
    );
    final result = parser.parseOcr(
      OcrTextResult(
        hasLayout: true,
        text: [
          'BESALI CAFE',
          '1 Mie Goreng Jawa 30,000',
          '1 Nasi Goreng Besali 35,000',
          '7 Ice Tea 175,000',
          'SUBTOTAL 277,000',
        ].join('\n'),
        lines: [
          _line('BESALI CAFE', 0, 0),
          _line('1 Mie Goreng Jawa 30,000', 0, 80),
          _line('1 Nasi Goreng Besali 35,000', 0, 110),
          _line('7 Ice Tea 175,000', 0, 140),
          _line('SUBTOTAL 277,000', 0, 200),
        ],
      ),
      classification,
    );

    expect(result.amount, 277000);
    expect(result.category, 'Makanan');
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

OcrTextLine _line(String text, double left, double top) {
  final words = text.split(' ');
  var cursor = left;
  final elements = <OcrTextElement>[];
  for (final word in words) {
    final width = word.length * 8.0;
    elements.add(
      OcrTextElement(
        text: word,
        left: cursor,
        top: top,
        right: cursor + width,
        bottom: top + 18,
      ),
    );
    cursor += width + 8;
  }
  return OcrTextLine(
    text: text,
    left: left,
    top: top,
    right: cursor,
    bottom: top + 18,
    elements: elements,
  );
}
