import 'package:nara/features/security/domain/entities/security_entities.dart';

abstract interface class SecurityRepository {
  Future<PinCredential?> loadCredential();

  Future<void> saveCredential(PinCredential credential);

  Future<void> clearCredential();
}
