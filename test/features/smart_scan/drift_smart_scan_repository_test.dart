import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nara/database/app_database.dart';
import 'package:nara/features/smart_scan/data/repositories/drift_smart_scan_repository.dart';
import 'package:nara/features/smart_scan/domain/entities/smart_scan_entities.dart';

void main() {
  test(
    'schema v5 menyimpan metadata scan tanpa OCR text atau image path',
    () async {
      final database = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(database.close);
      final repository = DriftSmartScanRepository(database);
      await repository.saveRecord(
        SmartScanRecord(
          id: 'scan-1',
          source: ScanSource.camera,
          documentType: ScanDocumentType.receipt,
          confidence: .88,
          status: 'pending',
          extractedAmount: 25000,
          merchant: 'Toko Anonim',
          createdAt: DateTime.now(),
        ),
      );

      final row = await database.select(database.smartScans).getSingle();
      expect(database.schemaVersion, 5);
      expect(row.extractedAmount, 25000);
      expect(await repository.getStatus('scan-1'), 'pending');
      await repository.markCancelled('scan-1');
      expect(await repository.getStatus('scan-1'), 'cancelled');
    },
  );
}
