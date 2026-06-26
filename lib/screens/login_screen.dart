import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../state/app_state.dart';
import 'main_shell.dart';
import 'signup_screen.dart';
import 'admin_login_screen.dart';

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
  int _logoTapCount = 0;
  DateTime? _lastLogoTap;

  @override
  void dispose() {
    _ktoController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  void _onLogoTap() {
    final now = DateTime.now();
    if (_lastLogoTap != null && now.difference(_lastLogoTap!).inSeconds > 3) {
      _logoTapCount = 0;
    }
    _lastLogoTap = now;
    _logoTapCount++;
    if (_logoTapCount >= 5) {
      _logoTapCount = 0;
      Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminLoginScreen()));
    }
  }

  Future<void> _anmelden() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    final ok = await AppState().anmelden(
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
    final mq = MediaQuery.of(context);
    final sw = mq.size.width;
    final sh = mq.size.height;
    final isShortScreen = sh < 600;
    final logoW = (sw * 0.48).clamp(130.0, 210.0);
    final logoH = logoW / 2.4;

    // Brand section height: 30% of screen, clamped to a reasonable range
    final brandH = (sh * 0.30).clamp(160.0, 280.0);

    return Scaffold(
      backgroundColor: DkbColors.primary,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── Top brand area ─────────────────────────────────────────────
            SizedBox(
              height: brandH,
              width: double.infinity,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Logo card — tap 7× quickly to open admin panel
                  Center(
                    child: GestureDetector(
                      onTap: _onLogoTap,
                      child: Container(
                      width: logoW,
                      height: logoH,
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
                      padding: EdgeInsets.all(logoW * 0.07),
                      child: Image.asset(
                        'assets/images/dkb_logo.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                    ),
                  ),
                  SizedBox(height: isShortScreen ? 8 : 14),
                  Text(
                    'Willkommen zurück',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: isShortScreen ? 18 : 22,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Melden Sie sich mit Ihrer Kontonummer an',
                    style: GoogleFonts.inter(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ).animate().fadeIn(duration: 500.ms),
            ),

            // ── White form card ────────────────────────────────────────────
            Expanded(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: DkbColors.background,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                    ),
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        24,
                        isShortScreen ? 12 : 20,
                        24,
                        24,
                      ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Error banner
                                if (_hasError) ...[
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: DkbColors.danger.withValues(alpha: 0.08),
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
                                _label('Kontonummer'),
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
                                    prefixIcon:
                                        Icon(Icons.person_outline, color: DkbColors.textMuted),
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // PIN
                                _label('PIN'),
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
                                  onFieldSubmitted: (_) => _anmelden(),
                                ),
                                const SizedBox(height: 6),

                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: _showPinVergessen,
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 4, vertical: 4),
                                    ),
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

                                const SizedBox(height: 16),

                                Center(
                                  child: TextButton(
                                    onPressed: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) => const SignupScreen()),
                                    ),
                                    child: Text(
                                      'Noch kein Konto? Jetzt eröffnen',
                                      style: GoogleFonts.inter(
                                        color: DkbColors.accent,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 8),
                                Center(
                                  child: TextButton(
                                    onPressed: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
                                    ),
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    ),
                                    child: Text(
                                      'Verwaltung',
                                      style: GoogleFonts.inter(
                                        color: DkbColors.textMuted,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
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

  Widget _label(String text) => Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: DkbColors.textSecondary,
        ),
      );

  void _showPinVergessen() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title:
            Text('PIN vergessen', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
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
