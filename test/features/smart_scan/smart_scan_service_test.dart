import 'package:flutter_test/flutter_test.dart';
import 'package:nara/core/result/result.dart';
import 'package:nara/features/finance/application/finance_service.dart';
import 'package:nara/features/finance/domain/entities/finance_account.dart';
import 'package:nara/features/finance/domain/entities/finance_category.dart';
import 'package:nara/features/finance/domain/entities/finance_snapshot.dart';
import 'package:nara/features/finance/domain/entities/finance_transaction.dart';
import 'package:nara/features/smart_scan/application/document_classifier.dart';
import 'package:nara/features/smart_scan/application/receipt_parser.dart';
import 'package:nara/features/smart_scan/application/smart_scan_service.dart';
import 'package:nara/features/smart_scan/domain/entities/smart_scan_entities.dart';

import '../../helpers/fake_finance_repository.dart';
import '../../helpers/fake_smart_scan.dart';

void main() {
  const receipt = '''
TOKO MAJU
14/07/2026
TOTAL BAYAR Rp 25.000
TUNAI Rp 30.000
''';

  test('processing hanya membuat draft dan metadata pending', () async {
    final scans = FakeSmartScanRepository();
    final finance = _financeRepository();
    final service = _service(scans, finance, receipt);

    final result = await service.processImage(
      imagePath: '/tmp/receipt.jpg',
      source: ScanSource.gallery,
    );

    expect(result, isA<Success<SmartScanDraft>>());
    expect(scans.records.values.single.status, 'pending');
    expect(
      (await finance.loadSnapshot(month: DateTime.now())).transactions,
      isEmpty,
    );
  });

  test(
    'konfirmasi menyimpan transaksi sekali dengan source smart_scan',
    () async {
      final scans = FakeSmartScanRepository();
      final finance = _financeRepository();
      final service = _service(scans, finance, receipt);
      final processed = await service.processImage(
        imagePath: '/tmp/receipt.jpg',
        source: ScanSource.camera,
      );
      final draft = (processed as Success<SmartScanDraft>).value;

      final first = await service.confirm(
        SmartScanConfirmInput(
          scanId: draft.id,
          accountId: 'cash',
          categoryId: 'food',
          type: FinanceTransactionType.expense,
          amount: draft.amount!,
          date: draft.date,
          merchant: draft.merchant,
        ),
      );
      final second = await service.confirm(
        SmartScanConfirmInput(
          scanId: draft.id,
          accountId: 'cash',
          categoryId: 'food',
          type: FinanceTransactionType.expense,
          amount: draft.amount!,
          date: draft.date,
        ),
      );

      final transactions = (await finance.loadSnapshot(
        month: draft.date,
      )).transactions;
      expect(first, isA<Success<void>>());
      expect(second, isA<Failure<void>>());
      expect(transactions, hasLength(1));
      expect(transactions.single.source, 'smart_scan');
      expect(transactions.single.scanId, draft.id);
      expect(scans.records[draft.id]?.status, 'confirmed');
    },
  );

  test('OCR kosong menghasilkan failure tanpa transaksi', () async {
    final scans = FakeSmartScanRepository();
    final finance = _financeRepository();
    final service = _service(scans, finance, '   ');

    final result = await service.processImage(
      imagePath: '/tmp/blank.jpg',
      source: ScanSource.gallery,
    );

    expect(result, isA<Failure<SmartScanDraft>>());
    expect(scans.records.values.single.status, 'failed');
  });
}

SmartScanService _service(
  FakeSmartScanRepository scans,
  FakeFinanceRepository finance,
  String ocr,
) => SmartScanService(
  scans,
  FakeScanPreprocessor(),
  FakeScanOcrEngine(ocr),
  const LocalDocumentClassifier(),
  const LocalReceiptParser(),
  FinanceService(finance),
);

FakeFinanceRepository _financeRepository() {
  final now = DateTime.now();
  return FakeFinanceRepository(
    snapshot: FinanceSnapshot(
      accounts: [
        AccountBalance(
          account: FinanceAccount(
            id: 'cash',
            name: 'Tunai',
            type: FinanceAccountType.cash,
            openingBalance: 0,
            currency: 'IDR',
            isArchived: false,
            createdAt: now,
            updatedAt: now,
          ),
          balance: 0,
        ),
      ],
      categories: const [
        FinanceCategory(
          id: 'food',
          name: 'Makanan',
          type: FinanceCategoryType.expense,
          icon: null,
          colorValue: null,
          isSystem: true,
        ),
      ],
      transactions: const [],
      savingGoals: const [],
      summary: const FinanceSummary(
        totalBalance: 0,
        monthlyIncome: 0,
        monthlyExpense: 0,
      ),
    ),
  );
}
