import 'package:intl/intl.dart';

abstract final class CurrencyFormatter {
  static final _rupiah = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp',
    decimalDigits: 0,
  );

  static String rupiah(int value) => _rupiah.format(value);

  static int? parse(String value) {
    final digits = value.replaceAll(RegExp('[^0-9]'), '');
    if (digits.isEmpty) return null;
    return int.tryParse(digits);
  }
}
