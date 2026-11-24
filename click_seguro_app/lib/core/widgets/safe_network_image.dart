import 'dart:math' as math;

import 'package:click_seguro_app/core/theme/app_motion.dart';
import 'package:flutter/material.dart';

/// Imagem da rede (specs/022 R11, FR-029 a FR-031): decodifica no tamanho
/// mostrado, esmaece ao chegar e mostra [placeholder] sem endereço, enquanto
/// carrega e se falhar. O que já estava no cache aparece na hora.
///
/// Decodifica pelo maior lado do quadro ([width] ou a largura da tela, e
/// [height]), para que `BoxFit.cover` não estique a imagem; nunca maior que
/// o original. Sem `LayoutBuilder`, porque ele quebra dentro de
/// `IntrinsicHeight`.
class SafeNetworkImage extends StatelessWidget {
  const SafeNetworkImage({
    super.key,
    required this.url,
    required this.placeholder,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.padding = EdgeInsets.zero,
  });

  final String? url;
  final Widget placeholder;
  final double? width;
  final double? height;
  final BoxFit fit;

  /// Espaço em volta que só existe quando a imagem aparece (sem ela, nem o
  /// espaço fica).
  final EdgeInsetsGeometry padding;

  /// Largura de decodificação em pixels: o maior lado do quadro.
  static int? _decodeWidth(
    BuildContext context,
    double? width,
    double? height,
  ) {
    double? finite(double? value) =>
        value != null && value.isFinite ? value : null;
    final double side = math.max(
      finite(width) ?? MediaQuery.sizeOf(context).width,
      finite(height) ?? 0,
    );
    final int pixels = (side * MediaQuery.devicePixelRatioOf(context)).round();
    return pixels > 0 ? pixels : null;
  }

  /// Carrega [url] no cache com a mesma chave que um [SafeNetworkImage] de
  /// [width] × [height] vai pedir; falhas ficam para o widget mostrar.
  static Future<void> precache(
    BuildContext context,
    String url, {
    double? width,
    double? height,
  }) => precacheImage(
    ResizeImage.resizeIfNeeded(
      _decodeWidth(context, width, height),
      null,
      NetworkImage(url),
    ),
    context,
    onError: (_, _) {},
  );

  @override
  Widget build(BuildContext context) {
    final String? src = url;
    if (src == null) return placeholder;
    final Duration fade = AppMotion.of(context).medium;
    return Image.network(
      src,
      width: width,
      height: height,
      fit: fit,
      cacheWidth: _decodeWidth(context, width, height),
      excludeFromSemantics: true,
      errorBuilder: (_, _, _) => placeholder,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded) {
          return Padding(padding: padding, child: child);
        }
        if (frame == null) return placeholder;
        return Padding(
          padding: padding,
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: 1),
            duration: fade,
            curve: AppMotion.standard,
            child: child,
            builder: (context, opacity, child) =>
                Opacity(opacity: opacity, child: child),
          ),
        );
      },
    );
  }
}
