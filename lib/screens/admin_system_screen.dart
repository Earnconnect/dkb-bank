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
  List<dynamic> _beneficiaries = [];
  bool _loading = true;
  String? _error;
  bool _seeding = false;

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
      final res = await ApiService.instance.adminGetBeneficiaries();
      if (!mounted) return;
      if (res['statusCode'] == 200) {
        setState(() {
          _beneficiaries = res['beneficiaries'] as List;
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

  Future<void> _seed() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Datenbank neu befüllen?', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: Text(
          'Alle Testdaten werden gelöscht und neu eingespielt. Echte Nutzerdaten bleiben erhalten.',
          style: GoogleFonts.inter(fontSize: 14),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Abbrechen')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: DkbColors.warning),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Bestätigen'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

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

  // Group beneficiaries by owner
  Map<String, List<Map<String, dynamic>>> get _grouped {
    final map = <String, List<Map<String, dynamic>>>{};
    for (final b in _beneficiaries) {
      final bMap = b as Map<String, dynamic>;
      final key = '${bMap['ownerName']} (${bMap['ownerKontonummer']})';
      map.putIfAbsent(key, () => []).add(bMap);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: DkbColors.danger, size: 44),
            const SizedBox(height: 10),
            Text(_error!, style: GoogleFonts.inter(color: DkbColors.danger)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _load, child: const Text('Erneut versuchen')),
          ],
        ),
      );
    }

    final grouped = _grouped;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── System Actions ───────────────────────────────────────────────
          _sectionLabel('System-Aktionen'),
          const SizedBox(height: 10),
          _actionCard(
            icon: Icons.storage_outlined,
            iconColor: DkbColors.warning,
            title: 'Datenbank neu befüllen',
            subtitle: 'Seed-Daten neu einspielen (Demo-Transaktionen, etc.)',
            actionLabel: 'Seed ausführen',
            actionColor: DkbColors.warning,
            loading: _seeding,
            onTap: _seed,
          ),

          const SizedBox(height: 20),

          // ── Beneficiaries ────────────────────────────────────────────────
          Row(
            children: [
              Expanded(child: _sectionLabel('Empfänger-Übersicht')),
              GestureDetector(
                onTap: _load,
                child: Row(
                  children: [
                    const Icon(Icons.refresh, size: 14, color: DkbColors.accent),
                    const SizedBox(width: 4),
                    Text('Aktualisieren', style: GoogleFonts.inter(fontSize: 12, color: DkbColors.accent)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${_beneficiaries.length} Empfänger insgesamt',
            style: GoogleFonts.inter(fontSize: 12, color: DkbColors.textMuted),
          ),
          const SizedBox(height: 12),

          if (_beneficiaries.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: DkbColors.surface,
                borderRadius: BorderRadius.circular(DkbRadius.md),
                border: Border.all(color: DkbColors.divider),
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.people_outline, size: 36, color: DkbColors.textMuted),
                    const SizedBox(height: 8),
                    Text(
                      'Keine Empfänger gespeichert',
                      style: GoogleFonts.inter(color: DkbColors.textMuted, fontSize: 13),
                    ),
                  ],
                ),
              ),
            )
          else
            ...grouped.entries.map((entry) {
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: DkbColors.surface,
                  borderRadius: BorderRadius.circular(DkbRadius.md),
                  border: Border.all(color: DkbColors.divider),
                ),
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                  leading: CircleAvatar(
                    radius: 18,
                    backgroundColor: DkbColors.primary.withValues(alpha: 0.1),
                    child: Text(
                      entry.key[0].toUpperCase(),
                      style: GoogleFonts.inter(color: DkbColors.primary, fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                  ),
                  title: Text(
                    entry.key,
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: DkbColors.textPrimary),
                  ),
                  subtitle: Text(
                    '${entry.value.length} Empfänger',
                    style: GoogleFonts.inter(fontSize: 11, color: DkbColors.textMuted),
                  ),
                  children: entry.value.map((b) {
                    final date = DateTime.tryParse(b['verknuepftAm'] as String? ?? '') ?? DateTime.now();
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: DkbColors.background,
                        borderRadius: BorderRadius.circular(DkbRadius.sm),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            b['name'] as String? ?? '–',
                            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: DkbColors.textPrimary),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            b['iban'] as String? ?? '–',
                            style: GoogleFonts.ibmPlexMono(fontSize: 11, color: DkbColors.textSecondary),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Text(
                                'BIC: ${b['bic'] ?? '–'}',
                                style: GoogleFonts.inter(fontSize: 11, color: DkbColors.textMuted),
                              ),
                              const Spacer(),
                              Text(
                                'Seit ${DateFormat('dd.MM.yy').format(date)}',
                                style: GoogleFonts.inter(fontSize: 11, color: DkbColors.textMuted),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              );
            }),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _sectionLabel(String t) => Text(
        t,
        style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: DkbColors.textPrimary),
      );

  Widget _actionCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String actionLabel,
    required Color actionColor,
    required bool loading,
    required VoidCallback onTap,
  }) =>
      Container(
        decoration: BoxDecoration(
          color: DkbColors.surface,
          borderRadius: BorderRadius.circular(DkbRadius.md),
          border: Border.all(color: DkbColors.divider),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
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
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: DkbColors.textPrimary)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: GoogleFonts.inter(fontSize: 12, color: DkbColors.textMuted)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            loading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : ElevatedButton(
                    onPressed: onTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: actionColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      textStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    child: Text(actionLabel),
                  ),
          ],
        ),
      );
}
