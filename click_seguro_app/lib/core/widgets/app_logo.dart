import 'package:flutter/material.dart';

/// Official artwork, exported from assets/branding/click_seguro_logo.svg.
/// Always decorative: the brand name is shown next to it.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 48});

  static const asset = 'assets/branding/click_seguro_logo.png';
  final double size;

  @override
  Widget build(BuildContext context) => Image.asset(
    asset,
    width: size,
    height: size,
    fit: BoxFit.contain,
    excludeFromSemantics: true,
  );
}
