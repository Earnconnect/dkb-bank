import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../data/mock_data.dart';
import '../models/beneficiary.dart';
import '../state/app_state.dart';

// Plaid-style "DKB Konto verknüpfen" bottom sheet
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
  _ConnectState _state = _ConnectState.idle;
  String? _errorMsg;

  @override
  void dispose() {
    _ktoCtrl.dispose();
    _pinCtrl.dispose();
    super.dispose();
  }

  Future<void> _verknuepfen() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _state = _ConnectState.loading;
      _errorMsg = null;
    });

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 2200));
    if (!mounted) return;

    final kto = _ktoCtrl.text.trim();
    final pin = _pinCtrl.text.trim();

    if (!MockData.validateDkbAccount(kto, pin)) {
      setState(() {
        _state = _ConnectState.error;
        _errorMsg = 'Kontonummer oder PIN ist falsch. Bitte überprüfen Sie die '
            'Zugangsdaten des Empfängers.';
      });
      return;
    }

    // Already a beneficiary?
    final existingIban = MockData.dkbAccountIban(kto);
    if (AppState().isBeneficiary(existingIban)) {
      setState(() {
        _state = _ConnectState.error;
        _errorMsg = 'Dieses Konto ist bereits als Begünstigter hinterlegt.';
      });
      return;
    }

    final newBen = Beneficiary(
      id: 'ben-${DateTime.now().millisecondsSinceEpoch}',
      name: MockData.dkbAccountName(kto),
      kontonummer: kto,
      iban: existingIban,
      bic: 'SSKMDEMMXXX',
      verknuepftAm: DateTime.now(),
    );

    AppState().beneficiaryHinzufuegen(newBen);
    setState(() => _state = _ConnectState.success);

    await Future.delayed(const Duration(milliseconds: 1600));
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
        child: _state == _ConnectState.success
            ? _buildSuccess()
            : _state == _ConnectState.loading
                ? _buildLoading()
                : _buildForm(),
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
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0E4EF),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // DKB logo
            Center(
              child: Container(
                width: 140,
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE8EAF0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.07),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(8),
                child:
                    Image.asset('assets/images/dkb_logo.png', fit: BoxFit.contain),
              ),
            ),

            const SizedBox(height: 20),

            Center(
              child: Text(
                'DKB Konto verknüpfen',
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
                'Geben Sie die DKB-Zugangsdaten des Empfängers ein,\num sein Konto sicher zu verknüpfen.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: DkbColors.textSecondary,
                  height: 1.4,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Security badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: DkbColors.success.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: DkbColors.success.withValues(alpha: 0.2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock, color: DkbColors.success, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    'Verschlüsselte Verbindung · Keine Datenspeicherung',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: DkbColors.success,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            if (_errorMsg != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: DkbColors.danger.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: DkbColors.danger.withValues(alpha: 0.25)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.error_outline,
                        color: DkbColors.danger, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMsg!,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: DkbColors.danger,
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().shake(),
              const SizedBox(height: 16),
            ],

            // Kontonummer
            Text(
              'Kontonummer des Empfängers',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: DkbColors.textSecondary,
              ),
            ),
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
                if (v.length != 8) return 'Kontonummer hat 8 Stellen';
                return null;
              },
              decoration: const InputDecoration(
                hintText: 'z. B. 87654321',
                prefixIcon:
                    Icon(Icons.person_outline, color: DkbColors.textMuted),
              ),
            ),

            const SizedBox(height: 14),

            // PIN
            Text(
              'Online-Banking-PIN des Empfängers',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: DkbColors.textSecondary,
              ),
            ),
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
                if (v.length != 4) return 'PIN hat 4 Stellen';
                return null;
              },
              decoration: InputDecoration(
                hintText: '••••',
                prefixIcon: const Icon(Icons.lock_outline,
                    color: DkbColors.textMuted),
                suffixIcon: IconButton(
                  onPressed: () =>
                      setState(() => _obscurePin = !_obscurePin),
                  icon: Icon(
                    _obscurePin
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: DkbColors.textMuted,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Demo hint
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: DkbColors.accent.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: DkbColors.accent.withValues(alpha: 0.15)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Demo-Testkonten zum Verknüpfen:',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: DkbColors.accent,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '• Klaus Mustermann → 87654321 / PIN 5678\n'
                    '• Anna Schmidt → 11223344 / PIN 4321\n'
                    '• Thomas Weber → 55667788 / PIN 9999',
                    style: GoogleFonts.ibmPlexMono(
                      fontSize: 11,
                      color: DkbColors.accent,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: _verknuepfen,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
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
      height: 340,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated connecting dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ConnectIcon(Icons.account_balance, DkbColors.primary),
              const SizedBox(width: 12),
              ...List.generate(
                4,
                (i) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: _AnimDot(delay: i * 180),
                ),
              ),
              const SizedBox(width: 12),
              _ConnectIcon(Icons.person, DkbColors.accent),
            ],
          ),
          const SizedBox(height: 28),
          Text(
            'Konto wird verknüpft...',
            style: GoogleFonts.inter(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: DkbColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Zugangsdaten werden sicher übertragen',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: DkbColors.textSecondary,
            ),
          ),
          const SizedBox(height: 28),
          const SizedBox(
            width: 220,
            child: LinearProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(DkbColors.accent),
              minHeight: 4,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Gesicherte Verbindung · 256-Bit-Verschlüsselung',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: DkbColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccess() {
    return SizedBox(
      key: const ValueKey('success'),
      height: 320,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: DkbColors.success.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_outline,
                color: DkbColors.success, size: 38),
          )
              .animate()
              .scale(begin: const Offset(0.5, 0.5), curve: Curves.elasticOut),
          const SizedBox(height: 20),
          Text(
            'Konto erfolgreich verknüpft!',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: DkbColors.textPrimary,
            ),
          ).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 8),
          Text(
            MockData.dkbAccountName(_ktoCtrl.text.trim()),
            style: GoogleFonts.inter(
              fontSize: 14,
              color: DkbColors.accent,
              fontWeight: FontWeight.w600,
            ),
          ).animate().fadeIn(delay: 300.ms),
          const SizedBox(height: 6),
          Text(
            'wurde als Begünstigter hinzugefügt.\nSie können jetzt überweisen.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: DkbColors.textSecondary,
            ),
          ).animate().fadeIn(delay: 350.ms),
        ],
      ),
    );
  }
}

class _ConnectIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  const _ConnectIcon(this.icon, this.color);

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

enum _ConnectState { idle, loading, error, success }
