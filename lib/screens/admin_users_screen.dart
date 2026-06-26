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
  String _search = '';

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
      final res = await ApiService.instance.adminGetUsers();
      if (!mounted) return;
      if (res['statusCode'] == 200) {
        setState(() {
          _users = res['users'] as List;
          _loading = false;
        });
      } else {
        setState(() {
          _error = res['error'] as String? ?? 'Fehler';
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

  List<dynamic> get _filtered {
    if (_search.isEmpty) return _users;
    final q = _search.toLowerCase();
    return _users.where((u) {
      final m = u as Map<String, dynamic>;
      return (m['name'] as String? ?? '').toLowerCase().contains(q) ||
          (m['kontonummer'] as String? ?? '').contains(q) ||
          (m['email'] as String? ?? '').toLowerCase().contains(q);
    }).toList();
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
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.error_outline, color: DkbColors.danger, size: 44),
          const SizedBox(height: 10),
          Text(_error!, style: GoogleFonts.inter(color: DkbColors.danger, fontSize: 14)),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _load, child: const Text('Erneut versuchen')),
        ]),
      );
    }

    final filtered = _filtered;
    final suspended = _users.where((u) => (u as Map)['gesperrt'] == true).length;

    return Column(
      children: [
        // ── Header bar ───────────────────────────────────────────────────
        Container(
          color: DkbColors.surface,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: DkbColors.divider, width: 1)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (v) => setState(() => _search = v),
                  decoration: InputDecoration(
                    hintText: 'Name oder Kontonummer suchen…',
                    prefixIcon: const Icon(Icons.search_rounded, size: 18),
                    suffixIcon: _search.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 16),
                            onPressed: () => setState(() => _search = ''),
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    filled: true,
                    fillColor: DkbColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(DkbRadius.sm),
                      borderSide: BorderSide.none,
                    ),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _statChip('${_users.length} Gesamt', DkbColors.primary),
              const SizedBox(width: 6),
              if (suspended > 0) _statChip('$suspended Gesperrt', DkbColors.danger),
            ],
          ),
        ),

        // ── User list ─────────────────────────────────────────────────────
        Expanded(
          child: RefreshIndicator(
            onRefresh: _load,
            child: filtered.isEmpty
                ? Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.search_off_rounded, size: 44, color: DkbColors.textMuted),
                      const SizedBox(height: 8),
                      Text('Keine Nutzer gefunden',
                          style: GoogleFonts.inter(color: DkbColors.textMuted, fontSize: 14)),
                    ]),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final u = filtered[i] as Map<String, dynamic>;
                      return _UserRow(user: u, onTap: () => _showDetail(u), onRefresh: _load);
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _statChip(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Text(label,
            style: GoogleFonts.inter(
                color: color, fontSize: 11, fontWeight: FontWeight.w600)),
      );
}

// ── User Row ──────────────────────────────────────────────────────────────

class _UserRow extends StatefulWidget {
  final Map<String, dynamic> user;
  final VoidCallback onTap;
  final VoidCallback onRefresh;

  const _UserRow({required this.user, required this.onTap, required this.onRefresh});

  @override
  State<_UserRow> createState() => _UserRowState();
}

class _UserRowState extends State<_UserRow> {
  bool _actionLoading = false;

