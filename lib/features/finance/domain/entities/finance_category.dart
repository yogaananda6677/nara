enum FinanceCategoryType {
  income,
  expense;

  String get label => switch (this) {
    FinanceCategoryType.income => 'Pemasukan',
    FinanceCategoryType.expense => 'Pengeluaran',
  };

  static FinanceCategoryType fromStorage(String value) {
    return value == 'income'
        ? FinanceCategoryType.income
        : FinanceCategoryType.expense;
  }
}

class FinanceCategory {
  const FinanceCategory({
    required this.id,
    required this.name,
    required this.type,
    required this.icon,
    required this.colorValue,
    required this.isSystem,
  });

  final String id;
  final String name;
  final FinanceCategoryType type;
  final String? icon;
  final int? colorValue;
  final bool isSystem;
}
