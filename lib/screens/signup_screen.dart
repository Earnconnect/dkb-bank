import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../state/app_state.dart';
import 'main_shell.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _pinCtrl = TextEditingController();
  final _confirmPinCtrl = TextEditingController();
  bool _obscurePin = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  String? _errorMsg;

  // Shown after successful registration
  String? _assignedKontonummer;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _pinCtrl.dispose();
    _confirmPinCtrl.dispose();
    super.dispose();
  }

  Future<void> _registrieren() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });

    final result = await AppState().registrieren(
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
      pin: _pinCtrl.text.trim(),
      confirmPin: _confirmPinCtrl.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['statusCode'] == 201) {
      setState(() => _assignedKontonummer = result['kontonummer'] as String?);
    } else {
      setState(() => _errorMsg = result['error'] as String? ?? 'Registrierung fehlgeschlagen');
      HapticFeedback.lightImpact();
    }
  }

  void _weiter() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, _, _) => const MainShell(),
        transitionDuration: const Duration(milliseconds: 350),
        transitionsBuilder: (_, anim, _, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DkbColors.primary,
      body: SafeArea(
        child: Column(
          children: [
            // Top brand area
            Expanded(
              flex: 2,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 160,
                      height: 88,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(DkbRadius.lg),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Image.asset('assets/images/dkb_logo.png',
                          fit: BoxFit.contain),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Konto eröffnen',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Kostenloses DKB-Konto in wenigen Schritten',
                      style: GoogleFonts.inter(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(duration: 500.ms),

            // White form card
            Expanded(
              flex: 4,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: DkbColors.background,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: _assignedKontonummer != null
                      ? _buildSuccess()
                      : _buildForm(),
                ),
              ).animate(delay: 200.ms).fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),

          if (_errorMsg != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: DkbColors.danger.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(DkbRadius.sm),
                border: Border.all(color: DkbColors.danger.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: DkbColors.danger, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMsg!,
                      style: GoogleFonts.inter(color: DkbColors.danger, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ).animate().shake(),
            const SizedBox(height: 16),
          ],

          // Name
          _label('Vollständiger Name'),
          const SizedBox(height: 6),
          TextFormField(
            controller: _nameCtrl,
            textCapitalization: TextCapitalization.words,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Name eingeben';
              if (v.trim().length < 2) return 'Name zu kurz';
              return null;
            },
            decoration: const InputDecoration(
              hintText: 'Max Mustermann',
              prefixIcon: Icon(Icons.person_outline, color: DkbColors.textMuted),
            ),
          ),
          const SizedBox(height: 16),

          // Email (optional)
          _label('E-Mail-Adresse (optional)'),
          const SizedBox(height: 6),
          TextFormField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return null;
              if (!v.contains('@') || !v.contains('.')) return 'Gültige E-Mail eingeben';
              return null;
            },
            decoration: const InputDecoration(
              hintText: 'max@email.de',
              prefixIcon: Icon(Icons.mail_outline, color: DkbColors.textMuted),
            ),
          ),
          const SizedBox(height: 16),

          // PIN
          _label('PIN (4 Stellen)'),
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
              if (v.length != 4) return 'PIN muss 4 Stellen haben';
              return null;
            },
            decoration: InputDecoration(
              hintText: '••••',
              prefixIcon: const Icon(Icons.lock_outline, color: DkbColors.textMuted),
              suffixIcon: IconButton(
                onPressed: () => setState(() => _obscurePin = !_obscurePin),
                icon: Icon(
                  _obscurePin ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: DkbColors.textMuted,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Confirm PIN
          _label('PIN bestätigen'),
          const SizedBox(height: 6),
          TextFormField(
            controller: _confirmPinCtrl,
            obscureText: _obscureConfirm,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(4),
            ],
            validator: (v) {
              if (v == null || v.isEmpty) return 'PIN bestätigen';
              if (v != _pinCtrl.text) return 'PINs stimmen nicht überein';
              return null;
            },
            decoration: InputDecoration(
              hintText: '••••',
              prefixIcon: const Icon(Icons.lock_outline, color: DkbColors.textMuted),
              suffixIcon: IconButton(
                onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                icon: Icon(
                  _obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: DkbColors.textMuted,
                ),
              ),
            ),
            onFieldSubmitted: (_) => _registrieren(),
          ),
          const SizedBox(height: 24),

          ElevatedButton(
            onPressed: _isLoading ? null : _registrieren,
            child: _isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5, color: Colors.white),
                  )
                : const Text('Konto eröffnen'),
          ),

          const SizedBox(height: 16),

          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Bereits ein Konto? Anmelden',
                style: GoogleFonts.inter(
                  color: DkbColors.accent,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccess() {
    return Column(
      children: [
        const SizedBox(height: 24),

        // Success icon
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: DkbColors.success.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_circle_outline,
              color: DkbColors.success, size: 42),
        ).animate().scale(begin: const Offset(0.5, 0.5), curve: Curves.elasticOut),

        const SizedBox(height: 20),

        Text(
          'Willkommen bei DKB!',
          style: GoogleFonts.inter(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: DkbColors.textPrimary,
          ),
        ).animate().fadeIn(delay: 200.ms),

        const SizedBox(height: 8),

        Text(
          'Ihr Konto wurde erfolgreich eröffnet.',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: DkbColors.textSecondary,
          ),
        ).animate().fadeIn(delay: 300.ms),

        const SizedBox(height: 28),

        // Kontonummer card — user must save this
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: DkbColors.primary,
            borderRadius: BorderRadius.circular(DkbRadius.md),
          ),
          child: Column(
            children: [
              Text(
                'Ihre Kontonummer',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.6),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _assignedKontonummer ?? '',
                style: GoogleFonts.ibmPlexMono(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 6,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: DkbColors.danger.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: DkbColors.danger.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: DkbColors.danger, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      'Merken Sie sich diese Nummer — Sie benötigen sie zum Anmelden',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ).animate().fadeIn(delay: 400.ms),

        const SizedBox(height: 12),

        // Copy button
        OutlinedButton.icon(
          onPressed: () {
            Clipboard.setData(ClipboardData(text: _assignedKontonummer ?? ''));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Kontonummer kopiert')),
            );
          },
          icon: const Icon(Icons.copy, size: 16),
          label: const Text('Kontonummer kopieren'),
          style: OutlinedButton.styleFrom(
            foregroundColor: DkbColors.primary,
            side: const BorderSide(color: DkbColors.primary),
          ),
        ).animate().fadeIn(delay: 500.ms),

        const SizedBox(height: 28),

        ElevatedButton(
          onPressed: _weiter,
          child: const Text('Zum Online-Banking'),
        ).animate().fadeIn(delay: 600.ms),
      ],
    );
  }

  Widget _label(String text) => Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: DkbColors.textSecondary,
        ),
      );
}
