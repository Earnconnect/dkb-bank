import '../models/app_user.dart';
import '../models/girokonto.dart';
import '../models/visa_karte.dart';
import '../models/umsatz.dart';
import '../models/dauerauftrag.dart';
import '../models/beneficiary.dart';

class MockData {
  static AppUser user = AppUser(
    id: 'usr-001',
    name: 'Max Mustermann',
    kontonummer: '12345678',
    pin: '1234',
    email: 'max.mustermann@email.de',
    adresse: 'Musterstraße 1, 10115 Berlin',
    status: BenutzerStatus.aktiv,
    kundeSeit: DateTime(2018, 3, 15),
  );

  static Girokonto girokonto = Girokonto(
    id: 'giro-001',
    iban: 'DE12120300001012345678',
    bic: 'SSKMDEMMXXX',
    kontonummer: '1012345678',
    saldo: 2847.50,
    verfuegbar: 2847.50,
    ueberziehungsrahmen: 500.0,
  );

  static VisaKarte visaKarte = VisaKarte(
    id: 'visa-001',
    kartenNummer: '4000000000004521',
    ablaufdatum: '09/29',
    karteninhaber: 'MAX MUSTERMANN',
    kreditlimit: 3000.0,
    aktuellerSaldo: 156.80,
    unbezahlt: 156.80,
    abrechnungsperiodeBeginn: DateTime(2026, 6, 1),
    abrechnungsperiodeEnde: DateTime(2026, 6, 30),
    status: KartenStatus.aktiv,
  );

