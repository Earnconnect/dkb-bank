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
      bottomNavigationBar: _DkbBottomNav(
        currentIndex: _state.activeTab,
        onTap: _state.setTab,
      ),
    );
  }
}

class _DkbBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _DkbBottomNav({required this.currentIndex, required this.onTap});

  static const _items = [
    (Icons.home_outlined, Icons.home, 'Übersicht'),
    (Icons.account_balance_outlined, Icons.account_balance, 'Girokonto'),
    (Icons.credit_card_outlined, Icons.credit_card, 'DKB-Visa'),
    (Icons.send_outlined, Icons.send, 'Überweisung'),
    (Icons.menu_outlined, Icons.menu, 'Mehr'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE4E8F0), width: 1)),
        boxShadow: [
          BoxShadow(
            color: Color(0x0A1C2B56),
            blurRadius: 12,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            children: List.generate(_items.length, (i) {
              final (icon, activeIcon, label) = _items[i];
              final isActive = i == currentIndex;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Active indicator dot above icon
                      Container(
                        width: 20,
                        height: 3,
                        margin: const EdgeInsets.only(bottom: 4),
                        decoration: BoxDecoration(
                          color: isActive
                              ? DkbColors.primary
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(DkbRadius.full),
                        ),
                      ),
                      Icon(
                        isActive ? activeIcon : icon,
                        color: isActive ? DkbColors.primary : DkbColors.textMuted,
                        size: 22,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        label,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                          color: isActive ? DkbColors.primary : DkbColors.textMuted,
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
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
