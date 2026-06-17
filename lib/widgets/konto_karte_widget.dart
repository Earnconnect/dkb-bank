import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../utils/german_formatter.dart';

enum KartenTyp { girokonto, visa }

class KontoKarteWidget extends StatelessWidget {
  final KartenTyp typ;
  final String kontonummerOderKarte;
  final double saldo;
  final String label;
  final String? sublabel;
  final bool isGesperrt;

  const KontoKarteWidget({
    super.key,
    required this.typ,
    required this.kontonummerOderKarte,
    required this.saldo,
    required this.label,
    this.sublabel,
    this.isGesperrt = false,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.586,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(DkbRadius.lg),
          gradient: DkbColors.cardGradient,
          boxShadow: DkbShadows.xl,
        ),
        child: Stack(
          children: [
            // Background pattern dots
            Positioned(
              right: -20,
              top: -20,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.04),
                ),
              ),
            ),
            Positioned(
              right: 20,
              bottom: -40,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.04),
                ),
              ),
            ),

            // Card content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top row: DKB logo + card type
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _DkbLogo(),
                      Text(
                        label,
                        style: GoogleFonts.inter(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),

                  const Spacer(),

                  // Chip icon (for girokonto) or VISA logo
                  if (typ == KartenTyp.girokonto)
                    _ChipIcon()
                  else
                    Text(
                      'VISA',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        fontStyle: FontStyle.italic,
                        letterSpacing: 2,
                      ),
                    ),

                  const SizedBox(height: 10),

                  // Card number / IBAN
                  Text(
                    kontonummerOderKarte,
                    style: GoogleFonts.ibmPlexMono(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 13,
                      letterSpacing: 2,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Balance
                  Text(
                    GermanFormatter.waehrung(saldo),
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  if (sublabel != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      sublabel!,
                      style: GoogleFonts.inter(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Gesperrt overlay
            if (isGesperrt)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(DkbRadius.lg),
                    color: Colors.black.withValues(alpha: 0.5),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.lock, color: Colors.white, size: 32),
                        const SizedBox(height: 6),
                        Text(
                          'GESPERRT',
                          style: GoogleFonts.inter(
                            color: DkbColors.danger,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DkbLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Text(
        'DKB',
        style: GoogleFonts.inter(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}

class _ChipIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 28,
      decoration: BoxDecoration(
        color: Colors.amber.shade300,
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(1, 1),
          ),
        ],
      ),
      child: Stack(
        children: [
          Center(
            child: Container(
              width: 20,
              height: 16,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.amber.shade600, width: 1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 10,
            child: Container(height: 1, color: Colors.amber.shade600),
          ),
          Positioned(
            left: 18,
            top: 0,
            bottom: 0,
            child: Container(width: 1, color: Colors.amber.shade600),
          ),
        ],
      ),
    );
  }
}