  static List<Umsatz> umsaetze = [
    Umsatz(
      id: 'txn-001',
      kontoId: 'giro-001',
      kontoTyp: 'girokonto',
      buchungsdatum: DateTime(2026, 6, 15),
      wertstellung: DateTime(2026, 6, 15),
      auftraggeber: 'Muster GmbH',
      empfaenger: 'Max Mustermann',
      verwendungszweck: 'Gehalt Juni 2026',
      betrag: 2800.00,
      typ: UmsatzTyp.gutschrift,
      kategorie: UmsatzKategorie.gehalt,
      referenznummer: 'REF-001',
    ),
    Umsatz(
      id: 'txn-002',
      kontoId: 'giro-001',
      kontoTyp: 'girokonto',
      buchungsdatum: DateTime(2026, 6, 14),
      wertstellung: DateTime(2026, 6, 14),
      auftraggeber: 'Max Mustermann',
      empfaenger: 'Wohnungsgesellschaft Berlin GmbH',
      verwendungszweck: 'Miete Juni 2026 Musterstraße 1',
      betrag: 950.00,
      typ: UmsatzTyp.belastung,
      kategorie: UmsatzKategorie.miete,
    ),
    Umsatz(
      id: 'txn-003',
      kontoId: 'giro-001',
      kontoTyp: 'girokonto',
      buchungsdatum: DateTime(2026, 6, 13),
      wertstellung: DateTime(2026, 6, 13),
      auftraggeber: 'Max Mustermann',
      empfaenger: 'REWE Supermarkt',
      verwendungszweck: 'Einkauf REWE Berlin Mitte',
      betrag: 67.43,
      typ: UmsatzTyp.belastung,
      kategorie: UmsatzKategorie.lebensmittel,
    ),
    Umsatz(
      id: 'txn-004',
      kontoId: 'giro-001',
      kontoTyp: 'girokonto',
      buchungsdatum: DateTime(2026, 6, 12),
      wertstellung: DateTime(2026, 6, 12),
      auftraggeber: 'Max Mustermann',
      empfaenger: 'Deutsche Bahn AG',
      verwendungszweck: 'BahnCard 50 Verlängerung',
      betrag: 89.00,
      typ: UmsatzTyp.belastung,
      kategorie: UmsatzKategorie.transport,
    ),
    Umsatz(
      id: 'txn-005',
      kontoId: 'giro-001',
      kontoTyp: 'girokonto',
      buchungsdatum: DateTime(2026, 6, 11),
      wertstellung: DateTime(2026, 6, 11),
      auftraggeber: 'Amazon EU SARL',
      empfaenger: 'Max Mustermann',
      verwendungszweck: 'Amazon Rückerstattung Bestellung',
      betrag: 34.99,
      typ: UmsatzTyp.gutschrift,
      kategorie: UmsatzKategorie.onlineEinkauf,
    ),
    Umsatz(
      id: 'txn-006',
      kontoId: 'giro-001',
      kontoTyp: 'girokonto',
      buchungsdatum: DateTime(2026, 6, 10),
      wertstellung: DateTime(2026, 6, 10),
      auftraggeber: 'Max Mustermann',
      empfaenger: 'Spotify AB',
      verwendungszweck: 'Spotify Premium Monatsbeitrag',
      betrag: 9.99,
      typ: UmsatzTyp.belastung,
      kategorie: UmsatzKategorie.abonnement,
    ),
    Umsatz(
      id: 'txn-007',
      kontoId: 'giro-001',
      kontoTyp: 'girokonto',
      buchungsdatum: DateTime(2026, 6, 10),
      wertstellung: DateTime(2026, 6, 10),
      auftraggeber: 'Max Mustermann',
      empfaenger: 'Netflix International B.V.',
      verwendungszweck: 'Netflix Monatsabo Standard',
      betrag: 17.99,
      typ: UmsatzTyp.belastung,
      kategorie: UmsatzKategorie.abonnement,
    ),
    Umsatz(
      id: 'txn-008',
      kontoId: 'giro-001',
      kontoTyp: 'girokonto',
      buchungsdatum: DateTime(2026, 6, 9),
      wertstellung: DateTime(2026, 6, 9),
      auftraggeber: 'Max Mustermann',
      empfaenger: 'Lidl Dienstleistung',
      verwendungszweck: 'Lidl Filiale Berlin Mitte',
      betrag: 45.12,
      typ: UmsatzTyp.belastung,
      kategorie: UmsatzKategorie.lebensmittel,
    ),
    Umsatz(
      id: 'txn-009',
      kontoId: 'giro-001',
      kontoTyp: 'girokonto',
      buchungsdatum: DateTime(2026, 6, 8),
      wertstellung: DateTime(2026, 6, 8),
      auftraggeber: 'PayPal Europe SARL',
      empfaenger: 'Max Mustermann',
      verwendungszweck: 'Rückzahlung Urlaub Mallorca - Thomas M.',
      betrag: 250.00,
      typ: UmsatzTyp.gutschrift,
      kategorie: UmsatzKategorie.ueberweisung,
    ),
    Umsatz(
      id: 'txn-010',
      kontoId: 'giro-001',
      kontoTyp: 'girokonto',
      buchungsdatum: DateTime(2026, 6, 7),
      wertstellung: DateTime(2026, 6, 7),
      auftraggeber: 'Max Mustermann',
      empfaenger: 'BVG Berliner Verkehrsbetriebe',
      verwendungszweck: 'Monatskarte Juni 2026 AB',
      betrag: 86.00,
      typ: UmsatzTyp.belastung,
      kategorie: UmsatzKategorie.transport,
    ),
    Umsatz(
      id: 'txn-011',
      kontoId: 'giro-001',
      kontoTyp: 'girokonto',
      buchungsdatum: DateTime(2026, 6, 6),
      wertstellung: DateTime(2026, 6, 6),
      auftraggeber: 'Max Mustermann',
      empfaenger: 'Vodafone GmbH',
      verwendungszweck: 'Mobilfunk Rechnung Mai 2026',
      betrag: 29.99,
      typ: UmsatzTyp.belastung,
      kategorie: UmsatzKategorie.versicherung,
    ),
    Umsatz(
      id: 'txn-012',
      kontoId: 'giro-001',
      kontoTyp: 'girokonto',
      buchungsdatum: DateTime(2026, 6, 5),
      wertstellung: DateTime(2026, 6, 5),
      auftraggeber: 'Max Mustermann',
      empfaenger: 'AOK Berlin-Brandenburg',
      verwendungszweck: 'Krankenversicherungsbeitrag Juni 2026',
      betrag: 120.50,
      typ: UmsatzTyp.belastung,
      kategorie: UmsatzKategorie.versicherung,
    ),
    Umsatz(
      id: 'txn-013',
      kontoId: 'giro-001',
      kontoTyp: 'girokonto',
      buchungsdatum: DateTime(2026, 6, 4),
      wertstellung: DateTime(2026, 6, 4),
      auftraggeber: 'Max Mustermann',
      empfaenger: 'Zalando SE',
      verwendungszweck: 'Zalando Bestellung Nr. Z-4829-1100',
      betrag: 129.90,
      typ: UmsatzTyp.belastung,
      kategorie: UmsatzKategorie.onlineEinkauf,
    ),
    Umsatz(
      id: 'txn-014',
      kontoId: 'giro-001',
      kontoTyp: 'girokonto',
      buchungsdatum: DateTime(2026, 6, 3),
      wertstellung: DateTime(2026, 6, 3),
      auftraggeber: 'Max Mustermann',
      empfaenger: 'McDonald\'s Berlin Alexanderplatz',
      verwendungszweck: 'Restaurant Bezahlung',
      betrag: 8.50,
      typ: UmsatzTyp.belastung,
      kategorie: UmsatzKategorie.restaurant,
    ),
    Umsatz(
      id: 'txn-015',
      kontoId: 'giro-001',
      kontoTyp: 'girokonto',
      buchungsdatum: DateTime(2026, 6, 2),
      wertstellung: DateTime(2026, 6, 2),
      auftraggeber: 'Max Mustermann',
      empfaenger: 'Shell Deutschland GmbH',
      verwendungszweck: 'Tankstelle Shell Berlin Prenzlauer Berg',
      betrag: 65.00,
      typ: UmsatzTyp.belastung,
      kategorie: UmsatzKategorie.transport,
    ),
    Umsatz(
      id: 'txn-016',
      kontoId: 'giro-001',
      kontoTyp: 'girokonto',
      buchungsdatum: DateTime(2026, 6, 2),
      wertstellung: DateTime(2026, 6, 2),
      auftraggeber: 'Max Mustermann',
      empfaenger: 'Apotheke am Bahnhof',
      verwendungszweck: 'Medikamente Rezept',
      betrag: 23.60,
      typ: UmsatzTyp.belastung,
      kategorie: UmsatzKategorie.gesundheit,
    ),
    Umsatz(
      id: 'txn-017',
      kontoId: 'giro-001',
      kontoTyp: 'girokonto',
      buchungsdatum: DateTime(2026, 6, 1),
      wertstellung: DateTime(2026, 6, 1),
      auftraggeber: 'Max Mustermann',
      empfaenger: 'ARD ZDF Deutschlandradio',
      verwendungszweck: 'Rundfunkbeitrag 2. Quartal 2026',
      betrag: 18.36,
      typ: UmsatzTyp.belastung,
      kategorie: UmsatzKategorie.gebuehr,
    ),
    Umsatz(
      id: 'txn-018',
      kontoId: 'giro-001',
      kontoTyp: 'girokonto',
      buchungsdatum: DateTime(2026, 6, 1),
      wertstellung: DateTime(2026, 6, 1),
      auftraggeber: 'Max Mustermann',
      empfaenger: 'H&M Hennes & Mauritz',
      verwendungszweck: 'H&M Online Shop Bestellung',
      betrag: 55.00,
      typ: UmsatzTyp.belastung,
      kategorie: UmsatzKategorie.onlineEinkauf,
    ),
    Umsatz(
      id: 'txn-019',
      kontoId: 'giro-001',
      kontoTyp: 'girokonto',
      buchungsdatum: DateTime(2026, 5, 31),
      wertstellung: DateTime(2026, 5, 31),
      auftraggeber: 'Max Mustermann',
      empfaenger: 'Klaus Mustermann',
      verwendungszweck: 'Rückzahlung Abendessen',
      betrag: 200.00,
      typ: UmsatzTyp.belastung,
      kategorie: UmsatzKategorie.ueberweisung,
    ),
    Umsatz(
      id: 'txn-020',
      kontoId: 'visa-001',
      kontoTyp: 'visa',
      buchungsdatum: DateTime(2026, 6, 13),
      wertstellung: DateTime(2026, 6, 13),
      auftraggeber: 'Max Mustermann',
      empfaenger: 'Amazon.de',
      verwendungszweck: 'Amazon.de Marketplace Einkauf',
      betrag: 34.99,
      typ: UmsatzTyp.belastung,
      kategorie: UmsatzKategorie.onlineEinkauf,
    ),
    Umsatz(
      id: 'txn-021',
      kontoId: 'visa-001',
      kontoTyp: 'visa',
      buchungsdatum: DateTime(2026, 6, 11),
      wertstellung: DateTime(2026, 6, 11),
      auftraggeber: 'Max Mustermann',
      empfaenger: 'Airbnb Ireland UC',
      verwendungszweck: 'Airbnb Unterkunft Barcelona',
      betrag: 89.50,
      typ: UmsatzTyp.belastung,
      kategorie: UmsatzKategorie.sonstiges,
    ),
    Umsatz(
      id: 'txn-022',
      kontoId: 'visa-001',
      kontoTyp: 'visa',
      buchungsdatum: DateTime(2026, 6, 8),
      wertstellung: DateTime(2026, 6, 8),
      auftraggeber: 'Max Mustermann',
      empfaenger: 'Rossmann Drogerie',
      verwendungszweck: 'Rossmann Drogerie Berlin',
      betrag: 32.31,
      typ: UmsatzTyp.belastung,
      kategorie: UmsatzKategorie.lebensmittel,
    ),
  ];

