import 'package:flutter/foundation.dart';
import '../data/mock_data.dart';
import '../models/app_user.dart';
import '../models/girokonto.dart';
import '../models/visa_karte.dart';
import '../models/umsatz.dart';
import '../models/dauerauftrag.dart';
import '../models/beneficiary.dart';
import '../services/storage_service.dart';
import '../services/api_service.dart';

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

  // ── Auth ──────────────────────────────────────────────────────────────────

  Future<bool> anmelden(String kontonummer, String pin) async {
    try {
      final result = await ApiService.instance.login(kontonummer, pin);
      if (result['statusCode'] != 200) return false;

      _hydrateUser(result);
      await _loadAllData();

      isAngemeldet = true;
      StorageService.saveSession(kontonummer);
      notifyListeners();
      return true;
    } catch (_) {
      // Fall back to MockData validation when API is unreachable
      if (MockData.validatePin(kontonummer, pin)) {
        isAngemeldet = true;
        StorageService.saveSession(kontonummer);
        notifyListeners();
        return true;
      }
      return false;
    }
  }

  Future<Map<String, dynamic>> registrieren({
    required String name,
    String? email,
    required String pin,
    required String confirmPin,
  }) async {
    final result = await ApiService.instance.register(
      name: name,
      email: email,
      pin: pin,
      confirmPin: confirmPin,
    );
    if (result['statusCode'] == 201) {
      _hydrateUser(result);
      await _loadAllData();
      isAngemeldet = true;
      StorageService.saveSession(result['kontonummer'] as String);
      notifyListeners();
    }
    return result;
  }

  Future<bool> sessionWiederherstellen(String kontonummer) async {
    try {
      final result = await ApiService.instance.me();
      if (result['statusCode'] != 200) return false;

      _hydrateUser(result);
      await _loadAllData();

      isAngemeldet = true;
      notifyListeners();
      return true;
    } catch (_) {
      isAngemeldet = true;
      notifyListeners();
      return true;
    }
  }

  void abmelden() {
    isAngemeldet = false;
    _activeTab = 0;
    ApiService.instance.clearToken();
    StorageService.clearSession();
    notifyListeners();
  }

  // ── Hydration ─────────────────────────────────────────────────────────────

  void _hydrateUser(Map<String, dynamic> data) {
    final u = data['user'] as Map<String, dynamic>?;
    final g = data['girokonto'] as Map<String, dynamic>?;
    final v = data['visaKarte'] as Map<String, dynamic>?;

    if (u != null) {
      MockData.user = AppUser(
        id: u['id'] as String,
        name: u['name'] as String,
        kontonummer: u['kontonummer'] as String,
        pin: '',
        email: u['email'] as String? ?? '',
        adresse: u['adresse'] as String? ?? '',
        status: BenutzerStatus.aktiv,
        kundeSeit: DateTime.parse(u['kundeSeit'] as String),
      );
    }

    if (g != null) {
      MockData.girokonto = Girokonto(
        id: g['id'] as String,
        iban: g['iban'] as String,
        bic: g['bic'] as String,
        kontonummer: g['kontonummer'] as String,
        saldo: (g['saldo'] as num).toDouble(),
        verfuegbar: (g['verfuegbar'] as num).toDouble(),
        ueberziehungsrahmen: (g['ueberziehungsrahmen'] as num).toDouble(),
      );
    }

    if (v != null) {
      MockData.visaKarte = VisaKarte(
        id: v['id'] as String,
        kartenNummer: v['kartenNummer'] as String,
        ablaufdatum: v['ablaufdatum'] as String,
        karteninhaber: v['karteninhaber'] as String,
        kreditlimit: (v['kreditlimit'] as num).toDouble(),
        aktuellerSaldo: (v['aktuellerSaldo'] as num).toDouble(),
        unbezahlt: (v['unbezahlt'] as num).toDouble(),
        abrechnungsperiodeBeginn: DateTime.parse(v['abrechnungsperiodeBeginn'] as String),
        abrechnungsperiodeEnde: DateTime.parse(v['abrechnungsperiodeEnde'] as String),
        status: (v['gesperrt'] == true) ? KartenStatus.gesperrt : KartenStatus.aktiv,
      );
    }
  }

  Future<void> _loadAllData() async {
    await Future.wait([
      _loadUmsaetze(),
      _loadBeneficiaries(),
      _loadDauerauftraege(),
    ]);
  }

  Future<void> _loadUmsaetze() async {
    try {
      final giro = await ApiService.instance.getTransactions(type: 'girokonto');
      final visa = await ApiService.instance.getTransactions(type: 'visa');

      final giroList = (giro['umsaetze'] as List? ?? [])
          .map((j) => _umsatzFromJson(j as Map<String, dynamic>, 'giro-001', 'girokonto'))
          .toList();
      final visaList = (visa['umsaetze'] as List? ?? [])
          .map((j) => _umsatzFromJson(j as Map<String, dynamic>, 'visa-001', 'visa'))
          .toList();

      MockData.umsaetze = [...giroList, ...visaList];
    } catch (_) {}
  }

  Future<void> _loadBeneficiaries() async {
    try {
      final result = await ApiService.instance.getBeneficiaries();
      MockData.beneficiaries = (result['beneficiaries'] as List? ?? [])
          .map((j) => _beneficiaryFromJson(j as Map<String, dynamic>))
          .toList();
    } catch (_) {}
  }

  Future<void> _loadDauerauftraege() async {
    try {
      final result = await ApiService.instance.getDauerauftraege();
      MockData.dauerauftraege = (result['dauerauftraege'] as List? ?? [])
          .map((j) => _dauerauftragFromJson(j as Map<String, dynamic>))
          .toList();
    } catch (_) {}
  }

  // ── Transfers ─────────────────────────────────────────────────────────────

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

    // Sync to DB in background
    ApiService.instance.transfer(
      empfaenger: empfaengerName,
      iban: iban,
      bic: bic,
      betrag: betrag,
      verwendungszweck: verwendungszweck,
      buchungsdatum: now.toIso8601String(),
    ).then((result) {
      if (result['statusCode'] == 200 && result['girokonto'] != null) {
        final g = result['girokonto'] as Map<String, dynamic>;
        MockData.girokonto.saldo = (g['saldo'] as num).toDouble();
        MockData.girokonto.verfuegbar = (g['verfuegbar'] as num).toDouble();
        notifyListeners();
      }
    }).catchError((_) {});

    return ref;
  }

  void saldoAktualisieren(double delta) {
    MockData.girokonto.saldo += delta;
    MockData.girokonto.verfuegbar += delta;
    StorageService.saveAll();
    notifyListeners();
  }

  // ── Card ──────────────────────────────────────────────────────────────────

  void karteGefrieren(bool freeze) {
    MockData.visaKarte.status = freeze ? KartenStatus.gesperrt : KartenStatus.aktiv;
    StorageService.saveAll();
    notifyListeners();
  }

  void visaSaldoAktualisieren(double delta) {
    MockData.visaKarte.aktuellerSaldo += delta;
    MockData.visaKarte.unbezahlt += delta;
    StorageService.saveAll();
    notifyListeners();
  }

  // ── Daueraufträge ─────────────────────────────────────────────────────────

  void dauerauftragHinzufuegen(Dauerauftrag d) {
    MockData.dauerauftraege.add(d);
    StorageService.saveAll();
    notifyListeners();

    ApiService.instance.addDauerauftrag(
      empfaengerName: d.empfaengerName,
      iban: d.iban,
      bic: d.bic,
      betrag: d.betrag,
      verwendungszweck: d.verwendungszweck,
      turnus: d.turnus.name,
      naechsteAusfuehrung: d.naechsteAusfuehrung.toIso8601String(),
    ).then((result) {
      if (result['statusCode'] == 201 && result['dauerauftrag'] != null) {
        final dbId = result['dauerauftrag']['id'] as String;
        final idx = MockData.dauerauftraege.indexWhere((x) => x.id == d.id);
        if (idx >= 0) MockData.dauerauftraege[idx].id = dbId;
      }
    }).catchError((_) {});
  }

  void dauerauftragLoeschen(String id) {
    MockData.dauerauftraege.removeWhere((d) => d.id == id);
    StorageService.saveAll();
    notifyListeners();
    ApiService.instance.deleteDauerauftrag(id).catchError((_) {});
  }

  void dauerauftragUmschalten(String id) {
    final idx = MockData.dauerauftraege.indexWhere((d) => d.id == id);
    if (idx >= 0) {
      MockData.dauerauftraege[idx].isAktiv = !MockData.dauerauftraege[idx].isAktiv;
      final isAktiv = MockData.dauerauftraege[idx].isAktiv;
      StorageService.saveAll();
      notifyListeners();
      ApiService.instance.toggleDauerauftrag(id, isAktiv: isAktiv).catchError((_) {});
    }
  }

  // ── Beneficiaries ─────────────────────────────────────────────────────────

  void beneficiaryHinzufuegen(Beneficiary b) {
    MockData.beneficiaries.add(b);
    notifyListeners();

    ApiService.instance.addBeneficiary(
      name: b.name,
      kontonummer: b.kontonummer,
      iban: b.iban,
      bic: b.bic,
    ).then((result) {
      if (result['statusCode'] == 201 && result['beneficiary'] != null) {
        final dbId = result['beneficiary']['id'] as String;
        final idx = MockData.beneficiaries.indexWhere((x) => x.id == b.id);
        if (idx >= 0) MockData.beneficiaries[idx] = Beneficiary(
          id: dbId,
          name: b.name,
          kontonummer: b.kontonummer,
          iban: b.iban,
          bic: b.bic,
          verknuepftAm: b.verknuepftAm,
        );
      }
    }).catchError((_) {});
  }

  void beneficiaryLoeschen(String id) {
    MockData.beneficiaries.removeWhere((b) => b.id == id);
    notifyListeners();
    ApiService.instance.deleteBeneficiary(id).catchError((_) {});
  }

  // ── PIN ───────────────────────────────────────────────────────────────────

  void pinAendern(String neuePin) {
    MockData.user.pin = neuePin;
    StorageService.saveAll();
    notifyListeners();
  }

  // ── IBAN helpers ──────────────────────────────────────────────────────────

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

  // ── Dauerauftrag execution ────────────────────────────────────────────────

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

  // ── JSON → Model helpers ──────────────────────────────────────────────────

  static Umsatz _umsatzFromJson(
      Map<String, dynamic> j, String kontoId, String kontoTyp) {
    return Umsatz(
      id: j['id'] as String,
      kontoId: kontoId,
      kontoTyp: kontoTyp,
      buchungsdatum: DateTime.parse(j['buchungsdatum'] as String),
      wertstellung: DateTime.parse(j['wertstellung'] as String),
      auftraggeber: j['auftraggeber'] as String,
      empfaenger: j['empfaenger'] as String,
      verwendungszweck: j['verwendungszweck'] as String,
      betrag: (j['betrag'] as num).toDouble(),
      typ: (j['typ'] as String) == 'gutschrift'
          ? UmsatzTyp.gutschrift
          : UmsatzTyp.belastung,
      kategorie: _parseKategorie(j['kategorie'] as String?),
      referenznummer: j['referenznummer'] as String?,
    );
  }

  static UmsatzKategorie? _parseKategorie(String? s) {
    if (s == null) return null;
    return UmsatzKategorie.values.where((e) => e.name == s).firstOrNull;
  }

  static Beneficiary _beneficiaryFromJson(Map<String, dynamic> j) {
    return Beneficiary(
      id: j['id'] as String,
      name: j['name'] as String,
      kontonummer: j['kontonummer'] as String,
      iban: j['iban'] as String,
      bic: j['bic'] as String,
      verknuepftAm: DateTime.parse(j['verknuepftAm'] as String),
    );
  }

  static Dauerauftrag _dauerauftragFromJson(Map<String, dynamic> j) {
    return Dauerauftrag(
      id: j['id'] as String,
      vonKontoId: 'giro-001',
      empfaengerName: j['empfaengerName'] as String,
      iban: j['iban'] as String,
      bic: j['bic'] as String,
      betrag: (j['betrag'] as num).toDouble(),
      verwendungszweck: j['verwendungszweck'] as String,
      turnus: Turnus.values.firstWhere(
        (e) => e.name == (j['turnus'] as String),
        orElse: () => Turnus.monatlich,
      ),
      naechsteAusfuehrung: DateTime.parse(j['naechsteAusfuehrung'] as String),
      isAktiv: j['isAktiv'] as bool? ?? true,
    );
  }
}
