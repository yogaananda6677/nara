import 'package:flutter/services.dart';
import 'package:nara/features/backup/application/backup_codec.dart';
import 'package:nara/features/backup/data/drift_backup_repository.dart';

class BackupFileService {
  BackupFileService(this._repository, this._codec, {BackupFileGateway? gateway})
    : _gateway = gateway ?? const AndroidBackupFileGateway();

  final DriftBackupRepository _repository;
  final BackupCodec _codec;
  final BackupFileGateway _gateway;

  Future<bool> export(String password) async {
    final snapshot = await _repository.createSnapshot();
    final bytes = await _codec.encrypt(snapshot, password);
    final now = DateTime.now().toUtc().toIso8601String().replaceAll(':', '-');
    return _gateway.save('nara-backup-$now.nara', bytes);
  }

  Future<bool> restore(String password) async {
    final bytes = await _gateway.open();
    if (bytes == null) return false;
    final snapshot = await _codec.decrypt(bytes, password);
    await _repository.restoreSnapshot(snapshot);
    return true;
  }
}

abstract interface class BackupFileGateway {
  Future<bool> save(String suggestedName, Uint8List bytes);

  Future<Uint8List?> open();
}

class AndroidBackupFileGateway implements BackupFileGateway {
  const AndroidBackupFileGateway();

  static const _channel = MethodChannel('ananda.yoga.nara/backup_files');

  @override
  Future<Uint8List?> open() => _channel.invokeMethod<Uint8List>('openBackup');

  @override
  Future<bool> save(String suggestedName, Uint8List bytes) async {
    return await _channel.invokeMethod<bool>('saveBackup', {
          'name': suggestedName,
          'bytes': bytes,
        }) ??
        false;
  }
}
