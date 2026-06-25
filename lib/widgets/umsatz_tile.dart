import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/umsatz.dart';
import '../theme/app_theme.dart';
import '../utils/german_formatter.dart';
import 'umsatz_detail_sheet.dart';

class UmsatzTile extends StatelessWidget {
  final Umsatz umsatz;

  const UmsatzTile({super.key, required this.umsatz});

  static Color _categoryColor(UmsatzKategorie kategorie, bool isGutschrift) {
    if (isGutschrift) return DkbColors.success;
    switch (kategorie) {
      case UmsatzKategorie.gehalt:
        return DkbColors.success;
      case UmsatzKategorie.miete:
        return const Color(0xFF009688);
      case UmsatzKategorie.lebensmittel:
        return const Color(0xFFFF6B35);
      case UmsatzKategorie.transport:
        return const Color(0xFF3498DB);
      case UmsatzKategorie.unterhaltung:
        return const Color(0xFF9B59B6);
      case UmsatzKategorie.gesundheit:
        return const Color(0xFFE74C3C);
      case UmsatzKategorie.versicherung:
        return const Color(0xFF2980B9);
      case UmsatzKategorie.abonnement:
        return const Color(0xFF8E44AD);
      case UmsatzKategorie.onlineEinkauf:
        return const Color(0xFFE67E22);
      case UmsatzKategorie.restaurant:
        return const Color(0xFFF39C12);
      case UmsatzKategorie.ueberweisung:
        return DkbColors.accent;
      case UmsatzKategorie.gebuehr:
        return const Color(0xFF7F8C8D);
      case UmsatzKategorie.sonstiges:
        return DkbColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isGut = umsatz.isGutschrift;
    final color = _categoryColor(umsatz.kategorie, isGut);

    return InkWell(
      onTap: () => showUmsatzDetail(context, umsatz),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            // Circular category icon
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(umsatz.kategorieIcon, color: color, size: 21),
            ),

            const SizedBox(width: 13),

            // Title and subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    umsatz.gegenpartei,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: DkbColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    umsatz.verwendungszweck.isNotEmpty
                        ? umsatz.verwendungszweck
                        : umsatz.kategorieLabel,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: DkbColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (umsatz.istVormerkung) ...[
                    const SizedBox(height: 3),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: DkbColors.warning.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Vorgemerkt',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: DkbColors.warning,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(width: 12),

            // Amount and date (right-aligned)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isGut ? '+' : '−'}${GermanFormatter.waehrung(umsatz.betrag)}',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isGut ? DkbColors.success : DkbColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  GermanFormatter.datumKurz(umsatz.buchungsdatum),
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: DkbColors.textMuted,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