  Future<void> _quickAction(String action) async {
    setState(() => _actionLoading = true);
    try {
      final res = await ApiService.instance.adminAccountAction(
        userId: widget.user['id'] as String,
        action: action,
      );
      if (!mounted) return;
      widget.onRefresh();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] as String? ?? 'Fertig'),
          backgroundColor: DkbColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler: $e'), backgroundColor: DkbColors.danger),
      );
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final u = widget.user;
    final gesperrt = u['gesperrt'] == true;
    final giro = u['girokonto'] as Map<String, dynamic>?;
    final visa = u['visaKarte'] as Map<String, dynamic>?;
    final saldo = (giro?['saldo'] as num?)?.toDouble() ?? 0.0;
    final visaGesperrt = visa?['gesperrt'] == true;
    final since = DateTime.tryParse(u['kundeSeit'] as String? ?? '') ?? DateTime.now();
    final initial = ((u['name'] as String?) ?? '?')[0].toUpperCase();

    return Container(
      decoration: BoxDecoration(
        color: DkbColors.surface,
        borderRadius: BorderRadius.circular(DkbRadius.md),
        border: Border.all(
          color: gesperrt ? DkbColors.danger.withValues(alpha: 0.3) : DkbColors.divider,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(DkbRadius.md),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(DkbRadius.md),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 21,
                  backgroundColor: gesperrt
                      ? DkbColors.danger.withValues(alpha: 0.1)
                      : DkbColors.primary.withValues(alpha: 0.08),
                  child: Text(initial,
                      style: GoogleFonts.inter(
                          color: gesperrt ? DkbColors.danger : DkbColors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 15)),
                ),
                const SizedBox(width: 12),

                // Name + meta
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(u['name'] as String? ?? '',
                                style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: DkbColors.textPrimary)),
                          ),
                          if (gesperrt) _badge('KONTO GESPERRT', DkbColors.danger),
                          if (!gesperrt && visaGesperrt) _badge('KARTE GESPERRT', DkbColors.warning),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Text(u['kontonummer'] as String? ?? '',
                              style: GoogleFonts.ibmPlexMono(
                                  fontSize: 11, color: DkbColors.textSecondary)),
                          const SizedBox(width: 8),
                          Text('·',
                              style:
                                  GoogleFonts.inter(color: DkbColors.textMuted, fontSize: 11)),
                          const SizedBox(width: 8),
                          Text('Seit ${DateFormat('MM/yyyy').format(since)}',
                              style: GoogleFonts.inter(
                                  fontSize: 11, color: DkbColors.textMuted)),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                // Balance + actions
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      NumberFormat.currency(locale: 'de_DE', symbol: '€').format(saldo),
                      style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: saldo >= 0 ? DkbColors.textPrimary : DkbColors.danger),
                    ),
                    Text('Girokonto',
                        style: GoogleFonts.inter(fontSize: 10, color: DkbColors.textMuted)),
                    const SizedBox(height: 6),
                    if (_actionLoading)
                      const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2))
                    else
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _iconBtn(
                            icon: gesperrt
                                ? Icons.lock_open_rounded
                                : Icons.lock_outline_rounded,
                            color: gesperrt ? DkbColors.success : DkbColors.danger,
                            tooltip: gesperrt ? 'Aktivieren' : 'Sperren',
                            onTap: () => _quickAction(gesperrt ? 'activate' : 'suspend'),
                          ),
                          const SizedBox(width: 4),
                          _iconBtn(
                            icon: Icons.info_outline_rounded,
                            color: DkbColors.accent,
                            tooltip: 'Details',
                            onTap: widget.onTap,
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _badge(String text, Color color) => Container(
        margin: const EdgeInsets.only(left: 6),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Text(text,
            style: GoogleFonts.inter(
                color: color, fontSize: 8, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
      );

  Widget _iconBtn({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onTap,
  }) =>
      Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 15, color: color),
          ),
        ),
      );
}

