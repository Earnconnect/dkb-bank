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
  final _amountCtrl = TextEditingController();
  bool _submitting = false;
  Map<String, dynamic>? _result;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
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
        final list = res['users'] as List;
        setState(() {
          _users = list;
          _loadingUsers = false;
          if (list.isNotEmpty) _selectedUserId = (list[0] as Map)['id'] as String;
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

  Map<String, dynamic>? get _selectedUser {
    if (_selectedUserId == null) return null;
    try {
      return _users.firstWhere((u) => (u as Map)['id'] == _selectedUserId)
          as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> _submit() async {
    final amtStr = _amountCtrl.text.replaceAll('.', '').replaceAll(',', '.').trim();
    final amount = double.tryParse(amtStr);
    if (_selectedUserId == null) {
      _snack('Bitte einen Nutzer auswählen', isError: true);
      return;
    }
    if (amount == null || amount <= 0) {
      _snack('Gültigen Betrag eingeben', isError: true);
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
          _amountCtrl.clear();
        });
        await _loadUsers(); // refresh balances
      } else {
        _snack(res['error'] as String? ?? 'Fehler', isError: true);
        setState(() => _submitting = false);
      }
    } catch (e) {
      if (!mounted) return;
      _snack(e.toString(), isError: true);
      setState(() => _submitting = false);
    }
  }

  void _snack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? DkbColors.danger : DkbColors.success,
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingUsers) return const Center(child: CircularProgressIndicator());
    if (_loadError != null) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.error_outline, color: DkbColors.danger, size: 44),
          const SizedBox(height: 10),
          Text(_loadError!, style: GoogleFonts.inter(color: DkbColors.danger)),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _loadUsers, child: const Text('Erneut versuchen')),
        ]),
      );
    }

    final user = _selectedUser;
    final giro = user?['girokonto'] as Map<String, dynamic>?;
    final visa = user?['visaKarte'] as Map<String, dynamic>?;
    final giroSaldo = (giro?['saldo'] as num?)?.toDouble() ?? 0;
    final visaSaldo = (visa?['aktuellerSaldo'] as num?)?.toDouble() ?? 0;

    final isAdding = _operation == 'add';
    final opColor = isAdding ? DkbColors.success : DkbColors.danger;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Page header ──────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E3060), Color(0xFF0D1A36)],
              ),
              borderRadius: BorderRadius.circular(DkbRadius.md),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: DkbColors.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(DkbRadius.sm),
                  ),
                  child: const Icon(Icons.account_balance_wallet_rounded,
                      color: DkbColors.accent, size: 24),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Geldverwaltung',
                        style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700)),
                    Text('Guthaben auf Nutzerkonten anpassen',
                        style: GoogleFonts.inter(
                            color: Colors.white.withValues(alpha: 0.55), fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          LayoutBuilder(builder: (ctx, c) {
            final isWide = c.maxWidth > 600;
            if (isWide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _formCard(giroSaldo, visaSaldo, isAdding, opColor)),
                  const SizedBox(width: 16),
                  SizedBox(width: 240, child: _sidePanel(user, giroSaldo, visaSaldo)),
                ],
              );
            }
            return Column(
              children: [
                _formCard(giroSaldo, visaSaldo, isAdding, opColor),
                const SizedBox(height: 16),
                _sidePanel(user, giroSaldo, visaSaldo),
              ],
            );
          }),

          // ── Result ───────────────────────────────────────────────────────
          if (_result != null) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: DkbColors.success.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(DkbRadius.md),
                border: Border.all(color: DkbColors.success.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.check_circle_rounded,
                          color: DkbColors.success, size: 18),
                      const SizedBox(width: 8),
                      Text('Transaktion erfolgreich',
                          style: GoogleFonts.inter(
                              color: DkbColors.success,
                              fontWeight: FontWeight.w700,
                              fontSize: 14)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (_result!['kontoType'] == 'girokonto') ...[
                    _resultRow('Neuer Girokonto Saldo',
                        _fmtEur((_result!['saldo'] as num?)?.toDouble() ?? 0)),
                    _resultRow('Verfügbar',
                        _fmtEur((_result!['verfuegbar'] as num?)?.toDouble() ?? 0)),
                  ] else ...[
                    _resultRow('Neuer Visa Saldo',
                        _fmtEur((_result!['aktuellerSaldo'] as num?)?.toDouble() ?? 0)),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _formCard(double giroSaldo, double visaSaldo, bool isAdding, Color opColor) {
    return Container(
      decoration: BoxDecoration(
        color: DkbColors.surface,
        borderRadius: BorderRadius.circular(DkbRadius.md),
        border: Border.all(color: DkbColors.divider),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _fieldLabel('Nutzer'),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedUserId,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.person_outline, color: DkbColors.textMuted, size: 18),
              isDense: true,
            ),
            items: _users.map((u) {
              final m = u as Map<String, dynamic>;
              return DropdownMenuItem<String>(
                value: m['id'] as String,
                child: Text('${m['name']}  (${m['kontonummer']})',
                    style: GoogleFonts.inter(fontSize: 13),
                    overflow: TextOverflow.ellipsis),
              );
            }).toList(),
            onChanged: (v) => setState(() {
              _selectedUserId = v;
              _result = null;
            }),
          ),

          const SizedBox(height: 18),
          _fieldLabel('Konto'),
          const SizedBox(height: 8),
          _toggle(
            options: ['Girokonto', 'DKB-Visa'],
            values: ['girokonto', 'visa'],
            selected: _kontoType,
            onSelect: (v) => setState(() {
              _kontoType = v;
              _result = null;
            }),
          ),

          const SizedBox(height: 18),
          _fieldLabel('Aktion'),
          const SizedBox(height: 8),
          _toggle(
            options: ['Einzahlen', 'Abziehen'],
            values: ['add', 'remove'],
            selected: _operation,
            onSelect: (v) => setState(() {
              _operation = v;
              _result = null;
            }),
            activeColor: _operation == 'add' ? DkbColors.success : DkbColors.danger,
          ),

          const SizedBox(height: 18),
          _fieldLabel('Betrag'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _amountCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d,.]'))],
            onChanged: (_) => setState(() => _result = null),
            decoration: InputDecoration(
              hintText: '0,00',
              prefixIcon: const Icon(Icons.euro_rounded, color: DkbColors.textMuted, size: 18),
              suffixText: '€',
              suffixStyle: GoogleFonts.inter(color: DkbColors.textSecondary),
            ),
          ),

          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _submitting ? null : _submit,
              icon: Icon(
                  isAdding ? Icons.add_circle_outline_rounded : Icons.remove_circle_outline_rounded,
                  size: 18),
              label: _submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                  : Text(isAdding ? 'Einzahlen' : 'Abziehen',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15)),
              style: ElevatedButton.styleFrom(
                backgroundColor: opColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sidePanel(Map<String, dynamic>? user, double giroSaldo, double visaSaldo) {
    return Container(
      decoration: BoxDecoration(
        color: DkbColors.surface,
        borderRadius: BorderRadius.circular(DkbRadius.md),
        border: Border.all(color: DkbColors.divider),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Aktuelle Stände',
              style: GoogleFonts.inter(
                  fontSize: 13, fontWeight: FontWeight.w600, color: DkbColors.textSecondary)),
          const SizedBox(height: 14),
          if (user == null)
            Text('Nutzer auswählen',
                style: GoogleFonts.inter(color: DkbColors.textMuted, fontSize: 13))
          else ...[
            _balRow(
              Icons.account_balance_rounded,
              DkbColors.primary,
              'Girokonto',
              _fmtEur(giroSaldo),
              selected: _kontoType == 'girokonto',
            ),
            const SizedBox(height: 10),
            _balRow(
              Icons.credit_card_rounded,
              DkbColors.accent,
              'DKB-Visa',
              _fmtEur(visaSaldo),
              selected: _kontoType == 'visa',
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: DkbColors.background,
                borderRadius: BorderRadius.circular(DkbRadius.sm),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      size: 14, color: DkbColors.textMuted),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '"Einzahlen" erhöht das Guthaben. "Abziehen" reduziert es.',
                      style: GoogleFonts.inter(fontSize: 11, color: DkbColors.textMuted),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _balRow(IconData icon, Color color, String label, String value,
      {bool selected = false}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: selected ? color.withValues(alpha: 0.06) : DkbColors.background,
        borderRadius: BorderRadius.circular(DkbRadius.sm),
        border: Border.all(
            color: selected ? color.withValues(alpha: 0.25) : DkbColors.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style:
                        GoogleFonts.inter(fontSize: 11, color: DkbColors.textMuted)),
                Text(value,
                    style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: DkbColors.textPrimary)),
              ],
            ),
          ),
          if (selected)
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
        ],
      ),
    );
  }

  Widget _toggle({
    required List<String> options,
    required List<String> values,
    required String selected,
    required void Function(String) onSelect,
    Color? activeColor,
  }) =>
      Row(
        children: List.generate(options.length, (i) {
          final isActive = selected == values[i];
          final color = activeColor ??
              (isActive ? DkbColors.primary : DkbColors.textMuted);
          return Expanded(
            child: GestureDetector(
              onTap: () => onSelect(values[i]),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                margin: EdgeInsets.only(right: i < options.length - 1 ? 8 : 0),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isActive ? color.withValues(alpha: 0.1) : DkbColors.background,
                  borderRadius: BorderRadius.circular(DkbRadius.sm),
                  border: Border.all(
                    color: isActive ? color : DkbColors.divider,
                    width: isActive ? 1.5 : 1,
                  ),
                ),
                child: Center(
                  child: Text(options[i],
                      style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                          color: isActive ? color : DkbColors.textMuted)),
                ),
              ),
            ),
          );
        }),
      );

  Widget _fieldLabel(String t) => Text(t,
      style: GoogleFonts.inter(
          fontSize: 12, fontWeight: FontWeight.w600, color: DkbColors.textSecondary));

  Widget _resultRow(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          children: [
            Text(label,
                style: GoogleFonts.inter(fontSize: 12, color: DkbColors.textSecondary)),
            const Spacer(),
            Text(value,
                style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: DkbColors.textPrimary)),
          ],
        ),
      );

  String _fmtEur(double v) =>
      NumberFormat.currency(locale: 'de_DE', symbol: '€').format(v);
}
