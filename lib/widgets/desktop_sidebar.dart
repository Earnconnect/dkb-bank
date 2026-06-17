import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../state/app_state.dart';
import '../data/mock_data.dart';
import '../utils/german_formatter.dart';

class DesktopSidebar extends StatelessWidget {
  final int activeIndex;
  final void Function(int) onTap;

  const DesktopSidebar({
    super.key,
    required this.activeIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      _SidebarItem(Icons.home_outlined, Icons.home, 'Übersicht'),
      _SidebarItem(Icons.account_balance_outlined, Icons.account_balance, 'Girokonto'),
      _SidebarItem(Icons.credit_card_outlined, Icons.credit_card, 'DKB-Visa'),
      _SidebarItem(Icons.send_outlined, Icons.send, 'Überweisung'),
      _SidebarItem(Icons.menu_outlined, Icons.menu, 'Mehr'),
    ];

    final totalBalance = MockData.girokonto.saldo + MockData.visaKarte.verfuegbaresLimit;

    return Container(
      width: 240,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: DkbColors.navyGradient,
        boxShadow: [
          BoxShadow(
            color: Color(0x221C2B56),
            blurRadius: 20,
            offset: Offset(4, 0),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // DKB logo
                Container(
                  width: 140,
                  height: 72,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(DkbRadius.md),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(8),
                  child: Image.asset(
                    'assets/images/dkb_logo.png',
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  MockData.user.name,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  GermanFormatter.waehrung(totalBalance),
                  style: GoogleFonts.inter(
                    color: DkbColors.accent,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Gesamtvermögen',
                  style: GoogleFonts.inter(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          Container(height: 1, color: Colors.white.withValues(alpha: 0.1)),

          const SizedBox(height: 12),

          // Nav items
          ...List.generate(
            items.length,
            (i) => _SidebarNavItem(
              item: items[i],
              isActive: activeIndex == i,
              onTap: () => onTap(i),
            ),
          ),

          const Spacer(),

          // Abmelden
          Padding(
            padding: const EdgeInsets.all(16),
            child: InkWell(
              onTap: () {
                AppState().abmelden();
                Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
              },
              borderRadius: BorderRadius.circular(DkbRadius.sm),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.white.withValues(alpha: 0.5), size: 18),
                    const SizedBox(width: 12),
                    Text(
                      'Abmelden',
                      style: GoogleFonts.inter(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _SidebarItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _SidebarItem(this.icon, this.activeIcon, this.label);
}

class _SidebarNavItem extends StatelessWidget {
  final _SidebarItem item;
  final bool isActive;
  final VoidCallback onTap;

  const _SidebarNavItem({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? Colors.white.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(DkbRadius.sm),
          border: isActive
              ? Border.all(color: Colors.white.withValues(alpha: 0.15))
              : null,
        ),
        child: Row(
          children: [
            Icon(
              isActive ? item.activeIcon : item.icon,
              color: isActive ? DkbColors.accent : Colors.white.withValues(alpha: 0.6),
              size: 20,
            ),
            const SizedBox(width: 14),
            Text(
              item.label,
              style: GoogleFonts.inter(
                color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.6),
                fontSize: 14,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            if (isActive) ...[
              const Spacer(),
              Container(
                width: 3,
                height: 16,
                decoration: BoxDecoration(
                  color: DkbColors.accent,
                  borderRadius: BorderRadius.circular(DkbRadius.full),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
