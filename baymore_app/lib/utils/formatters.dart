import 'package:intl/intl.dart';

class Formatters {
  Formatters._();

  static final _cfaFormat = NumberFormat('#,##0', 'fr_FR');

  /// Formate un montant en Francs CFA, ex. 18500 -> "18 500 F"
  static String cfa(num amount) => '${_cfaFormat.format(amount)} F';

  /// [localeCode] : 'fr' ou 'en' — passer la langue courante (AppStrings /
  /// LocaleProvider) pour que les dates suivent la langue choisie.
  static String date(DateTime d, {String localeCode = 'fr'}) =>
      DateFormat('dd MMM yyyy, HH:mm', localeCode == 'en' ? 'en_US' : 'fr_FR').format(d);

  static String shortDate(DateTime d, {String localeCode = 'fr'}) =>
      DateFormat('dd MMM, HH:mm', localeCode == 'en' ? 'en_US' : 'fr_FR').format(d);
}
