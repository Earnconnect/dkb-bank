import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';

class AdminTransactionsScreen extends StatefulWidget {
  const AdminTransactionsScreen({super.key});

  @override
  State<AdminTransactionsScreen> createState() => _AdminTransactionsScreenState();
}

class _AdminTransactionsScreenState extends State<AdminTransactionsScreen> {
  List<dynamic> _transactions = [];
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
      final result = await ApiService.instance.adminGetTransactions();
      if (!mounted) return;
      if (result['statusCode'] == 200) {
        setState(() {
          _transactions = result['transactions'] as List;
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

  List<dynamic> get _filtered {
    if (_search.isEmpty) return _transactions;
    final q = _search.toLowerCase();
    return _transactions.where((t) {
      final tx = t as Map<String, dynamic>;
      return (tx['empfaenger'] as String? ?? '').toLowerCase().contains(q) ||
          (tx['userName'] as String? ?? '').toLowerCase().contains(q) ||
          (tx['userKontonummer'] as String? ?? '').contains(q) ||
          (tx['kategorie'] as String? ?? '').toLowerCase().contains(q);
    }).toList();
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
            Text(_error!, style: GoogleFonts.inter(color: DkbColors.danger, fontSize: 14)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _load, child: const Text('Erneut versuchen')),
          ],
        ),
      );
    }

    final filtered = _filtered;

    return Column(
      children: [
        Container(
          color: DkbColors.surface,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: TextField(
            onChanged: (v) => setState(() => _search = v),
            decoration: InputDecoration(
              hintText: 'Nutzer oder Empfänger suchen…',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _search.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () => setState(() => _search = ''),
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              filled: true,
              fillColor: DkbColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DkbRadius.sm),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
          child: Row(
            children: [
              Text(
                '${filtered.length} Transaktionen',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: DkbColors.textSecondary,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _load,
                child: Row(
                  children: [
                    const Icon(Icons.refresh, size: 14, color: DkbColors.accent),
                    const SizedBox(width: 4),
                    Text(
                      'Aktualisieren',
                      style: GoogleFonts.inter(fontSize: 12, color: DkbColors.accent),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _load,
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              itemCount: filtered.length,
              itemBuilder: (_, i) {
                final tx = filtered[i] as Map<String, dynamic>;
                final betrag = (tx['betrag'] as num?)?.toDouble() ?? 0.0;
                final isCredit = betrag > 0;
                final date = DateTime.tryParse(tx['buchungsdatum'] as String? ?? '') ?? DateTime.now();
                final kontoTyp = tx['kontoTyp'] as String? ?? 'girokonto';

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: DkbColors.surface,
                    borderRadius: BorderRadius.circular(DkbRadius.sm),
                    border: Border.all(color: DkbColors.divider),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: isCredit
                                ? DkbColors.success.withValues(alpha: 0.1)
                                : DkbColors.danger.withValues(alpha: 0.08),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isCredit ? Icons.arrow_downward : Icons.arrow_upward,
                            size: 18,
                            color: isCredit ? DkbColors.success : DkbColors.danger,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tx['empfaenger'] as String? ?? '–',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: DkbColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${tx['userName']}  ·  Kto. ${tx['userKontonummer']}',
                                style: GoogleFonts.inter(fontSize: 11, color: DkbColors.textMuted),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: kontoTyp == 'visa'
                                          ? DkbColors.accent.withValues(alpha: 0.1)
                                          : DkbColors.primary.withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      kontoTyp == 'visa' ? 'VISA' : 'GIRO',
                                      style: GoogleFonts.inter(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        color: kontoTyp == 'visa' ? DkbColors.accent : DkbColors.primary,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    DateFormat('dd.MM.yy').format(date),
                                    style: GoogleFonts.inter(fontSize: 11, color: DkbColors.textMuted),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Text(
                          _fmtEur(betrag),
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isCredit ? DkbColors.success : DkbColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  String _fmtEur(double v) => NumberFormat.currency(locale: 'de_DE', symbol: '€').format(v);
}
