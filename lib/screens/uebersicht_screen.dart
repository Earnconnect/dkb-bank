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
import '../widgets/quick_actions_widget.dart';
import 'ueberweisung_screen.dart';
import 'umsaetze_screen.dart';

class UebersichtScreen extends StatefulWidget {
  const UebersichtScreen({super.key});

  @override
  State<UebersichtScreen> createState() => _UebersichtScreenState();
}

class _UebersichtScreenState extends State<UebersichtScreen> {
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
    final giro = MockData.girokonto;
    final visa = MockData.visaKarte;
    final recentGiro = MockData.umsaetzeForGirokonto().take(5).toList();
    final recentVisa = MockData.umsaetzeForVisa().take(3).toList();
    final now = DateTime.now();
    final hour = now.hour;
    final greeting = hour < 12 ? 'Guten Morgen' : hour < 18 ? 'Guten Tag' : 'Guten Abend';

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App bar
          SliverAppBar(
            expandedHeight: 80,
            floating: true,
            backgroundColor: DkbColors.primary,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: DkbColors.primary,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                alignment: Alignment.bottomLeft,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$greeting,',
                          style: GoogleFonts.inter(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          MockData.user.name.split(' ').first,
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          MockData.user.initialen,
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Account cards
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      KontoKarteWidget(
                        typ: KartenTyp.girokonto,
                        kontonummerOderKarte: giro.ibanMaskiert,
                        saldo: giro.saldo,
                        label: 'GIROKONTO',
                        sublabel: 'Verfügbar: ${GermanFormatter.waehrung(giro.verfuegbar)}',
                      ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0),

                      const SizedBox(height: 12),

                      KontoKarteWidget(
                        typ: KartenTyp.visa,
                        kontonummerOderKarte: visa.maskedNummer,
                        saldo: visa.verfuegbaresLimit,
                        label: 'DKB-VISA',
                        sublabel:
                            'Verfügbares Limit: ${GermanFormatter.waehrung(visa.verfuegbaresLimit)}',
                        isGesperrt: !visa.isAktiv,
                      ).animate(delay: 100.ms).fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0),
                    ],
                  ),
                ),

                // Quick actions
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  child: QuickActionsWidget(
                    actions: [
                      QuickAction(
                        icon: Icons.send,
                        label: 'Überweisung',
                        onTap: () => Navigator.push(
                            context, fadeSlide(const UeberweisungScreen())),
                      ),
                      QuickAction(
                        icon: Icons.receipt_long_outlined,
                        label: 'Umsätze',
                        onTap: () => Navigator.push(
                            context, fadeSlide(const UmsaetzeScreen(kontoTyp: 'girokonto'))),
                      ),
                      QuickAction(
                        icon: visa.isAktiv ? Icons.lock_outlined : Icons.lock_open_outlined,
                        label: visa.isAktiv ? 'Karte sperren' : 'Karte entsperren',
                        onTap: () {
                          _state.karteGefrieren(visa.isAktiv);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(visa.isAktiv
                                  ? 'Karte wurde gesperrt'
                                  : 'Karte wurde entsperrt'),
                            ),
                          );
                        },
                        isAccent: true,
                      ),
                      QuickAction(
                        icon: Icons.repeat,
                        label: 'Dauerauftrag',
                        onTap: () => _state.setTab(4),
                      ),
                    ],
                  ),
                ).animate(delay: 200.ms).fadeIn(duration: 400.ms),

                // Recent Girokonto transactions
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Letzte Umsätze',
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

                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: DkbColors.surface,
                    borderRadius: BorderRadius.circular(DkbRadius.md),
                    boxShadow: DkbShadows.sm,
                  ),
                  child: Column(
                    children: recentGiro.asMap().entries.map((entry) {
                      final i = entry.key;
                      final u = entry.value;
                      return Column(
                        children: [
                          UmsatzTile(umsatz: u)
                              .animate(delay: (i * 50 + 250).ms)
                              .fadeIn(duration: 300.ms)
                              .slideX(begin: 0.03, end: 0),
                          if (i < recentGiro.length - 1)
                            const Divider(height: 1, indent: 70),
                        ],
                      );
                    }).toList(),
                  ),
                ),

                // Recent Visa transactions
                if (recentVisa.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Letzte Visa-Umsätze',
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
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: DkbColors.surface,
                      borderRadius: BorderRadius.circular(DkbRadius.md),
                      boxShadow: DkbShadows.sm,
                    ),
                    child: Column(
                      children: recentVisa.asMap().entries.map((entry) {
                        final i = entry.key;
                        final u = entry.value;
                        return Column(
                          children: [
                            UmsatzTile(umsatz: u),
                            if (i < recentVisa.length - 1)
                              const Divider(height: 1, indent: 70),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ],

                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
