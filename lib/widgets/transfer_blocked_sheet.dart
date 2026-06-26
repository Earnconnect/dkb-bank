import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class TransferBlockedSheet extends StatefulWidget {
  final String recipientName;
  final String iban;
  final VoidCallback onAddBeneficiary;

  const TransferBlockedSheet({
    super.key,
    required this.recipientName,
    required this.iban,
    required this.onAddBeneficiary,
  });

  @override
  State<TransferBlockedSheet> createState() => _TransferBlockedSheetState();
}

class _TransferBlockedSheetState extends State<TransferBlockedSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _progressCtrl;
  _Phase _phase = _Phase.connecting;

  @override
  void initState() {
    super.initState();
    _progressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );
    _runFlow();
  }

  Future<void> _runFlow() async {
    _progressCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 1100));
    if (!mounted) return;
    setState(() => _phase = _Phase.processing);
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;
    setState(() => _phase = _Phase.blocked);
  }

  @override
  void dispose() {
    _progressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.white,
        child: SafeArea(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 450),
            child: _phase == _Phase.blocked ? _buildBlocked() : _buildChecking(),
          ),
        ),
      ),
    );
  }

  Widget _buildChecking() {
    return Column(
      key: const ValueKey('checking'),
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 40),

        // DKB logo
        Container(
          width: 160,
          height: 84,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE4E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.07),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(10),
          child: Image.asset('assets/images/dkb_logo.png', fit: BoxFit.contain),
        ),

        const SizedBox(height: 36),

        // Animated connection row
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _CircleIcon(Icons.account_balance, DkbColors.primary),
            const SizedBox(width: 10),
            ...List.generate(
              5,
              (i) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: _PulsingDot(delay: i * 160),
              ),
            ),
            const SizedBox(width: 10),
            _CircleIcon(Icons.person_search_outlined, DkbColors.accent),
          ],
        ),

        const SizedBox(height: 28),

        Text(
          _phase == _Phase.connecting
              ? 'Sicherheitsüberprüfung läuft…'
              : 'Begünstigtenliste wird geprüft…',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: DkbColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Bitte warten Sie einen Moment.',
          style: GoogleFonts.inter(fontSize: 13, color: DkbColors.textSecondary),
        ),

        const SizedBox(height: 30),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 52),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: AnimatedBuilder(
              animation: _progressCtrl,
              builder: (_, _) => LinearProgressIndicator(
                value: _progressCtrl.value,
                backgroundColor: const Color(0xFFE4E8F0),
                valueColor: AlwaysStoppedAnimation<Color>(DkbColors.accent),
                minHeight: 4,
              ),
            ),
          ),
        ),

        const SizedBox(height: 14),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock, size: 12, color: DkbColors.textMuted),
            const SizedBox(width: 4),
            Text(
              'Gesicherte Verbindung · TLS 1.3 · 256-Bit-Verschlüsselung',
              style: GoogleFonts.inter(fontSize: 11, color: DkbColors.textMuted),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBlocked() {
    return Stack(
      key: const ValueKey('blocked'),
      children: [
        // Close button — absolute top-right
        Positioned(
          top: 12,
          right: 8,
          child: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, color: DkbColors.textSecondary, size: 22),
          ),
        ),

        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // DKB logo — centered
              Container(
                width: 120,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE4E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(10),
                child: Image.asset('assets/images/dkb_logo.png', fit: BoxFit.contain),
              ),

              const SizedBox(height: 28),

              // Error icon — centered, large
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: DkbColors.danger.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: DkbColors.danger.withValues(alpha: 0.18),
                    width: 2,
                  ),
                ),
                child: const Icon(Icons.block_rounded, color: DkbColors.danger, size: 38),
              )
                  .animate()
                  .scale(begin: const Offset(0.5, 0.5), curve: Curves.elasticOut)
                  .fadeIn(),

              const SizedBox(height: 22),

              // Title — centered
              Text(
                'Überweisung nicht möglich',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: DkbColors.textPrimary,
                  letterSpacing: -0.3,
                ),
              ).animate().fadeIn(delay: 150.ms),

              const SizedBox(height: 10),

              // Subtitle — centered
              Text(
                'Dieser Empfänger ist in Ihrem\nOnline-Banking nicht als Begünstigter hinterlegt.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: DkbColors.textSecondary,
                  height: 1.55,
                ),
              ).animate().fadeIn(delay: 200.ms),

              const SizedBox(height: 24),

              // Recipient card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F8FC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE4E8F0)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: DkbColors.danger.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.person_off_outlined,
                          color: DkbColors.danger, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (widget.recipientName.isNotEmpty)
                            Text(
                              widget.recipientName,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: DkbColors.textPrimary,
                              ),
                            ),
                          const SizedBox(height: 2),
                          Text(
                            widget.iban,
                            style: GoogleFonts.ibmPlexMono(
                              fontSize: 12,
                              color: DkbColors.textSecondary,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: DkbColors.danger.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'NICHT\nVERIFIZIERT',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                          color: DkbColors.danger,
                          letterSpacing: 0.4,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 250.ms),

              const SizedBox(height: 14),

              // Info box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: DkbColors.primary.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: DkbColors.primary.withValues(alpha: 0.12)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.shield_outlined, size: 15, color: DkbColors.primary),
                        const SizedBox(width: 6),
                        Text(
                          'Hinweis zur Sicherheit',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: DkbColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Aus Sicherheitsgründen sind Überweisungen ausschließlich an '
                      'verifizierte Begünstigte möglich. Der Empfänger muss Inhaber '
                      'eines DKB-Girokontos sein und einmalig mit seinen DKB-Zugangsdaten '
                      'in Ihrem Online-Banking verknüpft werden.',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: DkbColors.textSecondary,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 300.ms),

              const SizedBox(height: 28),

              // CTA button
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  widget.onAddBeneficiary();
                },
                icon: const Icon(Icons.link_rounded, size: 18),
                label: const Text('Empfänger jetzt verknüpfen'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                  backgroundColor: DkbColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ).animate().fadeIn(delay: 380.ms).slideY(begin: 0.2, end: 0),

              const SizedBox(height: 12),

              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Schließen',
                  style: GoogleFonts.inter(
                    color: DkbColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ).animate().fadeIn(delay: 420.ms),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ],
    );
  }
}

class _PulsingDot extends StatefulWidget {
  final int delay;
  const _PulsingDot({required this.delay});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 750));
    _anim = Tween<double>(begin: 0.25, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _ctrl.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, _) => Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: DkbColors.accent.withValues(alpha: _anim.value),
        ),
      ),
    );
  }
}

class _CircleIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  const _CircleIcon(this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }
}

enum _Phase { connecting, processing, blocked }