  static List<Dauerauftrag> dauerauftraege = [
    Dauerauftrag(
      id: 'da-001',
      vonKontoId: 'giro-001',
      empfaengerName: 'Wohnungsgesellschaft Berlin GmbH',
      iban: 'DE89370400440532013000',
      bic: 'COBADEFFXXX',
      betrag: 950.00,
      verwendungszweck: 'Miete Musterstraße 1, 10115 Berlin',
      turnus: Turnus.monatlich,
      naechsteAusfuehrung: DateTime(2026, 7, 1),
      isAktiv: true,
    ),
    Dauerauftrag(
      id: 'da-002',
      vonKontoId: 'giro-001',
      empfaengerName: 'Netflix International B.V.',
      iban: 'DE21200400600003157801',
      bic: 'COBADEFFXXX',
      betrag: 17.99,
      verwendungszweck: 'Netflix Monatsabo',
      turnus: Turnus.monatlich,
      naechsteAusfuehrung: DateTime(2026, 7, 10),
      isAktiv: true,
    ),
  ];

  // Secondary DKB demo accounts for beneficiary linking
  static const Map<String, String> _mockDkbAccounts = {
    '87654321': '5678',
    '11223344': '4321',
    '55667788': '9999',
  };

  static const Map<String, String> _mockDkbNames = {
    '87654321': 'Klaus Mustermann',
    '11223344': 'Anna Schmidt',
    '55667788': 'Thomas Weber',
  };

