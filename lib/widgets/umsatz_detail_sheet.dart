import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/umsatz.dart';
import '../theme/app_theme.dart';
import '../utils/german_formatter.dart';

void showUmsatzDetail(BuildContext context, Umsatz umsatz) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _UmsatzDetailSheet(umsatz: umsatz),
  );
}

class _UmsatzDetailSheet extends StatelessWidget {
  final Umsatz umsatz;

  const _UmsatzDetailSheet({required this.umsatz});

  @override
  Widget build(BuildContext context) {
    final isGut = umsatz.isGutschrift;

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DkbColors.surface,
        borderRadius: BorderRadius.circular(DkbRadius.xl),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: DkbColors.divider,
                borderRadius: BorderRadius.circular(DkbRadius.full),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Type badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: isGut
                  ? DkbColors.success.withValues(alpha: 0.12)
                  : DkbColors.danger.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(DkbRadius.full),
            ),
            child: Text(
              umsatz.typLabel,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isGut ? DkbColors.success : DkbColors.danger,
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Amount
          Text(
            '${isGut ? '+' : '−'}${GermanFormatter.waehrung(umsatz.betrag)}',
            style: GoogleFonts.inter(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: isGut ? DkbColors.success : DkbColors.textPrimary,
            ),
          ),

          const SizedBox(height: 4),
          Text(
            umsatz.gegenpartei,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: DkbColors.textPrimary,
            ),
          ),

          const SizedBox(height: 20),
          const Divider(height: 1),

          // Detail rows
          _DetailRow('Verwendungszweck', umsatz.verwendungszweck),
          _DetailRow('Buchungsdatum', GermanFormatter.datum(umsatz.buchungsdatum)),
          _DetailRow('Wertstellung', GermanFormatter.datum(umsatz.wertstellung)),
          _DetailRow('Kategorie', umsatz.kategorieLabel),
          if (umsatz.referenznummer != null)
            _DetailRow('Referenz', umsatz.referenznummer!),
          if (umsatz.istVormerkung)
            _DetailRow('Status', 'Vorgemerkt'),

          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(
                  text: '${umsatz.gegenpartei}\n${umsatz.verwendungszweck}\n'
                      '${GermanFormatter.datum(umsatz.buchungsdatum)}\n'
                      '${isGut ? '+' : '-'}${GermanFormatter.waehrung(umsatz.betrag)}',
                ));
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Details kopiert')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: DkbColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Schließen'),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: DkbColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: DkbColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
