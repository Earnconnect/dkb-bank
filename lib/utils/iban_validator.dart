import 'german_formatter.dart';

class IbanValidator {
  static bool isValid(String iban) {
    final clean = iban.replaceAll(' ', '').toUpperCase();
    if (clean.length < 15 || clean.length > 34) return false;
    if (!RegExp(r'^[A-Z]{2}[0-9]{2}[A-Z0-9]+$').hasMatch(clean)) return false;

    // Move first 4 chars to end and convert letters to numbers
    final rearranged = clean.substring(4) + clean.substring(0, 4);
    final numeric = rearranged.split('').map((c) {
      final code = c.codeUnitAt(0);
      if (code >= 65 && code <= 90) return (code - 55).toString();
      return c;
    }).join();

    // Mod-97 check in chunks (JS-safe big number handling)
    var remainder = 0;
    for (int i = 0; i < numeric.length; i++) {
      remainder = (remainder * 10 + int.parse(numeric[i])) % 97;
    }
    return remainder == 1;
  }

  static bool isDeIban(String iban) {
    final clean = iban.replaceAll(' ', '').toUpperCase();
    return clean.startsWith('DE') && clean.length == 22;
  }

  static String? bicLookup(String iban) {
    final clean = iban.replaceAll(' ', '').toUpperCase();
    if (clean.length < 12) return null;
    final blz = clean.substring(4, 12);
    const table = {
      '12030000': 'SSKMDEMMXXX', // Deutsche Kreditbank Berlin
      '10020000': 'HYVEDEMMXXX', // HypoVereinsbank Berlin
      '20010020': 'NBAGDE3EXXX', // N26
      '43060967': 'GENODEM1GLS', // GLS Bank
      '37040044': 'COBADEFFXXX', // Commerzbank
      '20041133': 'DAAEDEDDXXX', // Deutsche Bank Hamburg
      '10010010': 'PBNKDEFFXXX', // Postbank Berlin
      '30020900': 'BHFBDEFF300', // BHF Bank
      '50010517': 'INGDDEFFXXX', // ING-DiBa Frankfurt
      '70150000': 'SSKMDEMM',    // Sparkasse München
      '20070000': 'DEUTDEDBHAM', // Deutsche Bank Hamburg
      '10070000': 'DEUTDEBBXXX', // Deutsche Bank Berlin
      '37070060': 'DEUTDEDBDUE', // Deutsche Bank Düsseldorf
      '50070010': 'DEUTDEDBFRA', // Deutsche Bank Frankfurt
      '20040000': 'COBADEHHXXX', // Commerzbank Hamburg
      '37089000': 'GENODEMMXXX', // Volksbank Köln Bonn
      '30040000': 'COBADEDDXXX', // Commerzbank Düsseldorf
    };
    return table[blz];
  }

  static String format(String raw) =>
      GermanFormatter.ibanFormatiert(raw.toUpperCase().replaceAll(' ', ''));
}
