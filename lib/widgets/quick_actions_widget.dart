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
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: actions.map((a) => _QuickActionButton(action: a)).toList(),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final QuickAction action;

  const _QuickActionButton({required this.action});

  @override
  Widget build(BuildContext context) {
    final iconColor = action.isAccent ? DkbColors.accent : DkbColors.primary;

    return PressScale(
      onTap: action.onTap,
      child: SizedBox(
        width: 72,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.08),
                shape: BoxShape.circle,
                border: Border.all(
                  color: iconColor.withValues(alpha: 0.18),
                  width: 1.5,
                ),
              ),
              child: Icon(action.icon, color: iconColor, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              action.label,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: DkbColors.textSecondary,
                height: 1.3,
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }
}
