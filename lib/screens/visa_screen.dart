import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../state/app_state.dart';
import '../data/mock_data.dart';
import '../utils/german_formatter.dart';
import '../utils/page_transitions.dart';
import '../widgets/konto_karte_widget.dart';
import '../widgets/umsatz_tile.dart';
import 'umsaetze_screen.dart';

class VisaScreen extends StatefulWidget {
  const VisaScreen({super.key});

  @override
  State<VisaScreen> createState() => _VisaScreenState();
}

class _VisaScreenState extends State<VisaScreen> {
  final _state = AppState();

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

  @override
  Widget build(BuildContext context) {
    final visa = MockData.visaKarte;
    final visaUmsaetze = MockData.umsaetzeForVisa().take(5).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('DKB-Visa')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Card visualization
          KontoKarteWidget(
            typ: KartenTyp.visa,
            kontonummerOderKarte: visa.maskedNummer,
            saldo: visa.verfuegbaresLimit,
            label: 'DKB-VISA',
            sublabel: visa.karteninhaber,
            isGesperrt: !visa.isAktiv,
          ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.95, 0.95)),

          const SizedBox(height: 16),

          // Status + freeze toggle
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: DkbColors.surface,
              borderRadius: BorderRadius.circular(DkbRadius.md),
              boxShadow: DkbShadows.sm,
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: visa.isAktiv
                            ? DkbColors.success.withValues(alpha: 0.12)
                            : DkbColors.danger.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(DkbRadius.full),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: visa.isAktiv ? DkbColors.success : DkbColors.danger,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            visa.statusLabel,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: visa.isAktiv ? DkbColors.success : DkbColors.danger,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Text(
                      visa.isAktiv ? 'Karte sperren' : 'Karte entsperren',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: DkbColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Switch(
                      value: !visa.isAktiv,
                      onChanged: (val) {
                        _state.karteGefrieren(val);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(val
                                ? 'Karte wurde gesperrt'
                                : 'Karte wurde entsperrt'),
                          ),
                        );
                      },
                    ),
                  ],
                ),

                const Divider(height: 20),

                // Card actions
                Row(
                  children: [
                    Expanded(
                      child: _CardAction(
                        icon: Icons.visibility_outlined,
                        label: 'Kartendaten',
                        onTap: () => _showKartendaten(context),
                      ),
                    ),
                    Expanded(
                      child: _CardAction(
                        icon: Icons.lock_reset_outlined,
                        label: 'PIN ändern',
                        onTap: () => Navigator.pushNamed(context, '/pin-aendern'),
                      ),
                    ),
                    Expanded(
                      child: _CardAction(
                        icon: Icons.receipt_outlined,
                        label: 'Abrechnung',
                        onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Funktion in Kürze verfügbar')),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Credit info card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: DkbColors.surface,
              borderRadius: BorderRadius.circular(DkbRadius.md),
              boxShadow: DkbShadows.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kreditrahmen',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: DkbColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                _CreditRow('Kreditlimit', GermanFormatter.waehrung(visa.kreditlimit)),
                const SizedBox(height: 8),
                _CreditRow('Aktueller Saldo',
                    GermanFormatter.waehrung(visa.aktuellerSaldo),
                    valueColor: DkbColors.danger),
                const SizedBox(height: 8),
                _CreditRow('Verfügbares Limit',
                    GermanFormatter.waehrung(visa.verfuegbaresLimit),
                    valueColor: DkbColors.success),

                const SizedBox(height: 16),

                // Utilization bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(DkbRadius.full),
                  child: LinearProgressIndicator(
                    value: visa.auslastungProzent.clamp(0.0, 1.0),
                    minHeight: 8,
                    backgroundColor: DkbColors.divider,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      visa.auslastungProzent > 0.8 ? DkbColors.danger : DkbColors.accent,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${(visa.auslastungProzent * 100).toStringAsFixed(1)} % des Limits genutzt',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: DkbColors.textMuted,
                  ),
                ),

                const Divider(height: 20),

                _CreditRow(
                  'Abrechnungsperiode',
                  '${GermanFormatter.datumKurz(visa.abrechnungsperiodeBeginn)} – '
                      '${GermanFormatter.datum(visa.abrechnungsperiodeEnde)}',
                ),
                const SizedBox(height: 8),
                _CreditRow(
                  'Ablaufdatum',
                  visa.ablaufdatum,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Visa transactions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Visa-Umsätze',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: DkbColors.textPrimary,
                ),
              ),
              TextButton(
                onPressed: () => Navigator.push(
                    context, fadeSlide(const UmsaetzeScreen(kontoTyp: 'visa'))),
                child: Text(
                  'Alle anzeigen',
                  style: GoogleFonts.inter(color: DkbColors.accent, fontSize: 13),
                ),
              ),
            ],
          ),

          Container(
            decoration: BoxDecoration(
              color: DkbColors.surface,
              borderRadius: BorderRadius.circular(DkbRadius.md),
              boxShadow: DkbShadows.xs,
            ),
            child: visaUmsaetze.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(20),
                    child: Center(
                      child: Text(
                        'Keine Umsätze',
                        style: GoogleFonts.inter(color: DkbColors.textMuted),
                      ),
                    ),
                  )
                : Column(
                    children: visaUmsaetze.asMap().entries.map((e) {
                      return Column(
                        children: [
                          UmsatzTile(umsatz: e.value),
                          if (e.key < visaUmsaetze.length - 1)
                            const Divider(height: 1, indent: 70),
                        ],
                      );
                    }).toList(),
                  ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _showKartendaten(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          'Kartendaten',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Aus Sicherheitsgründen werden vollständige Kartendaten nicht angezeigt.',
                style: GoogleFonts.inter(fontSize: 13, color: DkbColors.textSecondary)),
            const SizedBox(height: 12),
            Text('Kartennummer: ${MockData.visaKarte.maskedNummer}',
                style: GoogleFonts.ibmPlexMono(fontSize: 13)),
            Text('Ablauf: ${MockData.visaKarte.ablaufdatum}',
                style: GoogleFonts.inter(fontSize: 13)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Schließen'),
          ),
        ],
      ),
    );
  }
}

class _CardAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _CardAction({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: DkbColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(DkbRadius.sm),
            ),
            child: Icon(icon, color: DkbColors.primary, size: 20),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 11, color: DkbColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _CreditRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _CreditRow(this.label, this.value, {this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 13, color: DkbColors.textSecondary),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: valueColor ?? DkbColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
