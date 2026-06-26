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
  List<dynamic> _all = [];
  bool _loading = true;
  String? _error;
  String _search = '';
  String _filter = 'all'; // all | girokonto | visa | credit | debit

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
      final res = await ApiService.instance.adminGetTransactions();
      if (!mounted) return;
      if (res['statusCode'] == 200) {
        setState(() {
          _all = res['transactions'] as List;
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
    var list = _all;
    if (_filter == 'girokonto') list = list.where((t) => (t as Map)['kontoTyp'] == 'girokonto').toList();
    if (_filter == 'visa') list = list.where((t) => (t as Map)['kontoTyp'] == 'visa').toList();
    if (_filter == 'credit') list = list.where((t) => ((t as Map)['betrag'] as num? ?? 0) > 0).toList();
    if (_filter == 'debit') list = list.where((t) => ((t as Map)['betrag'] as num? ?? 0) < 0).toList();
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      list = list.where((t) {
        final m = t as Map<String, dynamic>;
        return (m['empfaenger'] as String? ?? '').toLowerCase().contains(q) ||
            (m['userName'] as String? ?? '').toLowerCase().contains(q) ||
            (m['userKontonummer'] as String? ?? '').contains(q);
      }).toList();
    }
    return list;
  }

  double get _totalFiltered {
    return _filtered.fold(0.0, (sum, t) => sum + ((t as Map)['betrag'] as num? ?? 0).toDouble());
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

    final filtered = _filtered;

    return Column(
      children: [
        // ── Toolbar ──────────────────────────────────────────────────────
        Container(
          color: DkbColors.surface,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: DkbColors.divider)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      onChanged: (v) => setState(() => _search = v),
                      decoration: InputDecoration(
                        hintText: 'Nutzer oder Empfänger suchen…',
                        prefixIcon: const Icon(Icons.search_rounded, size: 18),
                        suffixIcon: _search.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 16),
                                onPressed: () => setState(() => _search = ''),
                              )
                            : null,
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                  const SizedBox(width: 10),
                  _refreshBtn(),
                ],
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _chip('Alle', 'all'),
                    const SizedBox(width: 6),
                    _chip('Girokonto', 'girokonto'),
                    const SizedBox(width: 6),
                    _chip('Visa', 'visa'),
                    const SizedBox(width: 6),
                    _chip('Gutschriften', 'credit'),
                    const SizedBox(width: 6),
                    _chip('Belastungen', 'debit'),
                  ],
                ),
              ),
            ],
          ),
        ),

        // ── Summary bar ───────────────────────────────────────────────────
        Container(
          color: DkbColors.background,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text('${filtered.length} Einträge',
                  style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: DkbColors.textSecondary)),
              const Spacer(),
              Text(
                'Summe: ${NumberFormat.currency(locale: 'de_DE', symbol: '€').format(_totalFiltered)}',
                style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _totalFiltered >= 0 ? DkbColors.success : DkbColors.danger),
              ),
            ],
          ),
        ),

        // ── Transaction list ──────────────────────────────────────────────
        Expanded(
          child: RefreshIndicator(
            onRefresh: _load,
            child: filtered.isEmpty
                ? Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.receipt_long_outlined, size: 44, color: DkbColors.textMuted),
                      const SizedBox(height: 8),
                      Text('Keine Transaktionen',
                          style: GoogleFonts.inter(color: DkbColors.textMuted)),
                    ]),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: filtered.length,
                    itemBuilder: (_, i) {
                      final tx = filtered[i] as Map<String, dynamic>;
                      final betrag = (tx['betrag'] as num?)?.toDouble() ?? 0;
                      final isCredit = betrag > 0;
                      final date = DateTime.tryParse(
                              tx['buchungsdatum'] as String? ?? '') ??
                          DateTime.now();
                      final kontoTyp = tx['kontoTyp'] as String? ?? '';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        decoration: BoxDecoration(
                          color: DkbColors.surface,
                          borderRadius: BorderRadius.circular(DkbRadius.sm),
                          border: Border.all(color: DkbColors.divider),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          child: Row(
                            children: [
                              // Amount indicator circle
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: isCredit
                                      ? DkbColors.success.withValues(alpha: 0.1)
                                      : DkbColors.danger.withValues(alpha: 0.07),
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
                              const SizedBox(width: 10),

                              // Details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      tx['empfaenger'] as String? ?? '–',
                                      style: GoogleFonts.inter(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                          color: DkbColors.textPrimary),
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        _typePill(kontoTyp),
                                        const SizedBox(width: 6),
                                        Text(
                                          '${tx['userName']}',
                                          style: GoogleFonts.inter(
                                              fontSize: 11, color: DkbColors.textMuted),
                                        ),
                                        const SizedBox(width: 6),
                                        Text('·',
                                            style: GoogleFonts.inter(
                                                color: DkbColors.textMuted)),
                                        const SizedBox(width: 6),
                                        Text(
                                          DateFormat('dd.MM.yy').format(date),
                                          style: GoogleFonts.inter(
                                              fontSize: 11, color: DkbColors.textMuted),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              // Amount
                              Text(
                                NumberFormat.currency(locale: 'de_DE', symbol: '€')
                                    .format(betrag),
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: isCredit
                                      ? DkbColors.success
                                      : DkbColors.textPrimary,
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

  Widget _chip(String label, String value) {
    final active = _filter == value;
    return GestureDetector(
      onTap: () => setState(() => _filter = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? DkbColors.primary : DkbColors.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: active ? DkbColors.primary : DkbColors.divider),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: active ? FontWeight.w600 : FontWeight.w400,
            color: active ? Colors.white : DkbColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _typePill(String type) {
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

  Widget _refreshBtn() => Tooltip(
        message: 'Aktualisieren',
        child: InkWell(
          onTap: _load,
          borderRadius: BorderRadius.circular(DkbRadius.sm),
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: DkbColors.background,
              borderRadius: BorderRadius.circular(DkbRadius.sm),
              border: Border.all(color: DkbColors.divider),
            ),
            child: const Icon(Icons.refresh_rounded, size: 18, color: DkbColors.textSecondary),
          ),
        ),
      );
}
