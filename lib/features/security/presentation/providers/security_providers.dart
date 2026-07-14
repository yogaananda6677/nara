import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nara/database/database_provider.dart';
import 'package:nara/features/security/application/biometric_authenticator.dart';
import 'package:nara/features/security/application/pin_security_service.dart';
import 'package:nara/features/security/data/repositories/drift_security_repository.dart';
import 'package:nara/features/security/domain/repositories/security_repository.dart';

final securityRepositoryProvider = Provider<SecurityRepository>((ref) {
  return DriftSecurityRepository(ref.watch(appDatabaseProvider));
});

final pinSecurityServiceProvider = Provider<PinSecurityService>((ref) {
  return PinSecurityService(ref.watch(securityRepositoryProvider));
});

final biometricAuthenticatorProvider = Provider<BiometricAuthenticator>((ref) {
  return DeviceBiometricAuthenticator();
});
