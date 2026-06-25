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
          gradient: typ == KartenTyp.visa
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1A3A6B), Color(0xFF0D1A36)],
                )
              : const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF2E4080), Color(0xFF0D1A36)],
                ),
          boxShadow: [
            BoxShadow(
              color: DkbColors.primaryDeep.withValues(alpha: 0.4),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Decorative circles
            Positioned(
              right: -30,
              top: -30,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.03),
                ),
              ),
            ),
            Positioned(
              right: 30,
              bottom: -50,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.03),
                ),
              ),
            ),

            // Card content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top row: DKB logo + card type label
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // DKB logo image in frosted container
                      Container(
                        height: 30,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Image.asset(
                          'assets/images/dkb_logo.png',
                          fit: BoxFit.fitHeight,
                          errorBuilder: (context, err, _) => Text(
                            'DKB',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        label,
                        style: GoogleFonts.inter(
                          color: Colors.white.withValues(alpha: 0.65),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1.4,
                        ),
                      ),
                    ],
                  ),

                  const Spacer(),

                  // Middle: chip or VISA
                  if (typ == KartenTyp.girokonto)
                    _ChipIcon()
                  else
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'VISA',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          fontStyle: FontStyle.italic,
                          letterSpacing: 2,
                        ),
                      ),
                    ),

                  const SizedBox(height: 12),

                  // Bottom: IBAN / card number
                  Text(
                    kontonummerOderKarte,
                    style: GoogleFonts.ibmPlexMono(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontSize: 13,
                      letterSpacing: 2.5,
                    ),
                  ),

                  const SizedBox(height: 6),

                  // Balance row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            typ == KartenTyp.girokonto ? 'Kontostand' : 'Verfügbares Limit',
                            style: GoogleFonts.inter(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 10,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            GermanFormatter.waehrung(saldo),
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ],
                      ),
                      if (sublabel != null) ...[
                        const Spacer(),
                        Text(
                          sublabel!,
                          style: GoogleFonts.inter(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Gesperrt overlay
            if (isGesperrt)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(DkbRadius.lg),
                    color: Colors.black.withValues(alpha: 0.55),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: DkbColors.danger.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: DkbColors.danger.withValues(alpha: 0.4),
                            ),
                          ),
                          child: const Icon(Icons.lock, color: Colors.white, size: 28),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'GESPERRT',
                          style: GoogleFonts.inter(
                            color: DkbColors.danger,
                            fontSize: 14,
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

class _ChipIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 30,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE8C84A), Color(0xFFB8960C)],
        ),
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 4,
            offset: const Offset(1, 1),
          ),
        ],
      ),
      child: CustomPaint(painter: _ChipPainter()),
    );
  }
}

class _ChipPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFB8960C).withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    // Horizontal line
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      paint,
    );
    // Vertical center line
    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height),
      paint,
    );
    // Inner rectangle
    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height / 2),
        width: size.width * 0.55,
        height: size.height * 0.65,
      ),
      const Radius.circular(2),
    );
    canvas.drawRRect(rect, paint);
  }

  @override
  bool shouldRepaint(_) => false;
}
