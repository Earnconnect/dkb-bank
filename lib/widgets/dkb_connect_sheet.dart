import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../data/mock_data.dart';
import '../models/beneficiary.dart';
import '../services/api_service.dart';
import '../state/app_state.dart';

void showDkbConnectSheet(
  BuildContext context, {
  String? prefillName,
  String? prefillIban,
  VoidCallback? onSuccess,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => DkbConnectSheet(
      prefillName: prefillName,
      prefillIban: prefillIban,
      onSuccess: onSuccess,
    ),
  );
}

class DkbConnectSheet extends StatefulWidget {
  final String? prefillName;
  final String? prefillIban;
  final VoidCallback? onSuccess;

  const DkbConnectSheet({
    super.key,
    this.prefillName,
    this.prefillIban,
    this.onSuccess,
  });

  @override
  State<DkbConnectSheet> createState() => _DkbConnectSheetState();
}

class _DkbConnectSheetState extends State<DkbConnectSheet> {
  final _formKey = GlobalKey<FormState>();
  final _ktoCtrl = TextEditingController();
  final _pinCtrl = TextEditingController();
  bool _obscurePin = true;
  _Phase _phase = _Phase.form;
  String? _errorMsg;

  // Set when verify succeeds
  String? _verifiedName;
  String? _verifiedIban;
  String? _verifiedBic;

  @override
  void dispose() {
    _ktoCtrl.dispose();
    _pinCtrl.dispose();
    super.dispose();
  }

