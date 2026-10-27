import 'package:click_seguro_app/core/constants/app_identity.dart';
import 'package:flutter/material.dart';

/// Official artwork, exported from assets/branding/click_seguro_logo.svg.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 48, this.excludeFromSemantics = true});

  static const asset = 'assets/branding/click_seguro_logo.png';
  final double size;
  final bool excludeFromSemantics;

  @override
  Widget build(BuildContext context) => Image.asset(
    asset,
    width: size,
    height: size,
    fit: BoxFit.contain,
    excludeFromSemantics: excludeFromSemantics,
    semanticLabel: excludeFromSemantics ? null : AppIdentity.name,
  );
}
