import 'package:flutter_test/flutter_test.dart';
import 'package:nara/features/security/application/pin_security_service.dart';
import 'package:nara/features/security/domain/entities/security_entities.dart';
import 'package:nara/features/security/domain/repositories/security_repository.dart';

void main() {
  late _MemorySecurityRepository repository;
  late DateTime now;
  late PinSecurityService service;

  setUp(() {
    repository = _MemorySecurityRepository();
    now = DateTime.utc(2026, 7, 14, 10);
    service = PinSecurityService(repository, iterations: 1000, now: () => now);
  });

  test('PIN disimpan sebagai hash dan dapat diverifikasi', () async {
    await service.setPin('123456');

    expect(repository.credential, isNotNull);
    expect(repository.credential!.hash, isNot(contains('123456')));
    expect(repository.credential!.salt, isNotEmpty);
    expect((await service.verify('123456')).isSuccess, isTrue);
  });

  test('PIN wajib tepat enam angka', () async {
    expect(() => service.setPin('12345'), throwsFormatException);
    expect(() => service.setPin('abcdef'), throwsFormatException);
  });

  test(
    'lima kegagalan mengaktifkan jeda dan PIN benar tetap ditolak',
    () async {
      await service.setPin('123456');
      for (var attempt = 1; attempt < 5; attempt++) {
        final result = await service.verify('000000');
        expect(result.status, PinVerificationStatus.invalid);
      }
      final fifth = await service.verify('000000');
      expect(fifth.status, PinVerificationStatus.locked);
      expect(fifth.remainingSeconds, 30);
      expect(
        (await service.verify('123456')).status,
        PinVerificationStatus.locked,
      );

      now = now.add(const Duration(seconds: 31));
      expect((await service.verify('123456')).isSuccess, isTrue);
      expect(repository.credential!.failedAttempts, 0);
      expect(repository.credential!.lockedUntil, isNull);
    },
  );
}

class _MemorySecurityRepository implements SecurityRepository {
  PinCredential? credential;

  @override
  Future<void> clearCredential() async => credential = null;

  @override
  Future<PinCredential?> loadCredential() async => credential;

  @override
  Future<void> saveCredential(PinCredential value) async => credential = value;
}
