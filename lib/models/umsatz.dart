import 'package:flutter/material.dart';

enum UmsatzTyp { gutschrift, belastung }

enum UmsatzKategorie {
  gehalt,
  miete,
  lebensmittel,
  transport,
  unterhaltung,
  gesundheit,
  versicherung,
  abonnement,
  onlineEinkauf,
  restaurant,
  ueberweisung,
  gebuehr,
  sonstiges,
}

class Umsatz {
  final String id;
  final String kontoId;
  final String kontoTyp;
  final DateTime buchungsdatum;
  final DateTime wertstellung;
  final String auftraggeber;
  final String empfaenger;
  final String verwendungszweck;
  final double betrag;
  final UmsatzTyp typ;
  final UmsatzKategorie kategorie;
  final bool istVormerkung;
  final String? referenznummer;

  Umsatz({
    required this.id,
    required this.kontoId,
    required this.kontoTyp,
    required this.buchungsdatum,
    required this.wertstellung,
    this.auftraggeber = '',
    this.empfaenger = '',
    required this.verwendungszweck,
    required this.betrag,
    required this.typ,
    this.kategorie = UmsatzKategorie.sonstiges,
    this.istVormerkung = false,
    this.referenznummer,
  });

  bool get isGutschrift => typ == UmsatzTyp.gutschrift;
  bool get isBelastung => typ == UmsatzTyp.belastung;

  String get typLabel => isGutschrift ? 'Gutschrift' : 'Belastung';

  String get gegenpartei => isGutschrift ? auftraggeber : empfaenger;

  String get kategorieLabel {
    switch (kategorie) {
      case UmsatzKategorie.gehalt:
        return 'Gehalt';
      case UmsatzKategorie.miete:
        return 'Miete & Wohnen';
      case UmsatzKategorie.lebensmittel:
        return 'Lebensmittel';
      case UmsatzKategorie.transport:
        return 'Transport';
      case UmsatzKategorie.unterhaltung:
        return 'Unterhaltung';
      case UmsatzKategorie.gesundheit:
        return 'Gesundheit';
      case UmsatzKategorie.versicherung:
        return 'Versicherung';
      case UmsatzKategorie.abonnement:
        return 'Abonnements';
      case UmsatzKategorie.onlineEinkauf:
        return 'Online-Einkauf';
      case UmsatzKategorie.restaurant:
        return 'Restaurant';
      case UmsatzKategorie.ueberweisung:
        return 'Überweisung';
      case UmsatzKategorie.gebuehr:
        return 'Gebühren';
      case UmsatzKategorie.sonstiges:
        return 'Sonstiges';
    }
  }

  IconData get kategorieIcon {
    switch (kategorie) {
      case UmsatzKategorie.gehalt:
        return Icons.work_outline;
      case UmsatzKategorie.miete:
        return Icons.home_outlined;
      case UmsatzKategorie.lebensmittel:
        return Icons.shopping_cart_outlined;
      case UmsatzKategorie.transport:
        return Icons.directions_transit_outlined;
      case UmsatzKategorie.unterhaltung:
        return Icons.movie_outlined;
      case UmsatzKategorie.gesundheit:
        return Icons.local_hospital_outlined;
      case UmsatzKategorie.versicherung:
        return Icons.shield_outlined;
      case UmsatzKategorie.abonnement:
        return Icons.subscriptions_outlined;
      case UmsatzKategorie.onlineEinkauf:
        return Icons.laptop_outlined;
      case UmsatzKategorie.restaurant:
        return Icons.restaurant_outlined;
      case UmsatzKategorie.ueberweisung:
        return Icons.swap_horiz;
      case UmsatzKategorie.gebuehr:
        return Icons.receipt_outlined;
      case UmsatzKategorie.sonstiges:
        return Icons.more_horiz;
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'kontoId': kontoId,
        'kontoTyp': kontoTyp,
        'buchungsdatum': buchungsdatum.toIso8601String(),
        'wertstellung': wertstellung.toIso8601String(),
        'auftraggeber': auftraggeber,
        'empfaenger': empfaenger,
        'verwendungszweck': verwendungszweck,
        'betrag': betrag,
        'typ': typ.index,
        'kategorie': kategorie.index,
        'istVormerkung': istVormerkung,
        'referenznummer': referenznummer,
      };

  factory Umsatz.fromJson(Map<String, dynamic> json) => Umsatz(
        id: json['id'],
        kontoId: json['kontoId'],
        kontoTyp: json['kontoTyp'],
        buchungsdatum: DateTime.parse(json['buchungsdatum']),
        wertstellung: DateTime.parse(json['wertstellung']),
        auftraggeber: json['auftraggeber'] ?? '',
        empfaenger: json['empfaenger'] ?? '',
        verwendungszweck: json['verwendungszweck'],
        betrag: (json['betrag'] as num).toDouble(),
        typ: UmsatzTyp.values[json['typ']],
        kategorie: UmsatzKategorie.values[json['kategorie'] ?? 12],
        istVormerkung: json['istVormerkung'] ?? false,
        referenznummer: json['referenznummer'],
      );
}
