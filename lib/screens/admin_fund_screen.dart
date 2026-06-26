import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';

class AdminFundScreen extends StatefulWidget {
  const AdminFundScreen({super.key});

  @override
  State<AdminFundScreen> createState() => _AdminFundScreenState();
}

class _AdminFundScreenState extends State<AdminFundScreen> {
  List<dynamic> _users = [];
  bool _loadingUsers = true;
  String? _loadError;

  String? _selectedUserId;
  String _kontoType = 'girokonto';
  String _operation = 'add';
  final _amountController = TextEditingController();
  bool _submitting = false;
  Map<String, dynamic>? _result;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _loadingUsers = true;
      _loadError = null;
    });
    try {
      final res = await ApiService.instance.adminGetUsers();
      if (!mounted) return;
      if (res['statusCode'] == 200) {
        setState(() {
          _users = res['users'] as List;
          _loadingUsers = false;
          if (_users.isNotEmpty) {
            _selectedUserId = _users[0]['id'] as String;
          }
        });
      } else {
        setState(() {
          _loadError = res['error'] as String? ?? 'Fehler';
          _loadingUsers = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.toString();
        _loadingUsers = false;
      });
    }
  }

  Future<void> _submit() async {
    final amtStr = _amountController.text.replaceAll(',', '.').trim();
    final amount = double.tryParse(amtStr);
    if (_selectedUserId == null) {
      _showError('Bitte einen Nutzer auswählen');
      return;
    }
    if (amount == null || amount <= 0) {
      _showError('Gültigen Betrag eingeben');
      return;
    }

    setState(() {
      _submitting = true;
      _result = null;
    });

    try {
      final res = await ApiService.instance.adminFund(
        userId: _selectedUserId!,
        amount: amount,
        operation: _operation,
        kontoType: _kontoType,
      );
      if (!mounted) return;
      if (res['statusCode'] == 200) {
        setState(() {
          _result = res;
          _submitting = false;
          _amountController.clear();
        });
      } else {
        _showError(res['error'] as String? ?? 'Fehler');
        setState(() => _submitting = false);
      }
    } catch (e) {
      if (!mounted) return;
      _showError(e.toString());
      setState(() => _submitting = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: DkbColors.danger),
    );
  }

  Map<String, dynamic>? get _selectedUser {
    if (_selectedUserId == null) return null;
    try {
      return _users.firstWhere((u) => (u as Map)['id'] == _selectedUserId) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingUsers) return const Center(child: CircularProgressIndicator());
    if (_loadError != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: DkbColors.danger, size: 44),
            const SizedBox(height: 10),
            Text(_loadError!, style: GoogleFonts.inter(color: DkbColors.danger)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadUsers, child: const Text('Erneut versuchen')),
          ],
        ),
      );
    }

    final user = _selectedUser;
    final giro = user?['girokonto'] as Map<String, dynamic>?;
    final visa = user?['visaKarte'] as Map<String, dynamic>?;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('Geldverwaltung'),
          const SizedBox(height: 4),
          Text(
            'Guthaben auf Nutzerkonten hinzufügen oder abziehen',
            style: GoogleFonts.inter(fontSize: 12, color: DkbColors.textMuted),
          ),
          const SizedBox(height: 20),

          // User selector
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _fieldLabel('Nutzer auswählen'),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedUserId,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.person_outline, color: DkbColors.textMuted),
                  ),
                  items: _users.map((u) {
                    final user = u as Map<String, dynamic>;
                    return DropdownMenuItem<String>(
                      value: user['id'] as String,
                      child: Text(
                        '${user['name']}  (${user['kontonummer']})',
                        style: GoogleFonts.inter(fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (v) => setState(() {
                    _selectedUserId = v;
                    _result = null;
                  }),
                ),
                if (user != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: DkbColors.background,
                      borderRadius: BorderRadius.circular(DkbRadius.sm),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _balChip(
                            'Girokonto',
                            _fmtEur((giro?['saldo'] as num?)?.toDouble() ?? 0),
                            DkbColors.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _balChip(
                            'Visa Saldo',
                            _fmtEur((visa?['aktuellerSaldo'] as num?)?.toDouble() ?? 0),
                            DkbColors.accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Account type + operation
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _fieldLabel('Konto'),
                const SizedBox(height: 8),
                _toggleRow(
                  options: const ['Girokonto', 'Visa'],
                  values: const ['girokonto', 'visa'],
                  selected: _kontoType,
                  onSelect: (v) => setState(() { _kontoType = v; _result = null; }),
                ),
                const SizedBox(height: 14),
                _fieldLabel('Aktion'),
                const SizedBox(height: 8),
                _toggleRow(
                  options: const ['Einzahlen', 'Abziehen'],
                  values: const ['add', 'remove'],
                  selected: _operation,
                  onSelect: (v) => setState(() { _operation = v; _result = null; }),
                  activeAddColor: _operation == 'add' ? DkbColors.success : DkbColors.danger,
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Amount
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _fieldLabel('Betrag (€)'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d,.]')),
                  ],
                  decoration: InputDecoration(
                    hintText: '0,00',
                    prefixIcon: const Icon(Icons.euro, color: DkbColors.textMuted),
                    suffixText: '€',
                    suffixStyle: GoogleFonts.inter(color: DkbColors.textSecondary),
                  ),
                  onChanged: (_) => setState(() => _result = null),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Submit
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: _operation == 'add' ? DkbColors.success : DkbColors.danger,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                    )
                  : Text(
                      _operation == 'add' ? 'Betrag einzahlen' : 'Betrag abziehen',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15),
                    ),
            ),
          ),

          // Result
          if (_result != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: DkbColors.success.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(DkbRadius.md),
                border: Border.all(color: DkbColors.success.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.check_circle_outline, color: DkbColors.success, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Transaktion erfolgreich',
                        style: GoogleFonts.inter(
                          color: DkbColors.success,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (_result!['kontoType'] == 'girokonto') ...[
                    _resultRow('Neuer Saldo', _fmtEur((_result!['saldo'] as num?)?.toDouble() ?? 0)),
                    _resultRow('Verfügbar', _fmtEur((_result!['verfuegbar'] as num?)?.toDouble() ?? 0)),
                  ] else ...[
                    _resultRow('Visa Saldo', _fmtEur((_result!['aktuellerSaldo'] as num?)?.toDouble() ?? 0)),
                    _resultRow('Kreditlimit', _fmtEur((_result!['kreditlimit'] as num?)?.toDouble() ?? 0)),
                  ],
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) => Container(
        decoration: BoxDecoration(
          color: DkbColors.surface,
          borderRadius: BorderRadius.circular(DkbRadius.md),
          border: Border.all(color: DkbColors.divider),
        ),
        padding: const EdgeInsets.all(16),
        child: child,
      );

  Widget _sectionLabel(String t) => Text(
        t,
        style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: DkbColors.textPrimary),
      );

  Widget _fieldLabel(String t) => Text(
        t,
        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: DkbColors.textSecondary),
      );

  Widget _toggleRow({
    required List<String> options,
    required List<String> values,
    required String selected,
    required void Function(String) onSelect,
    Color? activeAddColor,
  }) =>
      Row(
        children: List.generate(options.length, (i) {
          final isSelected = selected == values[i];
          final color = isSelected
              ? (activeAddColor != null && i == 0
                  ? (selected == 'add' ? DkbColors.success : DkbColors.danger)
                  : DkbColors.primary)
              : DkbColors.textMuted;
          return Expanded(
            child: GestureDetector(
              onTap: () => onSelect(values[i]),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: EdgeInsets.only(right: i == 0 ? 6 : 0),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? color.withValues(alpha: 0.1) : DkbColors.background,
                  borderRadius: BorderRadius.circular(DkbRadius.sm),
                  border: Border.all(
                    color: isSelected ? color : DkbColors.divider,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    options[i],
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                      color: isSelected ? color : DkbColors.textMuted,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      );

  Widget _balChip(String label, String value, Color color) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 10, color: DkbColors.textMuted)),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: color),
          ),
        ],
      );

  Widget _resultRow(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          children: [
            Text(label, style: GoogleFonts.inter(fontSize: 12, color: DkbColors.textSecondary)),
            const Spacer(),
            Text(
              value,
              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: DkbColors.textPrimary),
            ),
          ],
        ),
      );

  String _fmtEur(double v) => NumberFormat.currency(locale: 'de_DE', symbol: '€').format(v);
}
