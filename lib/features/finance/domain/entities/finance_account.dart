enum FinanceAccountType {
  cash,
  bank,
  ewallet;

  String get label => switch (this) {
    FinanceAccountType.cash => 'Tunai',
    FinanceAccountType.bank => 'Bank',
    FinanceAccountType.ewallet => 'E-Wallet',
  };

  static FinanceAccountType fromStorage(String value) {
    return FinanceAccountType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => FinanceAccountType.cash,
    );
  }
}

class FinanceAccount {
  const FinanceAccount({
    required this.id,
    required this.name,
    required this.type,
    required this.openingBalance,
    required this.currency,
    required this.isArchived,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final FinanceAccountType type;
  final int openingBalance;
  final String currency;
  final bool isArchived;
  final DateTime createdAt;
  final DateTime updatedAt;
}

class AccountBalance {
  const AccountBalance({required this.account, required this.balance});

  final FinanceAccount account;
  final int balance;
}
