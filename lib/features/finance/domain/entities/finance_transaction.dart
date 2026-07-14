enum FinanceTransactionType {
  income,
  expense,
  transferIn,
  transferOut;

  bool get isTransfer =>
      this == FinanceTransactionType.transferIn ||
      this == FinanceTransactionType.transferOut;

  static FinanceTransactionType fromStorage(String value) {
    return FinanceTransactionType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => FinanceTransactionType.expense,
    );
  }
}

class FinanceTransaction {
  const FinanceTransaction({
    required this.id,
    required this.accountId,
    required this.categoryId,
    required this.transferPairId,
    required this.type,
    required this.amount,
    required this.date,
    required this.merchant,
    required this.description,
    required this.source,
    required this.createdAt,
    required this.updatedAt,
    this.scanId,
  });

  final String id;
  final String accountId;
  final String? categoryId;
  final String? transferPairId;
  final FinanceTransactionType type;
  final int amount;
  final DateTime date;
  final String? merchant;
  final String? description;
  final String source;
  final String? scanId;
  final DateTime createdAt;
  final DateTime updatedAt;
}

enum TransactionFilter {
  all,
  income,
  expense;

  String get label => switch (this) {
    TransactionFilter.all => 'Semua',
    TransactionFilter.income => 'Pemasukan',
    TransactionFilter.expense => 'Pengeluaran',
  };
}
