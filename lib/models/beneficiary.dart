class Beneficiary {
  final String id;
  final String name;
  final String kontonummer;
  final String iban;
  final String bic;
  final DateTime verknuepftAm;

  const Beneficiary({
    required this.id,
    required this.name,
    required this.kontonummer,
    required this.iban,
    required this.bic,
    required this.verknuepftAm,
  });

  String get ibanFormatiert {
    final raw = iban.replaceAll(' ', '');
    final buf = StringBuffer();
    for (int i = 0; i < raw.length; i++) {
      if (i > 0 && i % 4 == 0) buf.write(' ');
      buf.write(raw[i]);
    }
    return buf.toString();
  }

  String get ibanMaskiert {
    final raw = iban.replaceAll(' ', '');
    if (raw.length < 6) return raw;
    return '${raw.substring(0, 4)} **** **** ${raw.substring(raw.length - 4)}';
  }
}
