import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/storage_service.dart';
import '../services/api_service.dart';
import '../state/app_state.dart';
import 'login_screen.dart';
import 'main_shell.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await StorageService.init();
    await StorageService.loadAll();
    await ApiService.instance.init();

    await Future.delayed(const Duration(milliseconds: 1800));
    if (!mounted) return;

    final session = StorageService.loadSession();
    if (session != null) {
      // Restore session with a hard timeout — never block the splash screen
      try {
        await AppState()
            .sessionWiederherstellen(session)
            .timeout(const Duration(seconds: 8));
      } catch (_) {
        // Timeout or error — fall through to login
      }
      if (!mounted) return;
      if (AppState().isAngemeldet) {
        Navigator.of(context).pushReplacement(_fadeRoute(const MainShell()));
        return;
      }
    }
    if (!mounted) return;
    Navigator.of(context).pushReplacement(_fadeRoute(const LoginScreen()));
  }

  PageRouteBuilder _fadeRoute(Widget page) => PageRouteBuilder(
        pageBuilder: (_, _, _) => page,
        transitionDuration: const Duration(milliseconds: 400),
        transitionsBuilder: (_, anim, _, child) =>
            FadeTransition(opacity: anim, child: child),
      );

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final sw = mq.size.width;
    final sh = mq.size.height;
    final logoW = (sw * 0.52).clamp(140.0, 240.0);
    final logoH = logoW / 2.4;

    return Scaffold(
      backgroundColor: DkbColors.primary,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 3),

            // Logo card
            Container(
              width: logoW,
              height: logoH,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(DkbRadius.lg),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              padding: EdgeInsets.all(logoW * 0.07),
              child: Image.asset(
                'assets/images/dkb_logo.png',
                fit: BoxFit.contain,
              ),
            )
                .animate()
                .fadeIn(duration: 600.ms)
                .scale(begin: const Offset(0.75, 0.75), curve: Curves.easeOut),

            SizedBox(height: sh * 0.025),

            Text(
              'Deutsche Kreditbank',
              style: GoogleFonts.inter(
                color: Colors.white.withValues(alpha: 0.65),
                fontSize: (sw * 0.04).clamp(13.0, 17.0),
                fontWeight: FontWeight.w400,
                letterSpacing: 0.5,
              ),
            )
                .animate(delay: 300.ms)
                .fadeIn(duration: 500.ms)
                .slideY(begin: 0.1, end: 0),

            const Spacer(flex: 4),

            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(DkbColors.accent),
              ),
            ).animate(delay: 600.ms).fadeIn(duration: 400.ms),

            SizedBox(height: sh * 0.06),
          ],
        ),
      ),
    );
  }
}
