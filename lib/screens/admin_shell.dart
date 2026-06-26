import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import 'admin_users_screen.dart';
import 'admin_transactions_screen.dart';
import 'admin_fund_screen.dart';
import 'admin_system_screen.dart';
import 'login_screen.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _selectedIndex = 0;

  static const _tabs = [
    (Icons.people_outline, Icons.people, 'Nutzer'),
    (Icons.receipt_long_outlined, Icons.receipt_long, 'Transaktionen'),
    (Icons.account_balance_wallet_outlined, Icons.account_balance_wallet, 'Gelder'),
    (Icons.settings_outlined, Icons.settings, 'System'),
  ];

  void _logout() {
    ApiService.instance.adminLogout();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DkbColors.background,
      appBar: AppBar(
        backgroundColor: DkbColors.primary,
        elevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 12,
        leading: Padding(
          padding: const EdgeInsets.all(10),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            child: Image.asset(
              'assets/images/dkb_logo.png',
              fit: BoxFit.contain,
              errorBuilder: (context, err, _) => Text(
                'DKB',
                style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12),
              ),
            ),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Admin Panel',
              style: GoogleFonts.inter(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
            ),
            Text(
              'Verwaltungszentrale',
              style: GoogleFonts.inter(color: Colors.white.withValues(alpha: 0.55), fontSize: 10),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 4, top: 10, bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: DkbColors.danger.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: DkbColors.danger.withValues(alpha: 0.5)),
            ),
            child: Text(
              'ADMIN',
              style: GoogleFonts.inter(
                color: DkbColors.danger,
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white, size: 20),
            onPressed: _logout,
            tooltip: 'Abmelden',
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: const [
          AdminUsersScreen(),
          AdminTransactionsScreen(),
          AdminFundScreen(),
          AdminSystemScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: DkbColors.divider, width: 1)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 62,
            child: Row(
              children: List.generate(_tabs.length, (i) {
                final active = _selectedIndex == i;
                final (iconOff, iconOn, label) = _tabs[i];
                return Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _selectedIndex = i),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          active ? iconOn : iconOff,
                          color: active ? DkbColors.primary : DkbColors.textMuted,
                          size: 22,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          label,
                          style: GoogleFonts.inter(
                            color: active ? DkbColors.primary : DkbColors.textMuted,
                            fontSize: 10,
                            fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
