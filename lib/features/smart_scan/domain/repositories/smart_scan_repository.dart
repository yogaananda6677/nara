import 'package:nara/features/smart_scan/domain/entities/smart_scan_entities.dart';

abstract interface class SmartScanRepository {
  Future<void> saveRecord(SmartScanRecord record);
  Future<void> markConfirmed(String id);
  Future<void> markCancelled(String id);
  Future<String?> getStatus(String id);
}
