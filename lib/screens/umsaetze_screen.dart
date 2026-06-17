import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../data/mock_data.dart';
import '../models/umsatz.dart';
import '../utils/german_formatter.dart';
import '../widgets/umsatz_tile.dart';

class UmsaetzeScreen extends StatefulWidget {
  final String kontoTyp;
  const UmsaetzeScreen({super.key, required this.kontoTyp});

  @override
  State<UmsaetzeScreen> createState() => _UmsaetzeScreenState();
}

class _UmsaetzeScreenState extends State<UmsaetzeScreen> {
  UmsatzTyp? _filter;
  String _search = '';

  List<Umsatz> get _filtered {
    final all = widget.kontoTyp == 'visa'
        ? MockData.umsaetzeForVisa()
        : MockData.umsaetzeForGirokonto();
    return all.where((u) {
      if (_filter != null && u.typ != _filter) return false;
      if (_search.isNotEmpty) {
        final q = _search.toLowerCase();
        return u.gegenpartei.toLowerCase().contains(q) ||
            u.verwendungszweck.toLowerCase().contains(q);
      }
      return true;
    }).toList();
  }

  double get _totalGutschriften =>
      _filtered.where((u) => u.isGutschrift).fold(0, (s, u) => s + u.betrag);

  double get _totalBelastungen =>
      _filtered.where((u) => u.isBelastung).fold(0, (s, u) => s + u.betrag);

  Map<String, List<Umsatz>> _groupByDate(List<Umsatz> list) {
    final map = <String, List<Umsatz>>{};
    for (final u in list) {
      final key = GermanFormatter.datumRelativ(u.buchungsdatum);
      (map[key] ??= []).add(u);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final grouped = _groupByDate(filtered);
    final groups = grouped.entries.toList();
    final title = widget.kontoTyp == 'visa' ? 'Visa-Umsätze' : 'Umsätze';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () async {
              final result = await showSearch<String>(
                context: context,
                delegate: _UmsatzSearch(
                  widget.kontoTyp == 'visa'
                      ? MockData.umsaetzeForVisa()
                      : MockData.umsaetzeForGirokonto(),
                ),
              );
              if (result != null) setState(() => _search = result);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Summary strip
          Container(
            color: DkbColors.primary,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: _SummaryItem(
                    label: 'Einnahmen',
                    amount: _totalGutschriften,
                    isPositive: true,
                  ),
                ),
                Container(width: 1, height: 40, color: Colors.white.withValues(alpha: 0.2)),
                Expanded(
                  child: _SummaryItem(
                    label: 'Ausgaben',
                    amount: _totalBelastungen,
                    isPositive: false,
                  ),
                ),
              ],
            ),
          ),

          // Filter chips
          Container(
            height: 44,
            color: DkbColors.surface,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              children: [
                buildFilterChip('Alle', _filter == null, () => setState(() => _filter = null)),
                const SizedBox(width: 8),
                buildFilterChip('Gutschriften', _filter == UmsatzTyp.gutschrift,
                    () => setState(() => _filter = UmsatzTyp.gutschrift)),
                const SizedBox(width: 8),
                buildFilterChip('Belastungen', _filter == UmsatzTyp.belastung,
                    () => setState(() => _filter = UmsatzTyp.belastung)),
              ],
            ),
          ),
          Container(height: 1, color: DkbColors.divider),

          // Transaction list
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text(
                      'Keine Umsätze gefunden',
                      style: GoogleFonts.inter(color: DkbColors.textMuted),
                    ),
                  )
                : ListView.builder(
                    itemCount: groups.length,
                    itemBuilder: (_, i) {
                      final group = groups[i];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                            child: Text(
                              group.key,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: DkbColors.textSecondary,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: DkbColors.surface,
                              borderRadius: BorderRadius.circular(DkbRadius.md),
                              boxShadow: DkbShadows.xs,
                            ),
                            child: Column(
                              children: group.value.asMap().entries.map((e) {
                                return Column(
                                  children: [
                                    UmsatzTile(umsatz: e.value),
                                    if (e.key < group.value.length - 1)
                                      const Divider(height: 1, indent: 70),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final double amount;
  final bool isPositive;

  const _SummaryItem({
    required this.label,
    required this.amount,
    required this.isPositive,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isPositive ? Icons.arrow_downward : Icons.arrow_upward,
              color: isPositive ? DkbColors.success : DkbColors.danger,
              size: 14,
            ),
            const SizedBox(width: 4),
            Text(
              GermanFormatter.waehrung(amount),
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

Widget buildFilterChip(String label, bool selected, VoidCallback onTap) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: selected ? DkbColors.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(DkbRadius.full),
        border: Border.all(
          color: selected ? DkbColors.primary : DkbColors.divider,
        ),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 13,
          color: selected ? Colors.white : DkbColors.textSecondary,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
    ),
  );
}

class _UmsatzSearch extends SearchDelegate<String> {
  final List<Umsatz> umsaetze;
  _UmsatzSearch(this.umsaetze);

  @override
  List<Widget> buildActions(BuildContext context) => [
        IconButton(icon: const Icon(Icons.clear), onPressed: () => query = ''),
      ];

  @override
  Widget buildLeading(BuildContext context) =>
      IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => close(context, ''));

  @override
  Widget buildResults(BuildContext context) {
    close(context, query);
    return const SizedBox.shrink();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final q = query.toLowerCase();
    final results = umsaetze.where((u) =>
        u.gegenpartei.toLowerCase().contains(q) ||
        u.verwendungszweck.toLowerCase().contains(q));
    return ListView(
      children: results
          .map((u) => UmsatzTile(umsatz: u))
          .toList(),
    );
  }
}