// ── User Detail Bottom Sheet ───────────────────────────────────────────────

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
      final res = await ApiService.instance.adminAccountAction(
        userId: widget.user['id'] as String,
        action: action,
        newPin: newPin,
      );
      if (!mounted) return;
      Navigator.pop(context);
      widget.onRefresh();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] as String? ?? 'Fertig'),
          backgroundColor: DkbColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler: $e'), backgroundColor: DkbColors.danger),
      );
    }
  }

  void _showPinReset() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title:
            Text('PIN zurücksetzen', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Neue 4-stellige PIN für ${widget.user['name']}:',
                style: GoogleFonts.inter(fontSize: 14)),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 4,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(4),
              ],
              decoration: const InputDecoration(hintText: '0000', counterText: ''),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text('Abbrechen')),
          ElevatedButton(
            onPressed: () {
              if (ctrl.text.length != 4) return;
              Navigator.pop(context);
              _doAction('reset-pin', newPin: ctrl.text);
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
    final visaGesperrt = visa?['gesperrt'] == true;
    final since =
        DateTime.tryParse(u['kundeSeit'] as String? ?? '') ?? DateTime.now();

    return Container(
      decoration: const BoxDecoration(
        color: DkbColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(
          20, 12, 20, MediaQuery.of(context).viewInsets.bottom + 28),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                      color: DkbColors.divider, borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 16),

            // User header
            Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: gesperrt
                      ? DkbColors.danger.withValues(alpha: 0.1)
                      : DkbColors.primary.withValues(alpha: 0.1),
                  child: Text(
                    ((u['name'] as String?) ?? '?')[0].toUpperCase(),
                    style: GoogleFonts.inter(
                        color: gesperrt ? DkbColors.danger : DkbColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 20),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(u['name'] as String? ?? '',
                          style: GoogleFonts.inter(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: DkbColors.textPrimary)),
                      Text('Kto. ${u['kontonummer']}',
                          style: GoogleFonts.ibmPlexMono(
                              fontSize: 12, color: DkbColors.textSecondary)),
                      if (u['email'] != null)
                        Text(u['email'] as String,
                            style: GoogleFonts.inter(fontSize: 11, color: DkbColors.textMuted)),
                    ],
                  ),
                ),
                if (gesperrt)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: DkbColors.danger.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: DkbColors.danger.withValues(alpha: 0.3)),
                    ),
                    child: Text('GESPERRT',
                        style: GoogleFonts.inter(
                            color: DkbColors.danger,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5)),
                  ),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(height: 1, color: DkbColors.divider),
            const SizedBox(height: 14),

            // Info grid
            Row(
              children: [
                Expanded(child: _infoSection('Konto-Info', [
                  _infoRow('Kunde seit', DateFormat('dd.MM.yyyy').format(since)),
                  if (giro != null) ...[
                    _infoRow('IBAN', giro['iban'] as String? ?? '–'),
                    _infoRow('Saldo',
                        _fmtEur((giro['saldo'] as num?)?.toDouble() ?? 0)),
                    _infoRow('Verfügbar',
                        _fmtEur((giro['verfuegbar'] as num?)?.toDouble() ?? 0)),
                  ],
                ])),
                const SizedBox(width: 16),
                Expanded(child: _infoSection('Visa-Karte', [
                  if (visa != null) ...[
                    _infoRow('Karte', visa['kartenNummer'] as String? ?? '–'),
                    _infoRow('Saldo',
                        _fmtEur((visa['aktuellerSaldo'] as num?)?.toDouble() ?? 0)),
                    _infoRow('Limit',
                        _fmtEur((visa['kreditlimit'] as num?)?.toDouble() ?? 0)),
                    _infoRow('Status', visaGesperrt ? '⛔ Gesperrt' : '✓ Aktiv'),
                  ] else
                    _infoRow('Status', 'Keine Karte'),
                ])),
              ],
            ),

            const SizedBox(height: 20),

            if (_loading)
              const Center(child: CircularProgressIndicator())
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Aktionen',
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: DkbColors.textSecondary)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: Icon(
                              gesperrt ? Icons.lock_open_rounded : Icons.lock_rounded,
                              size: 15),
                          label: Text(gesperrt ? 'Konto aktivieren' : 'Konto sperren'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor:
                                gesperrt ? DkbColors.success : DkbColors.danger,
                            side: BorderSide(
                                color: gesperrt ? DkbColors.success : DkbColors.danger),
                          ),
                          onPressed: () =>
                              _doAction(gesperrt ? 'activate' : 'suspend'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: Icon(
                              visaGesperrt
                                  ? Icons.credit_card_rounded
                                  : Icons.credit_card_off_rounded,
                              size: 15),
                          label: Text(visaGesperrt ? 'Karte freigeben' : 'Karte sperren'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor:
                                visaGesperrt ? DkbColors.success : DkbColors.warning,
                            side: BorderSide(
                                color: visaGesperrt
                                    ? DkbColors.success
                                    : DkbColors.warning),
                          ),
                          onPressed: visa == null
                              ? null
                              : () => _doAction(
                                  visaGesperrt ? 'unfreeze-card' : 'freeze-card'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.key_rounded, size: 15),
                    label: const Text('PIN zurücksetzen'),
                    onPressed: _showPinReset,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _infoSection(String title, List<Widget> rows) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: DkbColors.textMuted,
                  letterSpacing: 0.5)),
          const SizedBox(height: 8),
          ...rows,
        ],
      );

  Widget _infoRow(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: GoogleFonts.inter(fontSize: 10, color: DkbColors.textMuted)),
            Text(value,
                style: GoogleFonts.inter(
                    fontSize: 12,
                    color: DkbColors.textPrimary,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      );

  String _fmtEur(double v) =>
      NumberFormat.currency(locale: 'de_DE', symbol: '€').format(v);
}
