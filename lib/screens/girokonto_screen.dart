import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../state/app_state.dart';
import '../data/mock_data.dart';
import '../models/umsatz.dart';
import '../utils/german_formatter.dart';
import '../utils/page_transitions.dart';
import '../widgets/umsatz_tile.dart';
import 'umsaetze_screen.dart';

class GirokontoScreen extends StatefulWidget {
  const GirokontoScreen({super.key});

  @override
  State<GirokontoScreen> createState() => _GirokontoScreenState();
}

class _GirokontoScreenState extends State<GirokontoScreen> {
  final _state = AppState();
  UmsatzTyp? _filter;

  void _refresh() => setState(() {});

  @override
  void initState() {
    super.initState();
    _state.addListener(_refresh);
  }

  @override
  void dispose() {
    _state.removeListener(_refresh);
    super.dispose();
  }

  void _copy(String value, String label) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label kopiert')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final giro = MockData.girokonto;
    final umsaetze = MockData.umsaetzeForGirokonto().where((u) {
      if (_filter != null) return u.typ == _filter;
      return true;
    }).take(15).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Girokonto')),
      body: ListView(
        children: [
          // Account info card
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: DkbColors.surface,
              borderRadius: BorderRadius.circular(DkbRadius.md),
              boxShadow: DkbShadows.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InfoRow(
                  label: 'Kontonummer',
                  value: giro.kontonummer,
                  onCopy: () => _copy(giro.kontonummer, 'Kontonummer'),
                ),
                const Divider(height: 16),
                _InfoRow(
                  label: 'IBAN',
                  value: giro.ibanFormatiert,
                  onCopy: () => _copy(giro.ibanFormatiert.replaceAll(' ', ''), 'IBAN'),
                ),
                const Divider(height: 16),
                _InfoRow(
                  label: 'BIC',
                  value: giro.bic,
                  onCopy: () => _copy(giro.bic, 'BIC'),
                ),
                const Divider(height: 20),

                // Balance
                Text(
                  'Saldo',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: DkbColors.textSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  GermanFormatter.waehrung(giro.saldo),
                  style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: DkbColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      'Verfügbar: ${GermanFormatter.waehrung(giro.verfuegbar)}',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: DkbColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '· Dispo: ${GermanFormatter.waehrung(giro.ueberziehungsrahmen)}',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: DkbColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Umsätze header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Umsätze',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: DkbColors.textPrimary,
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.push(
                      context, fadeSlide(const UmsaetzeScreen(kontoTyp: 'girokonto'))),
                  child: Text(
                    'Alle anzeigen',
                    style: GoogleFonts.inter(color: DkbColors.accent, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),

          // Filter chips
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _buildChip('Alle', _filter == null, () => setState(() => _filter = null)),
                const SizedBox(width: 8),
                _buildChip('Gutschriften', _filter == UmsatzTyp.gutschrift,
                    () => setState(() => _filter = UmsatzTyp.gutschrift)),
                const SizedBox(width: 8),
                _buildChip('Belastungen', _filter == UmsatzTyp.belastung,
                    () => setState(() => _filter = UmsatzTyp.belastung)),
              ],
            ),
          ),

          const SizedBox(height: 8),

          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: DkbColors.surface,
              borderRadius: BorderRadius.circular(DkbRadius.md),
              boxShadow: DkbShadows.xs,
            ),
            child: Column(
              children: umsaetze.asMap().entries.map((e) {
                return Column(
                  children: [
                    UmsatzTile(umsatz: e.value),
                    if (e.key < umsaetze.length - 1) const Divider(height: 1, indent: 70),
                  ],
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildChip(String label, bool selected, VoidCallback onTap) {
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
            fontSize: 12,
            color: selected ? Colors.white : DkbColors.textSecondary,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback? onCopy;

  const _InfoRow({required this.label, required this.value, this.onCopy});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: DkbColors.textSecondary,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.ibmPlexMono(
                  fontSize: 14,
                  color: DkbColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        if (onCopy != null)
          IconButton(
            onPressed: onCopy,
            icon: const Icon(Icons.copy_outlined, size: 16),
            color: DkbColors.textMuted,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
      ],
    );
  }
}
