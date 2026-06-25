import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../state/app_state.dart';
import '../data/mock_data.dart';
import '../models/umsatz.dart';
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

  String _dateLabel(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final date = DateTime(d.year, d.month, d.day);
    if (date == today) return 'Heute';
    if (date == yesterday) return 'Gestern';
    return GermanFormatter.datum(d);
  }

  Map<String, List<Umsatz>> _groupByDate(List<Umsatz> umsaetze) {
    final result = <String, List<Umsatz>>{};
    for (final u in umsaetze) {
      result.putIfAbsent(_dateLabel(u.buchungsdatum), () => []).add(u);
    }
    return result;
  }

  List<Widget> _buildGroupedList(List<Umsatz> umsaetze) {
    final groups = _groupByDate(umsaetze);
    final widgets = <Widget>[];
    for (final entry in groups.entries) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(
            entry.key,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: DkbColors.textSecondary,
              letterSpacing: 0.3,
            ),
          ),
        ),
      );
      widgets.add(
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: DkbColors.surface,
            borderRadius: BorderRadius.circular(DkbRadius.md),
            boxShadow: DkbShadows.sm,
          ),
          child: Column(
            children: entry.value.asMap().entries.map((e) {
              return Column(
                children: [
                  UmsatzTile(umsatz: e.value),
                  if (e.key < entry.value.length - 1)
                    const Divider(height: 1, indent: 75),
                ],
              );
            }).toList(),
          ),
        ),
      );
    }
    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    final giro = MockData.girokonto;
    final visa = MockData.visaKarte;
    final recentGiro = MockData.umsaetzeForGirokonto().take(5).toList();
    final recentVisa = MockData.umsaetzeForVisa().take(3).toList();
    final now = DateTime.now();
    final hour = now.hour;
    final greeting =
        hour < 12 ? 'Guten Morgen' : hour < 18 ? 'Guten Tag' : 'Guten Abend';
    final firstName = MockData.user.name.split(' ').first;

    return Scaffold(
      backgroundColor: DkbColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: DkbColors.textPrimary,
        elevation: 0,
        automaticallyImplyLeading: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: DkbColors.divider),
        ),
        title: SizedBox(
          height: 28,
          child: Image.asset(
            'assets/images/dkb_logo.png',
            fit: BoxFit.fitHeight,
            errorBuilder: (context, err, _) => Text(
              'DKB',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: DkbColors.primary,
                letterSpacing: 2,
              ),
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, size: 22),
            color: DkbColors.textSecondary,
            onPressed: () {},
            padding: EdgeInsets.zero,
          ),
          const SizedBox(width: 4),
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: DkbColors.primary,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  MockData.user.initialen,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        children: [
          // ── Balance hero banner ────────────────────────────────────────────
          Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF2E4080), Color(0xFF0D1A36)],
              ),
              borderRadius: BorderRadius.circular(DkbRadius.xl),
              boxShadow: [
                BoxShadow(
                  color: DkbColors.primaryDeep.withValues(alpha: 0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$greeting, $firstName',
                  style: GoogleFonts.inter(
                    color: Colors.white.withValues(alpha: 0.65),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  GermanFormatter.waehrung(giro.saldo),
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      'Girokonto',
                      style: GoogleFonts.inter(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Verfügbar: ${GermanFormatter.waehrung(giro.verfuegbar)}',
                      style: GoogleFonts.inter(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.04, end: 0),

          // ── Konten section ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
            child: Text(
              'Meine Konten',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: DkbColors.textPrimary,
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: KontoKarteWidget(
              typ: KartenTyp.girokonto,
              kontonummerOderKarte: giro.ibanMaskiert,
              saldo: giro.saldo,
              label: 'GIROKONTO',
              sublabel: GermanFormatter.waehrung(giro.verfuegbar),
            ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0),
          ),

          const SizedBox(height: 12),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: KontoKarteWidget(
              typ: KartenTyp.visa,
              kontonummerOderKarte: visa.maskedNummer,
              saldo: visa.verfuegbaresLimit,
              label: 'DKB-VISA',
              isGesperrt: !visa.isAktiv,
            ).animate(delay: 80.ms).fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0),
          ),

          // ── Quick actions ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 10),
            child: Text(
              'Schnellzugriff',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: DkbColors.textPrimary,
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: QuickActionsWidget(
              actions: [
                QuickAction(
                  icon: Icons.send_outlined,
                  label: 'Überweisung',
                  onTap: () => Navigator.push(
                      context, fadeSlide(const UeberweisungScreen())),
                ),
                QuickAction(
                  icon: Icons.receipt_long_outlined,
                  label: 'Umsätze',
                  onTap: () => Navigator.push(
                      context,
                      fadeSlide(const UmsaetzeScreen(kontoTyp: 'girokonto'))),
                ),
                QuickAction(
                  icon: visa.isAktiv
                      ? Icons.lock_outlined
                      : Icons.lock_open_outlined,
                  label: visa.isAktiv ? 'Karte sperren' : 'Entsperren',
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
                  icon: Icons.repeat_outlined,
                  label: 'Dauerauftrag',
                  onTap: () => _state.setTab(4),
                ),
              ],
            ).animate(delay: 160.ms).fadeIn(duration: 400.ms),
          ),

          // ── Recent Girokonto transactions ─────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Letzte Umsätze',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: DkbColors.textPrimary,
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.push(context,
                      fadeSlide(const UmsaetzeScreen(kontoTyp: 'girokonto'))),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Alle anzeigen',
                    style: GoogleFonts.inter(
                        color: DkbColors.accent,
                        fontSize: 13,
                        fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),

          ..._buildGroupedList(recentGiro),

          // ── Recent Visa transactions ───────────────────────────────────────
          if (recentVisa.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Letzte Visa-Umsätze',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: DkbColors.textPrimary,
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.push(
                        context, fadeSlide(const UmsaetzeScreen(kontoTyp: 'visa'))),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Alle anzeigen',
                      style: GoogleFonts.inter(
                          color: DkbColors.accent,
                          fontSize: 13,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
            ..._buildGroupedList(recentVisa),
          ],

          const SizedBox(height: 36),
        ],
      ),
    );
  }
}
