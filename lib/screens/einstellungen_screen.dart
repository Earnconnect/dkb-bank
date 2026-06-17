import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../state/app_state.dart';
import '../utils/page_transitions.dart';
import 'dauerauftrag_screen.dart';
import 'beneficiary_screen.dart';
import 'pin_aendern_screen.dart';
import 'login_screen.dart';

class EinstellungenScreen extends StatefulWidget {
  const EinstellungenScreen({super.key});

  @override
  State<EinstellungenScreen> createState() => _EinstellungenScreenState();
}

class _EinstellungenScreenState extends State<EinstellungenScreen> {
  bool _benachrichtigungen = true;
  bool _fingerabdruck = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mehr')),
      body: ListView(
        children: [
          const SizedBox(height: 8),

          // Services section
          _SectionHeader('Services'),
          _SettingsItem(
            icon: Icons.repeat,
            label: 'Daueraufträge',
            subtitle: 'Wiederkehrende Überweisungen verwalten',
            onTap: () =>
                Navigator.push(context, fadeSlide(const DauerauftragScreen())),
          ),
          _SettingsItem(
            icon: Icons.people_outline,
            label: 'Begünstigte',
            subtitle: 'Empfänger verwalten und DKB-Konten verknüpfen',
            onTap: () =>
                Navigator.push(context, fadeSlide(const BeneficiaryScreen())),
          ),
          _SettingsItem(
            icon: Icons.receipt_long_outlined,
            label: 'Kontoauszüge',
            subtitle: 'Monatliche Kontoauszüge',
            onTap: () => _snackbar('Kontoauszüge werden in Kürze verfügbar sein'),
          ),
          _SettingsItem(
            icon: Icons.mail_outline,
            label: 'Postbox',
            subtitle: 'Digitale Dokumentenablage',
            onTap: () => _snackbar('Postbox wird in Kürze verfügbar sein'),
          ),

          const SizedBox(height: 8),

          // Security section
          _SectionHeader('Sicherheit'),
          _SettingsItem(
            icon: Icons.lock_outline,
            label: 'PIN ändern',
            subtitle: 'Online-Banking-PIN anpassen',
            onTap: () => Navigator.push(context, fadeSlide(const PinAendernScreen())),
          ),
          _SettingsSwitchItem(
            icon: Icons.fingerprint,
            label: 'Fingerabdruck / Face ID',
            value: _fingerabdruck,
            onChanged: (v) => setState(() => _fingerabdruck = v),
          ),

          const SizedBox(height: 8),

          // Notifications section
          _SectionHeader('Mitteilungen'),
          _SettingsSwitchItem(
            icon: Icons.notifications_outlined,
            label: 'Kontoaktivitäten',
            value: _benachrichtigungen,
            onChanged: (v) => setState(() => _benachrichtigungen = v),
          ),

          const SizedBox(height: 8),

          // Limits section
          _SectionHeader('Limits'),
          _SettingsItem(
            icon: Icons.tune_outlined,
            label: 'Überweisungslimit',
            subtitle: 'Täglich max. 5.000,00 €',
            onTap: () => _showLimitInfo(),
          ),
          _SettingsItem(
            icon: Icons.credit_card_outlined,
            label: 'Kreditkartenlimit',
            subtitle: '3.000,00 €',
            onTap: () => _showLimitInfo(),
          ),

          const SizedBox(height: 8),

          // Support section
          _SectionHeader('Support'),
          _SettingsItem(
            icon: Icons.headset_mic_outlined,
            label: 'Kundenservice',
            subtitle: '030 120 300 00 · Mo–So 24/7',
            onTap: () => _snackbar('Bitte rufen Sie uns an: 030 120 300 00'),
          ),
          _SettingsItem(
            icon: Icons.info_outline,
            label: 'Über DKB',
            subtitle: 'Version 1.0.0',
            onTap: () {},
          ),

          const SizedBox(height: 16),

          // Logout
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton.icon(
              onPressed: () => _abmelden(),
              icon: const Icon(Icons.logout, size: 18),
              label: const Text('Abmelden'),
              style: ElevatedButton.styleFrom(
                backgroundColor: DkbColors.danger,
                foregroundColor: Colors.white,
              ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _snackbar(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  void _showLimitInfo() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Limits', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: Text(
          'Tägliches Überweisungslimit: 5.000,00 €\nKreditkartenlimit: 3.000,00 €\n\n'
          'Zur Anpassung kontaktieren Sie bitte den DKB Kundenservice.',
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

  void _abmelden() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Abmelden?',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: Text(
          'Möchten Sie sich wirklich abmelden?',
          style: GoogleFonts.inter(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              AppState().abmelden();
              Navigator.of(context).pushAndRemoveUntil(
                PageRouteBuilder(
                  pageBuilder: (_, _, _) => const LoginScreen(),
                  transitionsBuilder: (_, anim, _, child) =>
                      FadeTransition(opacity: anim, child: child),
                ),
                (_) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: DkbColors.danger,
              minimumSize: const Size(80, 40),
            ),
            child: const Text('Abmelden'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: DkbColors.textMuted,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback? onTap;

  const _SettingsItem({
    required this.icon,
    required this.label,
    this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: DkbColors.surface,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: DkbColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(DkbRadius.sm),
                ),
                child: Icon(icon, color: DkbColors.primary, size: 18),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: DkbColors.textPrimary,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: DkbColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: DkbColors.textMuted, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsSwitchItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final void Function(bool) onChanged;

  const _SettingsSwitchItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: DkbColors.surface,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: DkbColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(DkbRadius.sm),
              ),
              child: Icon(icon, color: DkbColors.primary, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: DkbColors.textPrimary,
                ),
              ),
            ),
            Switch(value: value, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}
