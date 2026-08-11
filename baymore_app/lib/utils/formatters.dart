import 'package:intl/intl.dart';

class Formatters {
  Formatters._();

  static final _cfaFormat = NumberFormat('#,##0', 'fr_FR');

  /// Formate un montant en Francs CFA, ex. 18500 -> "18 500 F"
  static String cfa(num amount) => '${_cfaFormat.format(amount)} F';

  static String date(DateTime d) => DateFormat('dd MMM yyyy, HH:mm', 'fr_FR').format(d);

  static String shortDate(DateTime d) => DateFormat('dd MMM, HH:mm', 'fr_FR').format(d);
}
