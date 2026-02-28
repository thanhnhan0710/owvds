import 'package:flutter/material.dart';

class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    required this.desktop,
  });

  // Breakpoint: Dưới 800px coi là mobile/tablet dọc, trên 800px là desktop
  
  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 800;

  // --- BỔ SUNG HÀM NÀY ĐỂ SỬA LỖI ---
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 800;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 800) {
          return desktop;
        } else {
          return mobile;
        }
      },
    );
  }
}