import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  List<dynamic> _users = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await ApiService.instance.adminGetUsers();
      if (!mounted) return;
      if (result['statusCode'] == 200) {
        setState(() {
          _users = result['users'] as List;
          _loading = false;
        });
      } else {
        setState(() {
          _error = result['error'] as String? ?? 'Fehler beim Laden';
          _loading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _showDetail(Map<String, dynamic> user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _UserDetailSheet(user: user, onRefresh: _load),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: DkbColors.danger, size: 44),
            const SizedBox(height: 10),
            Text(_error!, style: GoogleFonts.inter(color: DkbColors.danger, fontSize: 14)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _load, child: const Text('Erneut versuchen')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _users.length + 1,
        itemBuilder: (_, i) {
          if (i == 0) {
            return _SectionHeader('${_users.length} Nutzer registriert');
          }
          final u = _users[i - 1] as Map<String, dynamic>;
          final gesperrt = u['gesperrt'] == true;
          final giro = u['girokonto'] as Map<String, dynamic>?;
          final saldo = (giro?['saldo'] as num?)?.toDouble() ?? 0.0;
          final since = DateTime.tryParse(u['kundeSeit'] as String? ?? '') ?? DateTime.now();

          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DkbRadius.md),
              side: BorderSide(
                color: gesperrt ? DkbColors.danger.withValues(alpha: 0.35) : DkbColors.divider,
              ),
            ),
            child: InkWell(
              onTap: () => _showDetail(u),
              borderRadius: BorderRadius.circular(DkbRadius.md),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: gesperrt
                          ? DkbColors.danger.withValues(alpha: 0.1)
                          : DkbColors.primary.withValues(alpha: 0.1),
                      child: Text(
                        ((u['name'] as String?) ?? '?')[0].toUpperCase(),
                        style: GoogleFonts.inter(
                          color: gesperrt ? DkbColors.danger : DkbColors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  u['name'] as String? ?? '',
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: DkbColors.textPrimary,
                                  ),
                                ),
                              ),
                              if (gesperrt)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: DkbColors.danger.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'GESPERRT',
                                    style: GoogleFonts.inter(
                                      color: DkbColors.danger,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            u['kontonummer'] as String? ?? '',
                            style: GoogleFonts.ibmPlexMono(fontSize: 12, color: DkbColors.textSecondary),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Kunde seit ${DateFormat('dd.MM.yyyy').format(since)}',
                            style: GoogleFonts.inter(fontSize: 11, color: DkbColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _fmtEur(saldo),
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: saldo >= 0 ? DkbColors.textPrimary : DkbColors.danger,
                          ),
                        ),
                        Text(
                          'Girokonto',
                          style: GoogleFonts.inter(fontSize: 10, color: DkbColors.textMuted),
                        ),
                        const SizedBox(height: 4),
                        const Icon(Icons.chevron_right, color: DkbColors.textMuted, size: 18),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _fmtEur(double v) => NumberFormat.currency(locale: 'de_DE', symbol: '€').format(v);
}

// ── User detail bottom sheet ───────────────────────────────────────────────

class _UserDetailSheet extends StatefulWidget {
  final Map<String, dynamic> user;
  final VoidCallback onRefresh;

  const _UserDetailSheet({required this.user, required this.onRefresh});

  @override
  State<_UserDetailSheet> createState() => _UserDetailSheetState();
}

class _UserDetailSheetState extends State<_UserDetailSheet> {
  bool _loading = false;

  Future<void> _doAction(String action, {String? newPin}) async {
    setState(() => _loading = true);
    try {
      final result = await ApiService.instance.adminAccountAction(
        userId: widget.user['id'] as String,
        action: action,
        newPin: newPin,
      );
      if (!mounted) return;
      Navigator.pop(context);
      widget.onRefresh();
      final msg = result['message'] as String? ?? 'Aktion ausgeführt';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: DkbColors.success),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler: $e'), backgroundColor: DkbColors.danger),
      );
    }
  }

  void _showResetPinDialog() {
    final pinCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('PIN zurücksetzen', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Neue 4-stellige PIN für ${widget.user['name']}:',
              style: GoogleFonts.inter(fontSize: 14),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: pinCtrl,
              keyboardType: TextInputType.number,
              obscureText: true,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(4),
              ],
              maxLength: 4,
              decoration: const InputDecoration(hintText: '0000', counterText: ''),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () {
              final pin = pinCtrl.text;
              if (pin.length != 4) return;
              Navigator.pop(context);
              _doAction('reset-pin', newPin: pin);
            },
            child: const Text('Zurücksetzen'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final u = widget.user;
    final gesperrt = u['gesperrt'] == true;
    final giro = u['girokonto'] as Map<String, dynamic>?;
    final visa = u['visaKarte'] as Map<String, dynamic>?;
    final since = DateTime.tryParse(u['kundeSeit'] as String? ?? '') ?? DateTime.now();

    return Container(
      decoration: const BoxDecoration(
        color: DkbColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: DkbColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // User header
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: gesperrt
                    ? DkbColors.danger.withValues(alpha: 0.1)
                    : DkbColors.primary.withValues(alpha: 0.1),
                child: Text(
                  ((u['name'] as String?) ?? '?')[0].toUpperCase(),
                  style: GoogleFonts.inter(
                    color: gesperrt ? DkbColors.danger : DkbColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      u['name'] as String? ?? '',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: DkbColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Kto. ${u['kontonummer']}',
                      style: GoogleFonts.ibmPlexMono(fontSize: 12, color: DkbColors.textSecondary),
                    ),
                    if (u['email'] != null)
                      Text(
                        u['email'] as String,
                        style: GoogleFonts.inter(fontSize: 12, color: DkbColors.textMuted),
                      ),
                  ],
                ),
              ),
              if (gesperrt)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: DkbColors.danger.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: DkbColors.danger.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    'GESPERRT',
                    style: GoogleFonts.inter(
                      color: DkbColors.danger,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: DkbColors.divider),
          const SizedBox(height: 12),
          // Account details
          _infoRow('Kunde seit', DateFormat('dd.MM.yyyy').format(since)),
          if (giro != null) ...[
            _infoRow('Girokonto IBAN', giro['iban'] as String? ?? '–'),
            _infoRow('BIC', giro['bic'] as String? ?? '–'),
            _infoRow(
              'Girokonto Saldo',
              _fmtEur((giro['saldo'] as num?)?.toDouble() ?? 0),
            ),
            _infoRow(
              'Verfügbar',
              _fmtEur((giro['verfuegbar'] as num?)?.toDouble() ?? 0),
            ),
          ],
          if (visa != null) ...[
            _infoRow('Visa Nummer', visa['kartenNummer'] as String? ?? '–'),
            _infoRow(
              'Visa Saldo',
              _fmtEur((visa['aktuellerSaldo'] as num?)?.toDouble() ?? 0),
            ),
            _infoRow(
              'Kreditlimit',
              _fmtEur((visa['kreditlimit'] as num?)?.toDouble() ?? 0),
            ),
            _infoRow(
              'Karte Status',
              (visa['gesperrt'] == true) ? 'Gesperrt' : 'Aktiv',
            ),
          ],
          const SizedBox(height: 20),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: Icon(
                      gesperrt ? Icons.lock_open_outlined : Icons.lock_outline,
                      size: 16,
                    ),
                    label: Text(gesperrt ? 'Aktivieren' : 'Sperren'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: gesperrt ? DkbColors.success : DkbColors.danger,
                      side: BorderSide(color: gesperrt ? DkbColors.success : DkbColors.danger),
                    ),
                    onPressed: () => _doAction(gesperrt ? 'activate' : 'suspend'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.key_outlined, size: 16),
                    label: const Text('PIN reset'),
                    onPressed: _showResetPinDialog,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 7),
        child: Row(
          children: [
            SizedBox(
              width: 140,
              child: Text(
                label,
                style: GoogleFonts.inter(fontSize: 12, color: DkbColors.textMuted),
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: DkbColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );

  String _fmtEur(double v) => NumberFormat.currency(locale: 'de_DE', symbol: '€').format(v);
}

// ── Section header widget ──────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: DkbColors.textSecondary,
          ),
        ),
      );
}
