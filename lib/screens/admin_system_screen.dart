import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';

class AdminSystemScreen extends StatefulWidget {
  const AdminSystemScreen({super.key});

  @override
  State<AdminSystemScreen> createState() => _AdminSystemScreenState();
}

class _AdminSystemScreenState extends State<AdminSystemScreen> {
  List<dynamic> _users = [];
  List<dynamic> _beneficiaries = [];
  bool _loading = true;
  String? _error;
  bool _seeding = false;
  int _activeTab = 0; // 0=cards, 1=beneficiaries, 2=system

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
      final results = await Future.wait([
        ApiService.instance.adminGetUsers(),
        ApiService.instance.adminGetBeneficiaries(),
      ]);
      if (!mounted) return;
      final usersRes = results[0];
      final bRes = results[1];
      if (usersRes['statusCode'] == 200 && bRes['statusCode'] == 200) {
        setState(() {
          _users = usersRes['users'] as List;
          _beneficiaries = bRes['beneficiaries'] as List;
          _loading = false;
        });
      } else {
        setState(() {
          _error = (usersRes['error'] ?? bRes['error']) as String? ?? 'Fehler';
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

  Future<void> _cardAction(String userId, String action) async {
    try {
      final res =
          await ApiService.instance.adminAccountAction(userId: userId, action: action);
      if (!mounted) return;
      await _load();
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
    }
  }

  Future<void> _seed() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title:
            Text('Seed ausführen?', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: Text(
          'Alle Demo-Daten werden neu eingespielt. Bestehende Nutzerkonten bleiben erhalten.',
          style: GoogleFonts.inter(fontSize: 14),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Abbrechen')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: DkbColors.warning),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Bestätigen'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => _seeding = true);
    try {
      final res = await ApiService.instance.seed();
      if (!mounted) return;
      setState(() => _seeding = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] as String? ?? 'Seed abgeschlossen'),
          backgroundColor: DkbColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _seeding = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler: $e'), backgroundColor: DkbColors.danger),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.error_outline, color: DkbColors.danger, size: 44),
          const SizedBox(height: 10),
          Text(_error!, style: GoogleFonts.inter(color: DkbColors.danger)),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _load, child: const Text('Erneut versuchen')),
        ]),
      );
    }

    return Column(
      children: [
        // ── Tab selector ──────────────────────────────────────────────────
        Container(
          color: DkbColors.surface,
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: DkbColors.divider)),
          ),
          child: Row(
            children: [
              _tab(0, Icons.credit_card_rounded, 'Karten'),
              _tab(1, Icons.people_outline_rounded, 'Empfänger'),
              _tab(2, Icons.storage_rounded, 'Datenbank'),
            ],
          ),
        ),

        Expanded(
          child: RefreshIndicator(
            onRefresh: _load,
            child: _activeTab == 0
                ? _cardsTab()
                : _activeTab == 1
                    ? _beneficiariesTab()
                    : _systemTab(),
          ),
        ),
      ],
    );
  }

  // ── Cards Tab ──────────────────────────────────────────────────────────

  Widget _cardsTab() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _users.length + 1,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        if (i == 0) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionHeader(
                  'Karten-Verwaltung', '${_users.length} Konten  ·  Visa-Karten sperren/freigeben'),
              const SizedBox(height: 12),
            ],
          );
        }
        final u = _users[i - 1] as Map<String, dynamic>;
        final visa = u['visaKarte'] as Map<String, dynamic>?;
        if (visa == null) return const SizedBox.shrink();
        final gesperrt = visa['gesperrt'] == true;

        return Container(
          decoration: BoxDecoration(
            color: DkbColors.surface,
            borderRadius: BorderRadius.circular(DkbRadius.md),
            border: Border.all(
              color: gesperrt ? DkbColors.danger.withValues(alpha: 0.3) : DkbColors.divider,
            ),
          ),
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1A3A6B), Color(0xFF0D1A36)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  gesperrt ? Icons.credit_card_off_rounded : Icons.credit_card_rounded,
                  color: gesperrt ? DkbColors.danger.withValues(alpha: 0.8) : Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(u['name'] as String? ?? '',
                        style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: DkbColors.textPrimary)),
                    const SizedBox(height: 2),
                    Text(
                      visa['kartenNummer'] as String? ?? '–',
                      style: GoogleFonts.ibmPlexMono(
                          fontSize: 11, color: DkbColors.textSecondary),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: gesperrt
                                ? DkbColors.danger.withValues(alpha: 0.1)
                                : DkbColors.success.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            gesperrt ? 'GESPERRT' : 'AKTIV',
                            style: GoogleFonts.inter(
                                color: gesperrt ? DkbColors.danger : DkbColors.success,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Limit: ${_fmtEur((visa['kreditlimit'] as num?)?.toDouble() ?? 0)}',
                          style: GoogleFonts.inter(fontSize: 11, color: DkbColors.textMuted),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () => _cardAction(
                  u['id'] as String,
                  gesperrt ? 'unfreeze-card' : 'freeze-card',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: gesperrt ? DkbColors.success : DkbColors.warning,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  textStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                child: Text(gesperrt ? 'Freigeben' : 'Sperren'),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Beneficiaries Tab ──────────────────────────────────────────────────

  Widget _beneficiariesTab() {
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final b in _beneficiaries) {
      final m = b as Map<String, dynamic>;
      final key = '${m['ownerName']} (${m['ownerKontonummer']})';
      grouped.putIfAbsent(key, () => []).add(m);
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionHeader('Empfänger-Übersicht',
            '${_beneficiaries.length} gespeicherte Empfänger  ·  ${grouped.length} Konten'),
        const SizedBox(height: 12),
        if (_beneficiaries.isEmpty)
          _emptyState(Icons.people_outline, 'Keine Empfänger gespeichert')
        else
          ...grouped.entries.map((entry) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: DkbColors.surface,
                  borderRadius: BorderRadius.circular(DkbRadius.md),
                  border: Border.all(color: DkbColors.divider),
                ),
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                  leading: CircleAvatar(
                    radius: 18,
                    backgroundColor: DkbColors.primary.withValues(alpha: 0.08),
                    child: Text(entry.key[0].toUpperCase(),
                        style: GoogleFonts.inter(
                            color: DkbColors.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 13)),
                  ),
                  title: Text(entry.key,
                      style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: DkbColors.textPrimary)),
                  subtitle: Text('${entry.value.length} Empfänger',
                      style: GoogleFonts.inter(fontSize: 11, color: DkbColors.textMuted)),
                  children: entry.value.map((b) {
                    final date =
                        DateTime.tryParse(b['verknuepftAm'] as String? ?? '') ??
                            DateTime.now();
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: DkbColors.background,
                        borderRadius: BorderRadius.circular(DkbRadius.sm),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(b['name'] as String? ?? '–',
                                    style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: DkbColors.textPrimary)),
                                const SizedBox(height: 2),
                                Text(b['iban'] as String? ?? '–',
                                    style: GoogleFonts.ibmPlexMono(
                                        fontSize: 11, color: DkbColors.textSecondary)),
                                const SizedBox(height: 2),
                                Text('BIC: ${b['bic'] ?? '–'}',
                                    style: GoogleFonts.inter(
                                        fontSize: 11, color: DkbColors.textMuted)),
                              ],
                            ),
                          ),
                          Text(DateFormat('dd.MM.yy').format(date),
                              style: GoogleFonts.inter(
                                  fontSize: 11, color: DkbColors.textMuted)),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              )),
      ],
    );
  }

  // ── System/DB Tab ──────────────────────────────────────────────────────

  Widget _systemTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionHeader(
            'Datenbank-Verwaltung', 'System-Operationen und Datenbankpflege'),
        const SizedBox(height: 16),

        _actionCard(
          icon: Icons.storage_rounded,
          iconColor: DkbColors.warning,
          title: 'Demo-Daten neu einspielen',
          description:
              'Seed-Transaktionen und Demo-Daten werden zurückgesetzt. Nutzerkonten bleiben erhalten.',
          buttonLabel: _seeding ? 'Läuft…' : 'Seed ausführen',
          buttonColor: DkbColors.warning,
          loading: _seeding,
          onTap: _seed,
        ),

        const SizedBox(height: 12),

        _actionCard(
          icon: Icons.info_outline_rounded,
          iconColor: DkbColors.accent,
          title: 'Datenbank-Schema',
          description:
              'Um das Schema zu aktualisieren (z.B. nach Änderungen), führen Sie "npx prisma db push" aus.',
          buttonLabel: null,
          buttonColor: DkbColors.accent,
          loading: false,
          onTap: null,
        ),

        const SizedBox(height: 12),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: DkbColors.surface,
            borderRadius: BorderRadius.circular(DkbRadius.md),
            border: Border.all(color: DkbColors.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Systemstatistiken',
                  style: GoogleFonts.inter(
                      fontSize: 14, fontWeight: FontWeight.w600, color: DkbColors.textPrimary)),
              const SizedBox(height: 14),
              _statRow('Registrierte Nutzer', '${_users.length}'),
              _statRow('Gespeicherte Empfänger', '${_beneficiaries.length}'),
              _statRow('Gesperrte Konten',
                  '${_users.where((u) => (u as Map)['gesperrt'] == true).length}'),
              _statRow('Gesperrte Karten',
                  '${_users.where((u) => (u as Map)['visaKarte']?['gesperrt'] == true).length}'),
            ],
          ),
        ),

        const SizedBox(height: 24),
      ],
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  Widget _tab(int index, IconData icon, String label) {
    final active = _activeTab == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _activeTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: active ? DkbColors.primary : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 16,
                  color: active ? DkbColors.primary : DkbColors.textMuted),
              const SizedBox(width: 6),
              Text(label,
                  style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                      color: active ? DkbColors.primary : DkbColors.textMuted)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, String subtitle) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: GoogleFonts.inter(
                  fontSize: 16, fontWeight: FontWeight.w700, color: DkbColors.textPrimary)),
          const SizedBox(height: 2),
          Text(subtitle,
              style: GoogleFonts.inter(fontSize: 12, color: DkbColors.textMuted)),
        ],
      );

  Widget _emptyState(IconData icon, String msg) => Container(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: Column(
            children: [
              Icon(icon, size: 40, color: DkbColors.textMuted),
              const SizedBox(height: 8),
              Text(msg, style: GoogleFonts.inter(color: DkbColors.textMuted, fontSize: 13)),
            ],
          ),
        ),
      );

  Widget _actionCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    required String? buttonLabel,
    required Color buttonColor,
    required bool loading,
    required VoidCallback? onTap,
  }) =>
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: DkbColors.surface,
          borderRadius: BorderRadius.circular(DkbRadius.md),
          border: Border.all(color: DkbColors.divider),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(DkbRadius.sm),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: DkbColors.textPrimary)),
                  const SizedBox(height: 4),
                  Text(description,
                      style: GoogleFonts.inter(fontSize: 12, color: DkbColors.textMuted)),
                  if (buttonLabel != null) ...[
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: ElevatedButton(
                        onPressed: loading ? null : onTap,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: buttonColor,
                          foregroundColor: Colors.white,
                          padding:
                              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          textStyle: GoogleFonts.inter(
                              fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                        child: loading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : Text(buttonLabel),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );

  Widget _statRow(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          children: [
            Expanded(
                child: Text(label,
                    style: GoogleFonts.inter(fontSize: 13, color: DkbColors.textSecondary))),
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
