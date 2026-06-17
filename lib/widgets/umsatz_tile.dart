import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/umsatz.dart';
import '../theme/app_theme.dart';
import '../utils/german_formatter.dart';
import 'umsatz_detail_sheet.dart';

class UmsatzTile extends StatelessWidget {
  final Umsatz umsatz;

  const UmsatzTile({super.key, required this.umsatz});

  @override
  Widget build(BuildContext context) {
    final isGut = umsatz.isGutschrift;

    return InkWell(
      onTap: () => showUmsatzDetail(context, umsatz),
      borderRadius: BorderRadius.circular(DkbRadius.md),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Category icon
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: isGut
                    ? DkbColors.success.withValues(alpha: 0.12)
                    : DkbColors.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(DkbRadius.sm),
              ),
              child: Icon(
                umsatz.kategorieIcon,
                color: isGut ? DkbColors.success : DkbColors.primary,
                size: 20,
              ),
            ),

            const SizedBox(width: 12),

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
                    umsatz.verwendungszweck,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: DkbColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (umsatz.istVormerkung) ...[
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: DkbColors.warning.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(DkbRadius.xs),
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

            // Amount and date
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
