class Ueberweisung {
  final String id;
  final String vonKontoId;
  final String empfaengerName;
  final String iban;
  final String bic;
  final double betrag;
  final String verwendungszweck;
  final DateTime buchungsdatum;
  final bool istEilauftrag;

  Ueberweisung({
    required this.id,
    required this.vonKontoId,
    required this.empfaengerName,
    required this.iban,
    required this.bic,
    required this.betrag,
    required this.verwendungszweck,
    required this.buchungsdatum,
    this.istEilauftrag = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'vonKontoId': vonKontoId,
        'empfaengerName': empfaengerName,
        'iban': iban,
        'bic': bic,
        'betrag': betrag,
        'verwendungszweck': verwendungszweck,
        'buchungsdatum': buchungsdatum.toIso8601String(),
        'istEilauftrag': istEilauftrag,
      };
}
