import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

// Plaid-style fullscreen overlay that shows loading → error for non-DKB IBANs
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
      duration: const Duration(milliseconds: 2400),
    );
    _runFlow();
  }

  Future<void> _runFlow() async {
    _progressCtrl.forward();

    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;
    setState(() => _phase = _Phase.processing);

    await Future.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;
    setState(() => _phase = _Phase.failed);
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
            duration: const Duration(milliseconds: 400),
            child: _phase == _Phase.failed ? _buildFailed() : _buildLoading(),
          ),
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return Column(
      key: const ValueKey('loading'),
      children: [
        const SizedBox(height: 48),

        // DKB logo card
        Container(
          width: 160,
          height: 86,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE8EAF0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(10),
          child: Image.asset('assets/images/dkb_logo.png', fit: BoxFit.contain),
        ),

        const SizedBox(height: 32),

        // Animated connection dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _BankIcon(Icons.account_balance, DkbColors.primary),
            const SizedBox(width: 12),
            ...List.generate(
              4,
              (i) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: _DotPulse(delay: i * 200),
              ),
            ),
            const SizedBox(width: 12),
            _BankIcon(Icons.person_outline, DkbColors.accent),
          ],
        ),

        const SizedBox(height: 32),

        Text(
          _phase == _Phase.connecting
              ? 'Verbindung wird aufgebaut...'
              : 'Überweisung wird verarbeitet...',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: DkbColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Bitte warten Sie einen Moment',
          style: GoogleFonts.inter(
            fontSize: 13,
            color: DkbColors.textSecondary,
          ),
        ),

        const SizedBox(height: 32),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 48),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: AnimatedBuilder(
              animation: _progressCtrl,
              builder: (_, _) => LinearProgressIndicator(
                value: _progressCtrl.value,
                backgroundColor: const Color(0xFFE8EAF0),
                valueColor: AlwaysStoppedAnimation<Color>(DkbColors.accent),
                minHeight: 5,
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        Text(
          'Gesicherte Verbindung · 256-Bit-Verschlüsselung',
          style: GoogleFonts.inter(
            fontSize: 11,
            color: DkbColors.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildFailed() {
    return Padding(
      key: const ValueKey('failed'),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 40),

          // DKB logo small
          Container(
            width: 120,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE8EAF0)),
            ),
            padding: const EdgeInsets.all(8),
            child: Image.asset('assets/images/dkb_logo.png', fit: BoxFit.contain),
          ),

          const SizedBox(height: 28),

          // Error icon
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: DkbColors.danger.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.cancel_outlined, color: DkbColors.danger, size: 38),
          )
              .animate()
              .scale(begin: const Offset(0.6, 0.6), curve: Curves.elasticOut),

          const SizedBox(height: 20),

          Text(
            'Überweisung nicht möglich',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: DkbColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 200.ms),

          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F8FC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE8EAF0)),
            ),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline,
                        color: DkbColors.textSecondary, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Diese Überweisung konnte nicht verarbeitet werden.',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: DkbColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Externe Bankkonten (Nicht-DKB) werden nicht direkt unterstützt. '
                  'Um an diesen Empfänger zu überweisen, müssen Sie ihn zuerst als '
                  'Begünstigten hinzufügen — der Empfänger muss über ein DKB-Konto verfügen.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: DkbColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 300.ms),

          const SizedBox(height: 16),

          // Recipient info
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: DkbColors.danger.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(8),
              border:
                  Border.all(color: DkbColors.danger.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.block, color: DkbColors.danger, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.recipientName,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: DkbColors.textPrimary,
                        ),
                      ),
                      Text(
                        widget.iban,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: DkbColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 350.ms),

          const Spacer(),

          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              widget.onAddBeneficiary();
            },
            icon: const Icon(Icons.person_add_outlined, size: 18),
            label: const Text('Begünstigten hinzufügen'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
            ),
          ).animate().fadeIn(delay: 450.ms),

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
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// Animated pulsing dot
class _DotPulse extends StatefulWidget {
  final int delay;
  const _DotPulse({required this.delay});

  @override
  State<_DotPulse> createState() => _DotPulseState();
}

class _DotPulseState extends State<_DotPulse>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _anim = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
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

class _BankIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  const _BankIcon(this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }
}

enum _Phase { connecting, processing, failed }
