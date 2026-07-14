import 'package:drift/drift.dart';
import 'package:nara/database/app_database.dart' as db;
import 'package:nara/features/smart_scan/domain/entities/smart_scan_entities.dart';
import 'package:nara/features/smart_scan/domain/repositories/smart_scan_repository.dart';

class DriftSmartScanRepository implements SmartScanRepository {
  DriftSmartScanRepository(this._database);
  final db.AppDatabase _database;

  @override
  Future<void> saveRecord(SmartScanRecord record) async {
    await _database
        .into(_database.smartScans)
        .insertOnConflictUpdate(
          db.SmartScansCompanion.insert(
            id: record.id,
            source: record.source.name,
            documentType: record.documentType.name,
            confidence: record.confidence,
            status: record.status,
            extractedAmount: Value(record.extractedAmount),
            merchant: Value(record.merchant),
            createdAt: Value(record.createdAt.toUtc()),
            confirmedAt: Value(record.confirmedAt?.toUtc()),
          ),
        );
  }

  @override
  Future<void> markConfirmed(String id) =>
      _mark(id, 'confirmed', confirmedAt: DateTime.now().toUtc());

  @override
  Future<void> markCancelled(String id) => _mark(id, 'cancelled');

  Future<void> _mark(String id, String status, {DateTime? confirmedAt}) {
    return (_database.update(
      _database.smartScans,
    )..where((row) => row.id.equals(id))).write(
      db.SmartScansCompanion(
        status: Value(status),
        confirmedAt: Value(confirmedAt),
      ),
    );
  }

  @override
  Future<String?> getStatus(String id) async {
    final row =
        await (_database.selectOnly(_database.smartScans)
              ..addColumns([_database.smartScans.status])
              ..where(_database.smartScans.id.equals(id)))
            .map((row) => row.read(_database.smartScans.status))
            .getSingleOrNull();
    return row;
  }
}