  static bool validateDkbAccount(String kontonummer, String pin) {
    if (kontonummer == user.kontonummer) return false;
    return _mockDkbAccounts[kontonummer] == pin;
  }

  static String dkbAccountName(String kontonummer) =>
      _mockDkbNames[kontonummer] ?? 'DKB Kontoinhaber';

  static String dkbAccountIban(String kontonummer) {
    final padded = kontonummer.padLeft(10, '0');
    return 'DE49120300000$padded';
  }

  static List<Beneficiary> beneficiaries = [
    Beneficiary(
      id: 'ben-001',
      name: 'Klaus Mustermann',
      kontonummer: '87654321',
      iban: 'DE49120300000087654321',
      bic: 'SSKMDEMMXXX',
      verknuepftAm: DateTime(2025, 11, 15),
    ),
  ];

  static List<Umsatz> umsaetzeForGirokonto() =>
      umsaetze.where((u) => u.kontoId == 'giro-001').toList()
        ..sort((a, b) => b.buchungsdatum.compareTo(a.buchungsdatum));

  static List<Umsatz> umsaetzeForVisa() =>
      umsaetze.where((u) => u.kontoId == 'visa-001').toList()
        ..sort((a, b) => b.buchungsdatum.compareTo(a.buchungsdatum));

  static bool validatePin(String kontonummer, String pin) =>
      user.kontonummer == kontonummer && user.pin == pin;
}
