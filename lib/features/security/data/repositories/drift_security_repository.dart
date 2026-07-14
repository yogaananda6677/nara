import 'package:drift/drift.dart';
import 'package:nara/database/app_database.dart';
import 'package:nara/features/security/domain/entities/security_entities.dart';
import 'package:nara/features/security/domain/repositories/security_repository.dart';

class DriftSecurityRepository implements SecurityRepository {
  DriftSecurityRepository(this._database);

  static const _credentialId = 'primary';
  final AppDatabase _database;

  @override
  Future<PinCredential?> loadCredential() async {
    final query = _database.select(_database.securityCredentials)
      ..where((row) => row.id.equals(_credentialId));
    final row = await query.getSingleOrNull();
    if (row == null) return null;
    return PinCredential(
      hash: row.pinHash,
      salt: row.pinSalt,
      iterations: row.kdfIterations,
      failedAttempts: row.failedAttempts,
      lockedUntil: row.lockedUntil,
    );
  }

  @override
  Future<void> saveCredential(PinCredential credential) async {
    await _database
        .into(_database.securityCredentials)
        .insertOnConflictUpdate(
          SecurityCredentialsCompanion.insert(
            id: _credentialId,
            pinHash: credential.hash,
            pinSalt: credential.salt,
            kdfIterations: credential.iterations,
            failedAttempts: Value(credential.failedAttempts),
            lockedUntil: Value(credential.lockedUntil?.toUtc()),
            updatedAt: Value(DateTime.now().toUtc()),
          ),
        );
  }

  @override
  Future<void> clearCredential() async {
    await (_database.delete(
      _database.securityCredentials,
    )..where((row) => row.id.equals(_credentialId))).go();
  }
}
