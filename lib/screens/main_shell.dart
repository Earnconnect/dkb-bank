import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../state/app_state.dart';
import '../utils/responsive.dart';
import '../widgets/desktop_sidebar.dart';
import 'uebersicht_screen.dart';
import 'girokonto_screen.dart';
import 'visa_screen.dart';
import 'ueberweisung_screen.dart';
import 'einstellungen_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  final _state = AppState();

  void _refresh() => setState(() {});

  @override
  void initState() {
    super.initState();
    _state.addListener(_refresh);
  }

  @override
  void dispose() {
    _state.removeListener(_refresh);
    super.dispose();
  }

  static const _screens = [
    UebersichtScreen(),
    GirokontoScreen(),
    VisaScreen(),
    UeberweisungScreen(),
    EinstellungenScreen(),
  ];

  static const _navItems = [
    _NavItem(Icons.home_outlined, Icons.home, 'Übersicht'),
    _NavItem(Icons.account_balance_outlined, Icons.account_balance, 'Girokonto'),
    _NavItem(Icons.credit_card_outlined, Icons.credit_card, 'DKB-Visa'),
    _NavItem(Icons.send_outlined, Icons.send, 'Überweisung'),
    _NavItem(Icons.menu_outlined, Icons.menu, 'Mehr'),
  ];

  @override
  Widget build(BuildContext context) {
    if (R.showSidebar(context)) {
      return _DesktopLayout(
        activeIndex: _state.activeTab,
        onTabChange: _state.setTab,
        screens: _screens,
      );
    }

    return Scaffold(
      body: IndexedStack(
        index: _state.activeTab,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: DkbColors.primary.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _state.activeTab,
          onTap: _state.setTab,
          items: _navItems.map((item) {
            final isActive = _navItems.indexOf(item) == _state.activeTab;
            return BottomNavigationBarItem(
              icon: Icon(isActive ? item.activeIcon : item.icon),
              label: item.label,
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _DesktopLayout extends StatelessWidget {
  final int activeIndex;
  final void Function(int) onTabChange;
  final List<Widget> screens;

  const _DesktopLayout({
    required this.activeIndex,
    required this.onTabChange,
    required this.screens,
  });

  static const _titles = [
    ('Übersicht', 'Ihr Kontoüberblick'),
    ('Girokonto', 'Kontodetails & Umsätze'),
    ('DKB-Visa', 'Kreditkartenübersicht'),
    ('Überweisung', 'SEPA-Überweisung'),
    ('Mehr', 'Einstellungen & weitere Services'),
  ];

  @override
  Widget build(BuildContext context) {
    final (title, subtitle) = _titles[activeIndex];

    return Scaffold(
      body: Row(
        children: [
          DesktopSidebar(activeIndex: activeIndex, onTap: onTabChange),
          Expanded(
            child: Column(
              children: [
                // Top bar
                Container(
                  height: 64,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  color: DkbColors.surface,
                  child: Row(
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: DkbColors.textPrimary,
                            ),
                          ),
                          Text(
                            subtitle,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: DkbColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: DkbColors.primary,
                          borderRadius: BorderRadius.circular(DkbRadius.sm),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.send, color: Colors.white, size: 14),
                            const SizedBox(width: 6),
                            Text(
                              'Überweisung',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(height: 1, color: DkbColors.divider),
                Expanded(
                  child: IndexedStack(
                    index: activeIndex,
                    children: screens,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem(this.icon, this.activeIcon, this.label);
}
