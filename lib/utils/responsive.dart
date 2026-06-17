import 'package:flutter/material.dart';

class Breakpoints {
  static const double mobile = 480;
  static const double tablet = 768;
  static const double desktop = 1100;
}

class R {
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < Breakpoints.tablet;

  static bool isTablet(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return w >= Breakpoints.tablet && w < Breakpoints.desktop;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= Breakpoints.desktop;

  static bool showSidebar(BuildContext context) =>
      MediaQuery.of(context).size.width >= Breakpoints.desktop;

  static double maxContentWidth(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    if (w >= Breakpoints.desktop) return 960;
    return double.infinity;
  }
}

class MaxWidth extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const MaxWidth({super.key, required this.child, this.maxWidth = 960});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
