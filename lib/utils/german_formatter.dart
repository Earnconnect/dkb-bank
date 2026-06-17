import 'package:intl/intl.dart';

class GermanFormatter {
  static String waehrung(double betrag, {bool mitVorzeichen = false}) {
    final formatter = NumberFormat.currency(
      locale: 'de_DE',
      symbol: '€',
      decimalDigits: 2,
    );
    final formatted = formatter.format(betrag.abs());
    if (mitVorzeichen) {
      return betrag >= 0 ? '+$formatted' : '-$formatted';
    }
    return formatted;
  }

  static String datum(DateTime d, {bool lang = false}) {
    if (lang) return DateFormat('d. MMMM yyyy', 'de_DE').format(d);
    return DateFormat('dd.MM.yyyy', 'de_DE').format(d);
  }

  static String datumKurz(DateTime d) => DateFormat('dd.MM.', 'de_DE').format(d);

  static String monat(DateTime d) => DateFormat('MMMM yyyy', 'de_DE').format(d);

  static String datumRelativ(DateTime d) {
    final now = DateTime.now();
    final heute = DateTime(now.year, now.month, now.day);
    final tag = DateTime(d.year, d.month, d.day);
    final diff = heute.difference(tag).inDays;
    if (diff == 0) return 'Heute';
    if (diff == 1) return 'Gestern';
    return datum(d, lang: true);
  }

  static String ibanFormatiert(String iban) {
    final clean = iban.replaceAll(' ', '').toUpperCase();
    final buf = StringBuffer();
    for (int i = 0; i < clean.length; i++) {
      if (i > 0 && i % 4 == 0) buf.write(' ');
      buf.write(clean[i]);
    }
    return buf.toString();
  }

  static String ibanMaskiert(String iban) {
    final f = ibanFormatiert(iban);
    final parts = f.split(' ');
    if (parts.length <= 2) return f;
    final masked = parts.sublist(1, parts.length - 2).map((_) => '****').join(' ');
    return '${parts[0]} $masked ${parts[parts.length - 2]} ${parts[parts.length - 1]}';
  }

  static double parseGermanBetrag(String value) {
    final clean = value.trim().replaceAll(' ', '').replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(clean) ?? 0.0;
  }
}
