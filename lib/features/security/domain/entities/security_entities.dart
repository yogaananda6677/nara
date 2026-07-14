class PinCredential {
  const PinCredential({
    required this.hash,
    required this.salt,
    required this.iterations,
    this.failedAttempts = 0,
    this.lockedUntil,
  });

  final String hash;
  final String salt;
  final int iterations;
  final int failedAttempts;
  final DateTime? lockedUntil;

  PinCredential copyWith({
    int? failedAttempts,
    DateTime? lockedUntil,
    bool clearLockedUntil = false,
  }) => PinCredential(
    hash: hash,
    salt: salt,
    iterations: iterations,
    failedAttempts: failedAttempts ?? this.failedAttempts,
    lockedUntil: clearLockedUntil ? null : lockedUntil ?? this.lockedUntil,
  );
}

enum PinVerificationStatus { success, invalid, locked, notConfigured }

class PinVerification {
  const PinVerification(this.status, {this.remainingSeconds});

  final PinVerificationStatus status;
  final int? remainingSeconds;

  bool get isSuccess => status == PinVerificationStatus.success;
}
