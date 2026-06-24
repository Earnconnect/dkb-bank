import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  ApiService._();
  static final ApiService instance = ApiService._();

  String? _token;

  static String get baseUrl {
    if (kIsWeb) {
      final b = Uri.base;
      final port = b.port;
      final p = (port != 0 && port != 80 && port != 443) ? ':$port' : '';
      return '${b.scheme}://${b.host}$p/.netlify/functions';
    }
    return 'http://localhost:8888/.netlify/functions';
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('api_token');
  }

  Future<void> _saveToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('api_token', token);
  }

  Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('api_token');
  }

  bool get hasToken => _token != null;

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  Future<Map<String, dynamic>> _parse(http.Response r) async {
    final data = jsonDecode(r.body) as Map<String, dynamic>;
    return {'statusCode': r.statusCode, ...data};
  }

  Future<Map<String, dynamic>> login(String kontonummer, String pin) async {
    final r = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: _headers,
      body: jsonEncode({'kontonummer': kontonummer, 'pin': pin}),
    );
    final data = await _parse(r);
    if (r.statusCode == 200) await _saveToken(data['token'] as String);
    return data;
  }

  Future<Map<String, dynamic>> me() async {
    final r = await http.get(Uri.parse('$baseUrl/me'), headers: _headers);
    return _parse(r);
  }

  Future<Map<String, dynamic>> getTransactions({String type = 'girokonto'}) async {
    final r = await http.get(
      Uri.parse('$baseUrl/transactions?type=$type'),
      headers: _headers,
    );
    return _parse(r);
  }

  Future<Map<String, dynamic>> transfer({
    required String empfaenger,
    required String iban,
    required String bic,
    required double betrag,
    required String verwendungszweck,
    required String buchungsdatum,
  }) async {
    final r = await http.post(
      Uri.parse('$baseUrl/transfer'),
      headers: _headers,
      body: jsonEncode({
        'empfaenger': empfaenger,
        'iban': iban,
        'bic': bic,
        'betrag': betrag,
        'verwendungszweck': verwendungszweck,
        'buchungsdatum': buchungsdatum,
      }),
    );
    return _parse(r);
  }

  Future<Map<String, dynamic>> getBeneficiaries() async {
    final r = await http.get(Uri.parse('$baseUrl/beneficiaries'), headers: _headers);
    return _parse(r);
  }

  Future<Map<String, dynamic>> addBeneficiary({
    required String name,
    required String kontonummer,
    required String iban,
    required String bic,
  }) async {
    final r = await http.post(
      Uri.parse('$baseUrl/beneficiaries'),
      headers: _headers,
      body: jsonEncode({'name': name, 'kontonummer': kontonummer, 'iban': iban, 'bic': bic}),
    );
    return _parse(r);
  }

  Future<Map<String, dynamic>> deleteBeneficiary(String id) async {
    final r = await http.delete(
      Uri.parse('$baseUrl/beneficiaries?id=$id'),
      headers: _headers,
    );
    return _parse(r);
  }

  Future<Map<String, dynamic>> getDauerauftraege() async {
    final r = await http.get(Uri.parse('$baseUrl/dauerauftraege'), headers: _headers);
    return _parse(r);
  }

  Future<Map<String, dynamic>> addDauerauftrag({
    required String empfaengerName,
    required String iban,
    required String bic,
    required double betrag,
    required String verwendungszweck,
    required String turnus,
    required String naechsteAusfuehrung,
  }) async {
    final r = await http.post(
      Uri.parse('$baseUrl/dauerauftraege'),
      headers: _headers,
      body: jsonEncode({
        'empfaengerName': empfaengerName,
        'iban': iban,
        'bic': bic,
        'betrag': betrag,
        'verwendungszweck': verwendungszweck,
        'turnus': turnus,
        'naechsteAusfuehrung': naechsteAusfuehrung,
      }),
    );
    return _parse(r);
  }

  Future<Map<String, dynamic>> deleteDauerauftrag(String id) async {
    final r = await http.delete(
      Uri.parse('$baseUrl/dauerauftraege?id=$id'),
      headers: _headers,
    );
    return _parse(r);
  }

  Future<Map<String, dynamic>> toggleDauerauftrag(String id, {required bool isAktiv}) async {
    final r = await http.put(
      Uri.parse('$baseUrl/dauerauftraege?id=$id'),
      headers: _headers,
      body: jsonEncode({'isAktiv': isAktiv}),
    );
    return _parse(r);
  }

  Future<Map<String, dynamic>> seed() async {
    final r = await http.post(Uri.parse('$baseUrl/seed'), headers: _headers);
    return _parse(r);
  }
}
