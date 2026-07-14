import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nara/features/backup/application/backup_codec.dart';

void main() {
  late BackupCodec codec;

  setUp(() => codec = BackupCodec(iterations: 100000));

  test('round-trip mempertahankan isi snapshot', () async {
    final snapshot = <String, Object?>{
      'format': 'test',
      'tables': <String, Object?>{
        'profiles': [
          {'name': 'Yoga'},
        ],
      },
    };

    final encrypted = await codec.encrypt(snapshot, 'rahasia-kuat');

    expect(utf8.decode(encrypted), isNot(contains('Yoga')));
    expect(await codec.decrypt(encrypted, 'rahasia-kuat'), snapshot);
  });

  test('password salah dan file rusak ditolak', () async {
    final encrypted = await codec.encrypt(<String, Object?>{
      'value': 42,
    }, 'rahasia-kuat');

    expect(
      () => codec.decrypt(encrypted, 'password-salah'),
      throwsA(isA<BackupException>()),
    );
    expect(
      () => codec.decrypt(Uint8List.fromList([1, 2, 3]), 'rahasia-kuat'),
      throwsA(isA<BackupException>()),
    );
  });
}
