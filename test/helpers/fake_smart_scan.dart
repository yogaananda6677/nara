import 'package:nara/features/smart_scan/application/scan_gateways.dart';
import 'package:nara/features/smart_scan/domain/entities/smart_scan_entities.dart';
import 'package:nara/features/smart_scan/domain/repositories/smart_scan_repository.dart';

class FakeSmartScanRepository implements SmartScanRepository {
  final records = <String, SmartScanRecord>{};

  @override
  Future<void> saveRecord(SmartScanRecord record) async {
    records[record.id] = record;
  }

  @override
  Future<String?> getStatus(String id) async => records[id]?.status;

  @override
  Future<void> markCancelled(String id) async => _status(id, 'cancelled');

  @override
  Future<void> markConfirmed(String id) async => _status(id, 'confirmed');

  void _status(String id, String status) {
    final item = records[id]!;
    records[id] = SmartScanRecord(
      id: item.id,
      source: item.source,
      documentType: item.documentType,
      confidence: item.confidence,
      status: status,
      extractedAmount: item.extractedAmount,
      merchant: item.merchant,
      createdAt: item.createdAt,
      confirmedAt: status == 'confirmed' ? DateTime.now() : null,
    );
  }
}

class FakeScanImagePicker implements ScanImagePicker {
  FakeScanImagePicker({this.path});
  final String? path;

  @override
  Future<String?> pick(ScanSource source) async => path;

  @override
  Future<String?> retrieveLostImage() async => null;
}

class FakeScanPreprocessor implements ScanImagePreprocessor {
  @override
  Future<ProcessedScanImage> process(String sourcePath) async =>
      ProcessedScanImage(path: sourcePath, isTemporary: false);
}

class FakeScanOcrEngine implements ScanOcrEngine {
  FakeScanOcrEngine(this.text);
  final String text;

  @override
  Future<OcrTextResult> recognize(String imagePath) async =>
      OcrTextResult.fromText(text);
}
