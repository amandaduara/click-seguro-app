import 'package:click_seguro_app/core/widgets/brand_mark.dart';
import 'package:flutter/material.dart';

/// Logo oficial desenhado em código, na cor `primary` do tema (segue o alto
/// contraste). Sempre decorativo: o nome da marca vem escrito ao lado.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 48});

  final double size;

  @override
  Widget build(BuildContext context) => BrandMark(size: size);
}
