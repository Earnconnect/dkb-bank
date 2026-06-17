enum KartenStatus { aktiv, gesperrt }

class VisaKarte {
  final String id;
  final String kartenNummer;
  final String ablaufdatum;
  final String karteninhaber;
  final double kreditlimit;
  double aktuellerSaldo;
  double unbezahlt;
  final DateTime abrechnungsperiodeBeginn;
  final DateTime abrechnungsperiodeEnde;
  KartenStatus status;

  VisaKarte({
    required this.id,
    required this.kartenNummer,
    required this.ablaufdatum,
    required this.karteninhaber,
    required this.kreditlimit,
    required this.aktuellerSaldo,
    required this.unbezahlt,
    required this.abrechnungsperiodeBeginn,
    required this.abrechnungsperiodeEnde,
    this.status = KartenStatus.aktiv,
  });

  String get maskedNummer {
    if (kartenNummer.length >= 4) {
      return '**** **** **** ${kartenNummer.substring(kartenNummer.length - 4)}';
    }
    return '**** **** **** ****';
  }

  String get letzteVier {
    if (kartenNummer.length >= 4) {
      return kartenNummer.substring(kartenNummer.length - 4);
    }
    return '****';
  }

  double get verfuegbaresLimit => kreditlimit - aktuellerSaldo;

  double get auslastungProzent => kreditlimit > 0 ? aktuellerSaldo / kreditlimit : 0;

  bool get isAktiv => status == KartenStatus.aktiv;

  String get statusLabel => status == KartenStatus.aktiv ? 'Aktiv' : 'Gesperrt';

  Map<String, dynamic> toJson() => {
        'id': id,
        'kartenNummer': kartenNummer,
        'ablaufdatum': ablaufdatum,
        'karteninhaber': karteninhaber,
        'kreditlimit': kreditlimit,
        'aktuellerSaldo': aktuellerSaldo,
        'unbezahlt': unbezahlt,
        'abrechnungsperiodeBeginn': abrechnungsperiodeBeginn.toIso8601String(),
        'abrechnungsperiodeEnde': abrechnungsperiodeEnde.toIso8601String(),
        'status': status.index,
      };

  factory VisaKarte.fromJson(Map<String, dynamic> json) => VisaKarte(
        id: json['id'],
        kartenNummer: json['kartenNummer'],
        ablaufdatum: json['ablaufdatum'],
        karteninhaber: json['karteninhaber'],
        kreditlimit: (json['kreditlimit'] as num).toDouble(),
        aktuellerSaldo: (json['aktuellerSaldo'] as num).toDouble(),
        unbezahlt: (json['unbezahlt'] as num).toDouble(),
        abrechnungsperiodeBeginn: DateTime.parse(json['abrechnungsperiodeBeginn']),
        abrechnungsperiodeEnde: DateTime.parse(json['abrechnungsperiodeEnde']),
        status: KartenStatus.values[json['status'] ?? 0],
      );
}
