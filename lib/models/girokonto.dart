class Girokonto {
  final String id;
  final String iban;
  final String bic;
  final String kontonummer;
  double saldo;
  double verfuegbar;
  final double ueberziehungsrahmen;

  Girokonto({
    required this.id,
    required this.iban,
    required this.bic,
    required this.kontonummer,
    required this.saldo,
    required this.verfuegbar,
    this.ueberziehungsrahmen = 500.0,
  });

  String get ibanFormatiert {
    final clean = iban.replaceAll(' ', '');
    final buf = StringBuffer();
    for (int i = 0; i < clean.length; i++) {
      if (i > 0 && i % 4 == 0) buf.write(' ');
      buf.write(clean[i]);
    }
    return buf.toString();
  }

  String get ibanMaskiert {
    final f = ibanFormatiert;
    final parts = f.split(' ');
    if (parts.length <= 2) return f;
    final masked = parts.sublist(1, parts.length - 2).map((_) => '****').join(' ');
    return '${parts[0]} $masked ${parts[parts.length - 2]} ${parts[parts.length - 1]}';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'iban': iban,
        'bic': bic,
        'kontonummer': kontonummer,
        'saldo': saldo,
        'verfuegbar': verfuegbar,
        'ueberziehungsrahmen': ueberziehungsrahmen,
      };

  factory Girokonto.fromJson(Map<String, dynamic> json) => Girokonto(
        id: json['id'],
        iban: json['iban'],
        bic: json['bic'],
        kontonummer: json['kontonummer'],
        saldo: (json['saldo'] as num).toDouble(),
        verfuegbar: (json['verfuegbar'] as num).toDouble(),
        ueberziehungsrahmen: (json['ueberziehungsrahmen'] as num).toDouble(),
      );
}
