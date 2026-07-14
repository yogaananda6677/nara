import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nara/database/database_provider.dart';
import 'package:nara/features/backup/application/backup_codec.dart';
import 'package:nara/features/backup/application/backup_file_service.dart';
import 'package:nara/features/backup/data/drift_backup_repository.dart';

final backupRepositoryProvider = Provider<DriftBackupRepository>((ref) {
  return DriftBackupRepository(ref.watch(appDatabaseProvider));
});

final backupCodecProvider = Provider<BackupCodec>((ref) => BackupCodec());

final backupFileServiceProvider = Provider<BackupFileService>((ref) {
  return BackupFileService(
    ref.watch(backupRepositoryProvider),
    ref.watch(backupCodecProvider),
  );
});