  Future<void> _verknuepfen() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _phase = _Phase.loading;
      _errorMsg = null;
    });

    final kto = _ktoCtrl.text.trim();
    final pin = _pinCtrl.text.trim();

    try {
      // Try live API first
      final result = await ApiService.instance.verifyAccount(kto, pin);
      if (!mounted) return;

      if (result['statusCode'] == 200) {
        _verifiedName = result['name'] as String?;
        _verifiedIban = result['iban'] as String?;
        _verifiedBic = result['bic'] as String? ?? 'SSKMDEMMXXX';
      } else {
        final msg = result['error'] as String? ?? 'Zugangsdaten nicht korrekt';
        setState(() {
          _phase = _Phase.form;
          _errorMsg = msg;
        });
        return;
      }
    } catch (_) {
      // Offline fallback: validate against MockData
      if (!mounted) return;
      if (!MockData.validateDkbAccount(kto, pin)) {
        setState(() {
          _phase = _Phase.form;
          _errorMsg = 'DKB-Konto nicht gefunden oder PIN ist falsch.';
        });
        return;
      }
      _verifiedName = MockData.dkbAccountName(kto);
      _verifiedIban = MockData.dkbAccountIban(kto);
      _verifiedBic = 'SSKMDEMMXXX';
    }

    // Already linked?
    if (AppState().isBeneficiary(_verifiedIban ?? '')) {
      setState(() {
        _phase = _Phase.form;
        _errorMsg = 'Dieses Konto ist bereits als Begünstigter hinterlegt.';
      });
      return;
    }

    // Save beneficiary
    final ben = Beneficiary(
      id: 'ben-${DateTime.now().millisecondsSinceEpoch}',
      name: _verifiedName ?? 'DKB Kontoinhaber',
      kontonummer: kto,
      iban: _verifiedIban ?? '',
      bic: _verifiedBic ?? 'SSKMDEMMXXX',
      verknuepftAm: DateTime.now(),
    );

    AppState().beneficiaryHinzufuegen(ben);

    if (!mounted) return;
    setState(() => _phase = _Phase.success);

    await Future.delayed(const Duration(milliseconds: 1800));
    if (!mounted) return;
    Navigator.pop(context);
    widget.onSuccess?.call();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(24, 0, 24, 24 + bottom),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        child: switch (_phase) {
          _Phase.success => _buildSuccess(),
          _Phase.loading => _buildLoading(),
          _Phase.form => _buildForm(),
        },
      ),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      key: const ValueKey('form'),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 14),
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFDDE1ED),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // DKB logo
            Center(
              child: Container(
                width: 150,
                height: 76,
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
            ),

            const SizedBox(height: 20),

            Center(
              child: Text(
                'Empfänger verknüpfen',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: DkbColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Center(
              child: Text(
                'Geben Sie die DKB-Zugangsdaten des Empfängers ein.\nDas Konto wird einmalig sicher verifiziert.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: DkbColors.textSecondary,
                  height: 1.45,
                ),
              ),
            ),

            const SizedBox(height: 18),

            // Security badge
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: DkbColors.success.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: DkbColors.success.withValues(alpha: 0.18)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified_user_outlined,
                      color: DkbColors.success, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Verschlüsselte Übertragung · Zugangsdaten werden nicht gespeichert',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: DkbColors.success,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Error banner
            if (_errorMsg != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: DkbColors.danger.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: DkbColors.danger.withValues(alpha: 0.25)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.error_outline, color: DkbColors.danger, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMsg!,
                        style: GoogleFonts.inter(fontSize: 13, color: DkbColors.danger),
                      ),
                    ),
                  ],
                ),
              ).animate().shake(),
              const SizedBox(height: 16),
            ],

            // Kontonummer
            _fieldLabel('Kontonummer des Empfängers'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _ktoCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(8),
              ],
              validator: (v) {
                if (v == null || v.isEmpty) return 'Kontonummer eingeben';
                if (v.length != 8) return 'Kontonummer besteht aus 8 Ziffern';
                return null;
              },
              decoration: const InputDecoration(
                hintText: '8-stellige Kontonummer',
                prefixIcon: Icon(Icons.person_outline, color: DkbColors.textMuted),
              ),
            ),

            const SizedBox(height: 14),

            // PIN
            _fieldLabel('Online-Banking-PIN des Empfängers'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _pinCtrl,
              obscureText: _obscurePin,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(4),
              ],
              validator: (v) {
                if (v == null || v.isEmpty) return 'PIN eingeben';
                if (v.length != 4) return 'PIN besteht aus 4 Ziffern';
                return null;
              },
              decoration: InputDecoration(
                hintText: '4-stellige PIN',
                prefixIcon: const Icon(Icons.lock_outline, color: DkbColors.textMuted),
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _obscurePin = !_obscurePin),
                  icon: Icon(
                    _obscurePin ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: DkbColors.textMuted,
                  ),
                ),
              ),
              onFieldSubmitted: (_) => _verknuepfen(),
            ),

            const SizedBox(height: 6),

            // Disclaimer
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Text(
                'Die Zugangsdaten des Empfängers werden ausschließlich zur einmaligen '
                'Verknüpfung verwendet und nicht auf unseren Servern gespeichert.',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: DkbColors.textMuted,
                  height: 1.5,
                ),
              ),
            ),

            const SizedBox(height: 22),

            ElevatedButton(
              onPressed: _verknuepfen,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                textStyle: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: const Text('Konto verknüpfen'),
            ),

            const SizedBox(height: 10),

            Center(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Abbrechen',
                  style: GoogleFonts.inter(
                    color: DkbColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return SizedBox(
      key: const ValueKey('loading'),
      height: 360,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated connection row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ConnectCircle(Icons.account_balance, DkbColors.primary),
              const SizedBox(width: 10),
              ...List.generate(
                5,
                (i) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: _AnimDot(delay: i * 160),
                ),
              ),
              const SizedBox(width: 10),
              _ConnectCircle(Icons.person_outline, DkbColors.accent),
            ],
          ),
          const SizedBox(height: 30),
          Text(
            'Konto wird verifiziert…',
            style: GoogleFonts.inter(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: DkbColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Zugangsdaten werden sicher geprüft',
            style: GoogleFonts.inter(fontSize: 13, color: DkbColors.textSecondary),
          ),
          const SizedBox(height: 30),
          const SizedBox(
            width: 200,
            child: LinearProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(DkbColors.accent),
              minHeight: 4,
              borderRadius: BorderRadius.all(Radius.circular(2)),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock, size: 12, color: DkbColors.textMuted),
              const SizedBox(width: 4),
              Text(
                'Gesicherte Verbindung · 256-Bit-Verschlüsselung',
                style: GoogleFonts.inter(fontSize: 11, color: DkbColors.textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSuccess() {
    return SizedBox(
      key: const ValueKey('success'),
      height: 340,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: DkbColors.success.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_outline,
                color: DkbColors.success, size: 40),
          )
              .animate()
              .scale(begin: const Offset(0.5, 0.5), curve: Curves.elasticOut),

          const SizedBox(height: 22),

          Text(
            'Konto erfolgreich verknüpft',
            style: GoogleFonts.inter(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: DkbColors.textPrimary,
            ),
          ).animate().fadeIn(delay: 200.ms),

          const SizedBox(height: 8),

          Text(
            _verifiedName ?? '',
            style: GoogleFonts.inter(
              fontSize: 15,
              color: DkbColors.accent,
              fontWeight: FontWeight.w600,
            ),
          ).animate().fadeIn(delay: 280.ms),

          const SizedBox(height: 6),

          Text(
            'wurde als Begünstigter gespeichert.\nSie können jetzt an dieses Konto überweisen.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: DkbColors.textSecondary,
              height: 1.5,
            ),
          ).animate().fadeIn(delay: 340.ms),
        ],
      ),
    );
  }

  Widget _fieldLabel(String text) => Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: DkbColors.textSecondary,
        ),
      );
}

class _ConnectCircle extends StatelessWidget {
  final IconData icon;
  final Color color;
  const _ConnectCircle(this.icon, this.color);

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

class _AnimDot extends StatefulWidget {
  final int delay;
  const _AnimDot({required this.delay});
  @override
  State<_AnimDot> createState() => _AnimDotState();
}

class _AnimDotState extends State<_AnimDot> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _anim = Tween<double>(begin: 0.2, end: 1.0)
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

enum _Phase { form, loading, success }
