import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/mock_data.dart';
import '../models/girokonto.dart';
import '../models/visa_karte.dart';
import '../models/umsatz.dart';
import '../models/dauerauftrag.dart';

class StorageService {
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static Future<void> saveAll() async {
    if (_prefs == null) return;
    try {
      await _prefs!.setString('dkb_girokonto', jsonEncode(MockData.girokonto.toJson()));
      await _prefs!.setString('dkb_visa', jsonEncode(MockData.visaKarte.toJson()));
      await _prefs!.setString(
        'dkb_umsaetze',
        jsonEncode(MockData.umsaetze.map((u) => u.toJson()).toList()),
      );
      await _prefs!.setString(
        'dkb_dauerauftraege',
        jsonEncode(MockData.dauerauftraege.map((d) => d.toJson()).toList()),
      );
      await _prefs!.setString('dkb_pin', MockData.user.pin);
    } catch (_) {}
  }

  static Future<void> loadAll() async {
    if (_prefs == null) return;
    try {
      final giroJson = _prefs!.getString('dkb_girokonto');
      if (giroJson != null) {
        final data = jsonDecode(giroJson) as Map<String, dynamic>;
        MockData.girokonto = Girokonto.fromJson(data);
      }

      final visaJson = _prefs!.getString('dkb_visa');
      if (visaJson != null) {
        final data = jsonDecode(visaJson) as Map<String, dynamic>;
        MockData.visaKarte = VisaKarte.fromJson(data);
      }

      final umsaetzeJson = _prefs!.getString('dkb_umsaetze');
      if (umsaetzeJson != null) {
        final list = jsonDecode(umsaetzeJson) as List<dynamic>;
        MockData.umsaetze = list
            .map((e) => Umsatz.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      final dauerJson = _prefs!.getString('dkb_dauerauftraege');
      if (dauerJson != null) {
        final list = jsonDecode(dauerJson) as List<dynamic>;
        MockData.dauerauftraege = list
            .map((e) => Dauerauftrag.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      final pin = _prefs!.getString('dkb_pin');
      if (pin != null) MockData.user.pin = pin;
    } catch (_) {}
  }

  static Future<void> saveSession(String kontonummer) async {
    await _prefs?.setString('dkb_session', kontonummer);
  }

  static String? loadSession() => _prefs?.getString('dkb_session');

  static Future<void> clearSession() async {
    await _prefs?.remove('dkb_session');
  }

  static bool get hasData => _prefs?.containsKey('dkb_girokonto') ?? false;
}
