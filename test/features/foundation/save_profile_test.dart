import 'package:flutter_test/flutter_test.dart';
import 'package:nara/core/result/result.dart';
import 'package:nara/features/foundation/application/use_cases/save_profile.dart';
import 'package:uuid/uuid.dart';

import '../../helpers/fake_foundation_repository.dart';

void main() {
  test('menolak nama kosong sebelum menulis repository', () async {
    final repository = FakeFoundationRepository();
    final useCase = SaveProfile(repository, uuid: const Uuid());

    final result = await useCase(name: '  ', assistantName: 'Nara');

    expect(result, isA<Failure>());
    expect(repository.profile, isNull);
  });

  test('menormalisasi dan menyimpan profil baru', () async {
    final repository = FakeFoundationRepository();
    final useCase = SaveProfile(repository, uuid: const Uuid());

    final result = await useCase(name: '  Yoga  ', assistantName: ' Nara ');

    expect(result, isA<Success>());
    expect(repository.profile?.name, 'Yoga');
    expect(repository.profile?.assistantName, 'Nara');
    expect(repository.profile?.timezone, 'Asia/Jakarta');
  });
}
