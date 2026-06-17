enum Turnus { woechentlich, monatlich, vierteljaehrlich }

class Dauerauftrag {
  final String id;
  final String vonKontoId;
  final String empfaengerName;
  final String iban;
  final String bic;
  final double betrag;
  final String verwendungszweck;
  final Turnus turnus;
  DateTime naechsteAusfuehrung;
  DateTime? endDatum;
  bool isAktiv;

  Dauerauftrag({
    required this.id,
    required this.vonKontoId,
    required this.empfaengerName,
    required this.iban,
    required this.bic,
    required this.betrag,
    required this.verwendungszweck,
    required this.turnus,
    required this.naechsteAusfuehrung,
    this.endDatum,
    this.isAktiv = true,
  });

  String get turnusLabel {
    switch (turnus) {
      case Turnus.woechentlich:
        return 'Wöchentlich';
      case Turnus.monatlich:
        return 'Monatlich';
      case Turnus.vierteljaehrlich:
        return 'Vierteljährlich';
    }
  }

  bool get faelligHeute {
    final now = DateTime.now();
    return naechsteAusfuehrung.year == now.year &&
        naechsteAusfuehrung.month == now.month &&
        naechsteAusfuehrung.day == now.day;
  }

  String get ibanMaskiert {
    final clean = iban.replaceAll(' ', '');
    if (clean.length < 4) return iban;
    return '${clean.substring(0, 2)}** **** **** **** ${clean.substring(clean.length - 4)}';
  }

  DateTime naechsteAusfuehrungNach() {
    switch (turnus) {
      case Turnus.woechentlich:
        return naechsteAusfuehrung.add(const Duration(days: 7));
      case Turnus.monatlich:
        return DateTime(
          naechsteAusfuehrung.year,
          naechsteAusfuehrung.month + 1,
          naechsteAusfuehrung.day,
        );
      case Turnus.vierteljaehrlich:
        return DateTime(
          naechsteAusfuehrung.year,
          naechsteAusfuehrung.month + 3,
          naechsteAusfuehrung.day,
        );
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'vonKontoId': vonKontoId,
        'empfaengerName': empfaengerName,
        'iban': iban,
        'bic': bic,
        'betrag': betrag,
        'verwendungszweck': verwendungszweck,
        'turnus': turnus.index,
        'naechsteAusfuehrung': naechsteAusfuehrung.toIso8601String(),
        'endDatum': endDatum?.toIso8601String(),
        'isAktiv': isAktiv,
      };

  factory Dauerauftrag.fromJson(Map<String, dynamic> json) => Dauerauftrag(
        id: json['id'],
        vonKontoId: json['vonKontoId'],
        empfaengerName: json['empfaengerName'],
        iban: json['iban'],
        bic: json['bic'],
        betrag: (json['betrag'] as num).toDouble(),
        verwendungszweck: json['verwendungszweck'],
        turnus: Turnus.values[json['turnus']],
        naechsteAusfuehrung: DateTime.parse(json['naechsteAusfuehrung']),
        endDatum: json['endDatum'] != null ? DateTime.parse(json['endDatum']) : null,
        isAktiv: json['isAktiv'] ?? true,
      );
}
