import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../state/app_state.dart';
import 'main_shell.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _ktoController = TextEditingController();
  final _pinController = TextEditingController();
  bool _obscurePin = true;
  bool _isLoading = false;
  bool _hasError = false;

  @override
  void dispose() {
    _ktoController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _anmelden() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    await Future.delayed(const Duration(milliseconds: 600));

    final ok = AppState().anmelden(
      _ktoController.text.trim(),
      _pinController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (ok) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, _, _) => const MainShell(),
          transitionDuration: const Duration(milliseconds: 350),
          transitionsBuilder: (_, anim, _, child) =>
              FadeTransition(opacity: anim, child: child),
        ),
      );
    } else {
      setState(() => _hasError = true);
      HapticFeedback.lightImpact();
    }
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
                      width: 180,
                      height: 100,
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
                      child: Image.asset(
                        'assets/images/dkb_logo.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Willkommen zurück',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Melden Sie sich mit Ihrer Kontonummer an',
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
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: DkbColors.background,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),

                        // Error banner
                        if (_hasError) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: DkbColors.danger.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(DkbRadius.sm),
                              border: Border.all(
                                  color: DkbColors.danger.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline,
                                    color: DkbColors.danger, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  'Kontonummer oder PIN ist falsch.',
                                  style: GoogleFonts.inter(
                                    color: DkbColors.danger,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ).animate().shake(),
                          const SizedBox(height: 16),
                        ],

                        // Kontonummer
                        Text(
                          'Kontonummer',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: DkbColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _ktoController,
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
                            hintText: '12345678',
                            prefixIcon: Icon(Icons.person_outline, color: DkbColors.textMuted),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // PIN
                        Text(
                          'PIN',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: DkbColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _pinController,
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
                            prefixIcon: const Icon(Icons.lock_outline, color: DkbColors.textMuted),
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
                          onFieldSubmitted: (_) => _anmelden(),
                        ),
                        const SizedBox(height: 8),

                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => _showPinVergessen(),
                            child: Text(
                              'PIN vergessen?',
                              style: GoogleFonts.inter(
                                color: DkbColors.accent,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Login button
                        ElevatedButton(
                          onPressed: _isLoading ? null : _anmelden,
                          child: _isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Anmelden'),
                        ),

                        const SizedBox(height: 24),

                        // Demo hint
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: DkbColors.accent.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(DkbRadius.sm),
                            border: Border.all(
                                color: DkbColors.accent.withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline,
                                  color: DkbColors.accent, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Demo: Kontonummer 12345678 · PIN 1234',
                                  style: GoogleFonts.inter(
                                    color: DkbColors.accent,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ).animate(delay: 200.ms).fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
            ),
          ],
        ),
      ),
    );
  }

  void _showPinVergessen() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('PIN vergessen', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: Text(
          'Bitte kontaktieren Sie die DKB unter 030 120 300 00 oder besuchen Sie eine Filiale.',
          style: GoogleFonts.inter(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
