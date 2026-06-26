import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import 'admin_dashboard_screen.dart';
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

  static const _navItems = [
    (Icons.dashboard_outlined, Icons.dashboard_rounded, 'Dashboard'),
    (Icons.people_outline, Icons.people_rounded, 'Nutzer'),
    (Icons.receipt_long_outlined, Icons.receipt_long_rounded, 'Transaktionen'),
    (Icons.account_balance_wallet_outlined, Icons.account_balance_wallet_rounded, 'Gelder'),
    (Icons.tune_outlined, Icons.tune_rounded, 'System'),
  ];

  static const _screens = [
    AdminDashboardScreen(),
    AdminUsersScreen(),
    AdminTransactionsScreen(),
    AdminFundScreen(),
    AdminSystemScreen(),
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
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    if (isDesktop) {
      return Scaffold(
        backgroundColor: DkbColors.background,
        body: Row(
          children: [
            _Sidebar(
              selectedIndex: _selectedIndex,
              onSelect: (i) => setState(() => _selectedIndex = i),
              onLogout: _logout,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _TopBar(title: _navItems[_selectedIndex].$3),
                  Expanded(
                    child: IndexedStack(
                      index: _selectedIndex,
                      children: _screens,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Mobile: AppBar + bottom nav
    return Scaffold(
      backgroundColor: DkbColors.background,
      appBar: AppBar(
        backgroundColor: DkbColors.primary,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Container(
              height: 26,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(5),
              ),
              child: Image.asset(
                'assets/images/dkb_logo.png',
                fit: BoxFit.contain,
                errorBuilder: (context, err, _) => Text('DKB',
                    style: GoogleFonts.inter(
                        color: DkbColors.primary, fontWeight: FontWeight.w800, fontSize: 11)),
              ),
            ),
            const SizedBox(width: 10),
            Text('Admin Panel',
                style: GoogleFonts.inter(
                    color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: DkbColors.danger.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: DkbColors.danger.withValues(alpha: 0.5)),
              ),
              child: Text('ADMIN',
                  style: GoogleFonts.inter(
                      color: DkbColors.danger,
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1)),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white, size: 20),
            onPressed: _logout,
            tooltip: 'Abmelden',
          ),
        ],
      ),
      body: IndexedStack(index: _selectedIndex, children: _screens),
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
              children: List.generate(_navItems.length, (i) {
                final active = _selectedIndex == i;
                final (iconOff, iconOn, label) = _navItems[i];
                return Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _selectedIndex = i),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(active ? iconOn : iconOff,
                            color: active ? DkbColors.primary : DkbColors.textMuted, size: 20),
                        const SizedBox(height: 3),
                        Text(label,
                            style: GoogleFonts.inter(
                                color: active ? DkbColors.primary : DkbColors.textMuted,
                                fontSize: 9,
                                fontWeight: active ? FontWeight.w700 : FontWeight.w400)),
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

// ── Desktop Sidebar ────────────────────────────────────────────────────────

class _Sidebar extends StatelessWidget {
  final int selectedIndex;
  final void Function(int) onSelect;
  final VoidCallback onLogout;

  const _Sidebar({
    required this.selectedIndex,
    required this.onSelect,
    required this.onLogout,
  });

  static const _navItems = [
    (Icons.dashboard_outlined, Icons.dashboard_rounded, 'Dashboard'),
    (Icons.people_outline, Icons.people_rounded, 'Nutzer'),
    (Icons.receipt_long_outlined, Icons.receipt_long_rounded, 'Transaktionen'),
    (Icons.account_balance_wallet_outlined, Icons.account_balance_wallet_rounded, 'Gelder'),
    (Icons.tune_outlined, Icons.tune_rounded, 'System'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 230,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1E3060), Color(0xFF0D1A36)],
        ),
        border: Border(
          right: BorderSide(color: Color(0x18FFFFFF), width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 28, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Image.asset(
                    'assets/images/dkb_logo.png',
                    height: 20,
                    fit: BoxFit.fitHeight,
                    errorBuilder: (context, err, _) => Text('DKB',
                        style: GoogleFonts.inter(
                            color: DkbColors.primary, fontWeight: FontWeight.w800, fontSize: 13)),
                  ),
                ),
                const SizedBox(height: 14),
                Text('Admin Panel',
                    style: GoogleFonts.inter(
                        color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: DkbColors.danger.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: DkbColors.danger.withValues(alpha: 0.35)),
                  ),
                  child: Text('ADMINISTRATIV',
                      style: GoogleFonts.inter(
                          color: DkbColors.danger,
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2)),
                ),
              ],
            ),
          ),

          Container(height: 1, color: Colors.white.withValues(alpha: 0.08)),
          const SizedBox(height: 6),

          // ── Navigation items ────────────────────────────────────────────
          ...List.generate(_navItems.length, (i) {
            final active = selectedIndex == i;
            final (iconOff, iconOn, label) = _navItems[i];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  onTap: () => onSelect(i),
                  borderRadius: BorderRadius.circular(8),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: active ? Colors.white.withValues(alpha: 0.10) : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: active
                          ? const Border(
                              left: BorderSide(color: DkbColors.accent, width: 3),
                            )
                          : null,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          active ? iconOn : iconOff,
                          color: active ? DkbColors.accent : Colors.white.withValues(alpha: 0.5),
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          label,
                          style: GoogleFonts.inter(
                            color: active ? Colors.white : Colors.white.withValues(alpha: 0.5),
                            fontSize: 13,
                            fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),

          const Spacer(),

          // ── Footer actions ──────────────────────────────────────────────
          Container(height: 1, color: Colors.white.withValues(alpha: 0.08)),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 24),
            child: Column(
              children: [
                _footerBtn(
                  context,
                  icon: Icons.arrow_back_rounded,
                  label: 'Zur Bankanwendung',
                  onTap: () {
                    ApiService.instance.adminLogout();
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (_) => false,
                    );
                  },
                ),
                const SizedBox(height: 2),
                _footerBtn(
                  context,
                  icon: Icons.logout_rounded,
                  label: 'Abmelden',
                  onTap: onLogout,
                  danger: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _footerBtn(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool danger = false,
  }) {
    final color = danger
        ? DkbColors.danger.withValues(alpha: 0.75)
        : Colors.white.withValues(alpha: 0.38);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          child: Row(
            children: [
              Icon(icon, color: color, size: 15),
              const SizedBox(width: 10),
              Text(label, style: GoogleFonts.inter(color: color, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Desktop Top Bar ────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final String title;
  const _TopBar({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: DkbColors.divider, width: 1)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: DkbColors.textPrimary,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: DkbColors.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: DkbColors.divider),
            ),
            child: Row(
              children: [
                const Icon(Icons.admin_panel_settings_outlined,
                    size: 14, color: DkbColors.textMuted),
                const SizedBox(width: 6),
                Text('DKB Administrationsportal',
                    style: GoogleFonts.inter(fontSize: 11, color: DkbColors.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
