import 'package:flutter_test/flutter_test.dart';
import 'package:nara/core/result/result.dart';
import 'package:nara/features/finance/application/finance_service.dart';
import 'package:nara/features/finance/domain/entities/finance_account.dart';

import '../../helpers/fake_finance_repository.dart';

void main() {
  test('menolak akun tanpa nama dan saldo negatif', () async {
    final service = FinanceService(FakeFinanceRepository());

    final result = await service.saveAccount(
      const AccountInput(
        name: ' ',
        type: FinanceAccountType.cash,
        openingBalance: -1,
      ),
    );

    expect(result, isA<Failure>());
  });

  test('menolak transfer ke akun yang sama', () async {
    final service = FinanceService(FakeFinanceRepository());

    final result = await service.transfer(
      TransferInput(
        fromAccountId: 'cash',
        toAccountId: 'cash',
        amount: 10000,
        date: DateTime.now(),
      ),
    );

    expect(result, isA<Failure>());
  });
}
