import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/widgets/brand_mark.dart';
import 'package:flutter/material.dart';

/// Logo oficial desenhado em código ([BrandMarkPainter]), na cor `primary`
/// do tema (segue o alto contraste). Sempre decorativo: o nome da marca vem
/// escrito ao lado.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 48});

  final double size;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: CustomPaint(
      size: Size.square(size),
      painter: BrandMarkPainter(color: context.colors.primary),
    ),
  );
}
