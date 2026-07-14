import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:nara/features/security/domain/entities/security_entities.dart';
import 'package:nara/features/security/domain/repositories/security_repository.dart';

class PinSecurityService {
  PinSecurityService(
    this._repository, {
    this.iterations = 210000,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final SecurityRepository _repository;
  final int iterations;
  final DateTime Function() _now;

  static final _pinPattern = RegExp(r'^\d{6}$');

  Future<bool> isConfigured() async =>
      await _repository.loadCredential() != null;

  Future<void> setPin(String pin) async {
    if (!_pinPattern.hasMatch(pin)) {
      throw const FormatException('PIN harus terdiri dari tepat 6 angka.');
    }
    final salt = List<int>.generate(16, (_) => Random.secure().nextInt(256));
    final hash = await _derive(pin, salt, iterations);
    await _repository.saveCredential(
      PinCredential(
        hash: base64Encode(hash),
        salt: base64Encode(salt),
        iterations: iterations,
      ),
    );
  }

  Future<PinVerification> verify(String pin) async {
    final credential = await _repository.loadCredential();
    if (credential == null) {
      return const PinVerification(PinVerificationStatus.notConfigured);
    }
    final now = _now().toUtc();
    if (credential.lockedUntil case final lockedUntil?
        when lockedUntil.isAfter(now)) {
      return PinVerification(
        PinVerificationStatus.locked,
        remainingSeconds: lockedUntil.difference(now).inSeconds + 1,
      );
    }

    final candidate = await _derive(
      pin,
      base64Decode(credential.salt),
      credential.iterations,
    );
    final expected = base64Decode(credential.hash);
    if (_constantTimeEquals(candidate, expected)) {
      await _repository.saveCredential(
        credential.copyWith(failedAttempts: 0, clearLockedUntil: true),
      );
      return const PinVerification(PinVerificationStatus.success);
    }

    final failed = credential.failedAttempts + 1;
    DateTime? lockedUntil;
    if (failed >= 5) {
      final block = ((failed - 5) ~/ 5).clamp(0, 4).toInt();
      lockedUntil = now.add(Duration(seconds: 30 * (1 << block)));
    }
    await _repository.saveCredential(
      credential.copyWith(
        failedAttempts: failed,
        lockedUntil: lockedUntil,
        clearLockedUntil: lockedUntil == null,
      ),
    );
    return PinVerification(
      lockedUntil == null
          ? PinVerificationStatus.invalid
          : PinVerificationStatus.locked,
      remainingSeconds: lockedUntil?.difference(now).inSeconds,
    );
  }

  Future<void> removePin() => _repository.clearCredential();

  Future<List<int>> _derive(String pin, List<int> salt, int rounds) async {
    final algorithm = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: rounds,
      bits: 256,
    );
    final key = await algorithm.deriveKeyFromPassword(
      password: pin,
      nonce: salt,
    );
    return key.extractBytes();
  }

  bool _constantTimeEquals(List<int> left, List<int> right) {
    var difference = left.length ^ right.length;
    final length = min(left.length, right.length);
    for (var index = 0; index < length; index++) {
      difference |= left[index] ^ right[index];
    }
    return difference == 0;
  }
}
