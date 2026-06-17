import 'package:flutter/foundation.dart';
import '../data/mock_data.dart';
import '../models/umsatz.dart';
import '../models/dauerauftrag.dart';
import '../models/visa_karte.dart';
import '../models/beneficiary.dart';
import '../services/storage_service.dart';

class AppState extends ChangeNotifier {
  static final AppState _instance = AppState._internal();
  factory AppState() => _instance;
  AppState._internal();

  bool isAngemeldet = false;
  int _activeTab = 0;
  int get activeTab => _activeTab;

  void setTab(int i) {
    _activeTab = i;
    notifyListeners();
  }

  void _save() {
    StorageService.saveAll();
  }

  bool anmelden(String kontonummer, String pin) {
    if (MockData.validatePin(kontonummer, pin)) {
      isAngemeldet = true;
      StorageService.saveSession(kontonummer);
      notifyListeners();
      return true;
    }
    return false;
  }

  void abmelden() {
    isAngemeldet = false;
    _activeTab = 0;
    StorageService.clearSession();
    notifyListeners();
  }

  void saldoAktualisieren(double delta) {
    MockData.girokonto.saldo += delta;
    MockData.girokonto.verfuegbar += delta;
    _save();
    notifyListeners();
  }

  String ueberweisenAusfuehren({
    required String empfaengerName,
    required String iban,
    required String bic,
    required double betrag,
    required String verwendungszweck,
  }) {
    final ref = 'TAN${DateTime.now().millisecondsSinceEpoch % 100000000}';
    final now = DateTime.now();

    final umsatz = Umsatz(
      id: 'txn-${MockData.umsaetze.length + 1}',
      kontoId: 'giro-001',
      kontoTyp: 'girokonto',
      buchungsdatum: now,
      wertstellung: now,
      auftraggeber: MockData.user.name,
      empfaenger: empfaengerName,
      verwendungszweck: verwendungszweck,
      betrag: betrag,
      typ: UmsatzTyp.belastung,
      kategorie: UmsatzKategorie.ueberweisung,
      referenznummer: ref,
    );

    MockData.umsaetze.add(umsatz);
    saldoAktualisieren(-betrag);
    return ref;
  }

  void karteGefrieren(bool freeze) {
    MockData.visaKarte.status = freeze ? KartenStatus.gesperrt : KartenStatus.aktiv;
    _save();
    notifyListeners();
  }

  void visaSaldoAktualisieren(double delta) {
    MockData.visaKarte.aktuellerSaldo += delta;
    MockData.visaKarte.unbezahlt += delta;
    _save();
    notifyListeners();
  }

  void dauerauftragHinzufuegen(Dauerauftrag d) {
    MockData.dauerauftraege.add(d);
    _save();
    notifyListeners();
  }

  void dauerauftragLoeschen(String id) {
    MockData.dauerauftraege.removeWhere((d) => d.id == id);
    _save();
    notifyListeners();
  }

  void dauerauftragUmschalten(String id) {
    final idx = MockData.dauerauftraege.indexWhere((d) => d.id == id);
    if (idx >= 0) {
      MockData.dauerauftraege[idx].isAktiv = !MockData.dauerauftraege[idx].isAktiv;
      _save();
      notifyListeners();
    }
  }

  void pinAendern(String neuePin) {
    MockData.user.pin = neuePin;
    _save();
    notifyListeners();
  }

  bool isDkbIban(String iban) {
    final raw = iban.replaceAll(' ', '').toUpperCase();
    return raw.length >= 12 && raw.substring(4, 12) == '12030000';
  }

  bool isBeneficiary(String iban) {
    final raw = iban.replaceAll(' ', '').toUpperCase();
    return MockData.beneficiaries
        .any((b) => b.iban.replaceAll(' ', '').toUpperCase() == raw);
  }

  Beneficiary? findBeneficiary(String iban) {
    final raw = iban.replaceAll(' ', '').toUpperCase();
    try {
      return MockData.beneficiaries
          .firstWhere((b) => b.iban.replaceAll(' ', '').toUpperCase() == raw);
    } catch (_) {
      return null;
    }
  }

  void beneficiaryHinzufuegen(Beneficiary b) {
    MockData.beneficiaries.add(b);
    notifyListeners();
  }

  void beneficiaryLoeschen(String id) {
    MockData.beneficiaries.removeWhere((b) => b.id == id);
    notifyListeners();
  }

  void faelligeAuftraegeAusfuehren() {
    final now = DateTime.now();
    for (final da in MockData.dauerauftraege) {
      if (!da.isAktiv) continue;
      if (da.naechsteAusfuehrung.isBefore(now) || da.faelligHeute) {
        if (MockData.girokonto.verfuegbar >= da.betrag) {
          ueberweisenAusfuehren(
            empfaengerName: da.empfaengerName,
            iban: da.iban,
            bic: da.bic,
            betrag: da.betrag,
            verwendungszweck: da.verwendungszweck,
          );
          da.naechsteAusfuehrung = da.naechsteAusfuehrungNach();
        }
      }
    }
  }
}
