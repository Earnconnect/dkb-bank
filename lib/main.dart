import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/pin_aendern_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('de_DE', null);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ),
  );

  runApp(const DkbApp());
}

class DkbApp extends StatelessWidget {
  const DkbApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DKB Banking',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      locale: const Locale('de', 'DE'),
      supportedLocales: const [
        Locale('de', 'DE'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const SplashScreen(),
      routes: {
        '/login': (_) => const LoginScreen(),
        '/pin-aendern': (_) => const PinAendernScreen(),
      },
    );
  }
}
