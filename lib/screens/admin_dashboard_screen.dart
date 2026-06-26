import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  Map<String, dynamic>? _stats;
  List<dynamic> _recent = [];
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
      final res = await ApiService.instance.adminGetStats();
      if (!mounted) return;
      if (res['statusCode'] == 200) {
        setState(() {
          _stats = res['stats'] as Map<String, dynamic>;
          _recent = res['recentTransactions'] as List? ?? [];
          _loading = false;
        });
      } else {
        setState(() {
          _error = res['error'] as String? ?? 'Fehler beim Laden';
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
            Icon(Icons.cloud_off_outlined, size: 48, color: DkbColors.textMuted),
            const SizedBox(height: 12),
            Text(_error!, style: GoogleFonts.inter(color: DkbColors.danger, fontSize: 14)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Erneut versuchen'),
            ),
          ],
        ),
      );
    }

    final s = _stats!;
    final totalUsers = s['totalUsers'] as int? ?? 0;
    final activeCount = s['activeCount'] as int? ?? 0;
    final suspendedCount = s['suspendedCount'] as int? ?? 0;
    final totalGiro = (s['totalGiroBalance'] as num?)?.toDouble() ?? 0;
    final totalTx = s['totalTransactions'] as int? ?? 0;

    return RefreshIndicator(
      onRefresh: _load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Welcome banner ─────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1E3060), Color(0xFF0D1A36)],
                ),
                borderRadius: BorderRadius.circular(DkbRadius.lg),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Willkommen zurück',
                          style: GoogleFonts.inter(
                            color: Colors.white.withValues(alpha: 0.65),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'DKB Administrationsportal',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          DateFormat('EEEE, dd. MMMM yyyy', 'de_DE').format(DateTime.now()),
                          style: GoogleFonts.inter(
                            color: DkbColors.accent,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(DkbRadius.md),
                    ),
                    child: const Icon(Icons.admin_panel_settings_rounded,
                        color: DkbColors.accent, size: 28),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── KPI Cards ──────────────────────────────────────────────────
            Text('Kennzahlen',
                style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: DkbColors.textSecondary)),
            const SizedBox(height: 10),

            LayoutBuilder(builder: (ctx, c) {
              final w = c.maxWidth;
              final cols = w > 700 ? 4 : (w > 450 ? 2 : 2);
              final cardW = (w - (cols - 1) * 12) / cols;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _KpiCard(
                    width: cardW,
                    icon: Icons.people_rounded,
                    color: DkbColors.primary,
                    label: 'Nutzer',
                    value: '$totalUsers',
                    sub: '$activeCount aktiv',
                  ),
                  _KpiCard(
                    width: cardW,
                    icon: Icons.account_balance_rounded,
                    color: DkbColors.success,
                    label: 'Gesamtguthaben',
                    value: _fmtEur(totalGiro),
                    sub: 'Alle Girokonten',
                  ),
                  _KpiCard(
                    width: cardW,
                    icon: Icons.receipt_long_rounded,
                    color: DkbColors.accent,
                    label: 'Transaktionen',
                    value: _fmtInt(totalTx),
                    sub: 'Gesamt erfasst',
                  ),
                  _KpiCard(
                    width: cardW,
                    icon: suspendedCount > 0 ? Icons.lock_rounded : Icons.verified_rounded,
                    color: suspendedCount > 0 ? DkbColors.danger : DkbColors.success,
                    label: 'Gesperrt',
                    value: '$suspendedCount',
                    sub: suspendedCount == 0 ? 'Alle aktiv' : 'Konten gesperrt',
                  ),
                ],
              );
            }),

            const SizedBox(height: 24),

            // ── Alert banner if suspended accounts ─────────────────────────
            if (suspendedCount > 0) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: DkbColors.danger.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(DkbRadius.md),
                  border: Border.all(color: DkbColors.danger.withValues(alpha: 0.25)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: DkbColors.danger, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '$suspendedCount ${suspendedCount == 1 ? 'Konto ist' : 'Konten sind'} derzeit gesperrt.',
                        style: GoogleFonts.inter(
                            color: DkbColors.danger, fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // ── Recent Transactions ────────────────────────────────────────
            Row(
              children: [
                Text('Letzte Transaktionen',
                    style: GoogleFonts.inter(
                        fontSize: 13, fontWeight: FontWeight.w600, color: DkbColors.textSecondary)),
                const Spacer(),
                GestureDetector(
                  onTap: _load,
                  child: Row(
                    children: [
                      const Icon(Icons.refresh_rounded, size: 14, color: DkbColors.accent),
                      const SizedBox(width: 4),
                      Text('Aktualisieren',
                          style: GoogleFonts.inter(fontSize: 12, color: DkbColors.accent)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            Container(
              decoration: BoxDecoration(
                color: DkbColors.surface,
                borderRadius: BorderRadius.circular(DkbRadius.md),
                border: Border.all(color: DkbColors.divider),
              ),
              child: _recent.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Text('Keine Transaktionen vorhanden',
                            style: GoogleFonts.inter(
                                color: DkbColors.textMuted, fontSize: 13)),
                      ),
                    )
                  : Column(
                      children: List.generate(_recent.length, (i) {
                        final tx = _recent[i] as Map<String, dynamic>;
                        final betrag = (tx['betrag'] as num?)?.toDouble() ?? 0;
                        final isCredit = betrag > 0;
                        final date = DateTime.tryParse(tx['buchungsdatum'] as String? ?? '') ??
                            DateTime.now();
                        final kontoTyp = tx['kontoTyp'] as String? ?? 'girokonto';
                        final isLast = i == _recent.length - 1;

                        return Container(
                          decoration: BoxDecoration(
                            border: isLast
                                ? null
                                : const Border(
                                    bottom: BorderSide(color: DkbColors.divider, width: 1)),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: isCredit
                                      ? DkbColors.success.withValues(alpha: 0.1)
                                      : DkbColors.danger.withValues(alpha: 0.08),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isCredit
                                      ? Icons.arrow_downward_rounded
                                      : Icons.arrow_upward_rounded,
                                  size: 16,
                                  color: isCredit ? DkbColors.success : DkbColors.danger,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      tx['empfaenger'] as String? ?? '–',
                                      style: GoogleFonts.inter(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: DkbColors.textPrimary),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${tx['userName']}  ·  ${DateFormat('dd.MM.yy').format(date)}',
                                      style: GoogleFonts.inter(
                                          fontSize: 11, color: DkbColors.textMuted),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    _fmtEur(betrag),
                                    style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: isCredit
                                            ? DkbColors.success
                                            : DkbColors.textPrimary),
                                  ),
                                  const SizedBox(height: 2),
                                  _typeBadge(kontoTyp),
                                ],
                              ),
                            ],
                          ),
                        );
                      }),
                    ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _typeBadge(String type) {
    final isVisa = type == 'visa';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: isVisa
            ? DkbColors.accent.withValues(alpha: 0.1)
            : DkbColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        isVisa ? 'VISA' : 'GIRO',
        style: GoogleFonts.inter(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: isVisa ? DkbColors.accent : DkbColors.primary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  String _fmtEur(double v) => NumberFormat.currency(locale: 'de_DE', symbol: '€').format(v);
  String _fmtInt(int v) => NumberFormat('#,###', 'de_DE').format(v);
}

// ── KPI Card widget ────────────────────────────────────────────────────────

class _KpiCard extends StatelessWidget {
  final double width;
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final String sub;

  const _KpiCard({
    required this.width,
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    required this.sub,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: DkbColors.surface,
          borderRadius: BorderRadius.circular(DkbRadius.md),
          border: Border.all(color: DkbColors.divider),
          boxShadow: DkbShadows.xs,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(DkbRadius.sm),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 14),
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: DkbColors.textPrimary,
                letterSpacing: -0.5,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: DkbColors.textSecondary,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              sub,
              style: GoogleFonts.inter(fontSize: 11, color: DkbColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
