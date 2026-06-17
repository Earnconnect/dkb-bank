import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'press_scale.dart';

class QuickAction {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isAccent;

  const QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isAccent = false,
  });
}

class QuickActionsWidget extends StatelessWidget {
  final List<QuickAction> actions;

  const QuickActionsWidget({super.key, required this.actions});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: actions
          .map((a) => Expanded(child: _QuickActionButton(action: a)))
          .toList(),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final QuickAction action;

  const _QuickActionButton({required this.action});

  @override
  Widget build(BuildContext context) {
    return PressScale(
      onTap: action.onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: action.isAccent ? DkbColors.accentGradient : DkbColors.navyGradient,
              borderRadius: BorderRadius.circular(DkbRadius.md),
              boxShadow: DkbShadows.sm,
            ),
            child: Icon(action.icon, color: Colors.white, size: 22),
          ),
          const SizedBox(height: 7),
          Text(
            action.label,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: DkbColors.textSecondary,
            ),
            maxLines: 2,
          ),
        ],
      ),
    );
  }
}
