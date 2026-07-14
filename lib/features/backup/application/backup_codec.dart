import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

class BackupException implements Exception {
  const BackupException(this.message);

  final String message;

  @override
  String toString() => message;
}

class BackupCodec {
  BackupCodec({this.iterations = 210000});

  static const format = 'nara.encrypted.backup';
  static const version = 1;
  static final _aad = utf8.encode('nara-backup-v1');

  final int iterations;
  final _cipher = AesGcm.with256bits();

  Future<Uint8List> encrypt(
    Map<String, Object?> snapshot,
    String password,
  ) async {
    _validatePassword(password);
    final salt = _randomBytes(16);
    final nonce = _randomBytes(12);
    final key = await _deriveKey(password, salt, iterations);
    final box = await _cipher.encrypt(
      utf8.encode(jsonEncode(snapshot)),
      secretKey: key,
      nonce: nonce,
      aad: _aad,
    );
    final envelope = <String, Object?>{
      'format': format,
      'version': version,
      'kdf': <String, Object?>{
        'name': 'pbkdf2-hmac-sha256',
        'iterations': iterations,
        'salt': base64Encode(salt),
      },
      'cipher': <String, Object?>{
        'name': 'aes-256-gcm',
        'nonce': base64Encode(nonce),
        'mac': base64Encode(box.mac.bytes),
      },
      'data': base64Encode(box.cipherText),
    };
    return Uint8List.fromList(utf8.encode(jsonEncode(envelope)));
  }

  Future<Map<String, Object?>> decrypt(Uint8List bytes, String password) async {
    _validatePassword(password);
    try {
      final envelope = jsonDecode(utf8.decode(bytes));
      if (envelope is! Map<String, dynamic> ||
          envelope['format'] != format ||
          envelope['version'] != version) {
        throw const BackupException('Format backup tidak didukung.');
      }
      final kdf = Map<String, dynamic>.from(envelope['kdf'] as Map);
      final cipher = Map<String, dynamic>.from(envelope['cipher'] as Map);
      final rounds = kdf['iterations'] as int;
      if (rounds < 100000 || rounds > 1000000) {
        throw const BackupException('Parameter keamanan backup tidak valid.');
      }
      final key = await _deriveKey(
        password,
        base64Decode(kdf['salt'] as String),
        rounds,
      );
      final clearText = await _cipher.decrypt(
        SecretBox(
          base64Decode(envelope['data'] as String),
          nonce: base64Decode(cipher['nonce'] as String),
          mac: Mac(base64Decode(cipher['mac'] as String)),
        ),
        secretKey: key,
        aad: _aad,
      );
      final snapshot = jsonDecode(utf8.decode(clearText));
      if (snapshot is! Map<String, dynamic>) {
        throw const BackupException('Isi backup tidak valid.');
      }
      return Map<String, Object?>.from(snapshot);
    } on BackupException {
      rethrow;
    } catch (_) {
      throw const BackupException(
        'Backup tidak dapat dibuka. Periksa password dan kondisi file.',
      );
    }
  }

  Future<SecretKey> _deriveKey(String password, List<int> salt, int rounds) {
    return Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: rounds,
      bits: 256,
    ).deriveKeyFromPassword(password: password, nonce: salt);
  }

  List<int> _randomBytes(int length) =>
      List<int>.generate(length, (_) => Random.secure().nextInt(256));

  void _validatePassword(String password) {
    if (password.length < 8) {
      throw const BackupException('Password backup minimal 8 karakter.');
    }
  }
}
