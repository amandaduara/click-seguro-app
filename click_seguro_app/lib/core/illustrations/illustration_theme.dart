import 'package:click_seguro_app/core/illustrations/app_illustration.dart';
import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:flutter/material.dart';

/// Tema da ilustração de capa, reconhecido num texto livre: o título do
/// módulo ou a categoria e o título da notícia (FR-014, R7 de
/// specs/023-redesign-visual). Fica no `core` porque atividades e notícias
/// usam a mesma regra.
enum IllustrationTheme {
  whatsapp(AppIllustration.themeWhatsapp, [
    'whatsapp',
    'zap',
    'falso parente',
    'mensagem de parente',
  ]),
  pix(AppIllustration.themePix, [
    'pix',
    'boleto',
    'transferencia',
    'pagamento',
    'bank slip',
    'payment',
  ]),
  link(AppIllustration.themeLink, [
    'link',
    'phishing',
    'e-mail',
    'email',
    'sms',
    'mensagem suspeita',
    'mensagens suspeitas',
  ]),
  call(AppIllustration.themeCall, [
    'ligac',
    'telefone',
    'central falsa',
    'call',
    'phone',
  ]),
  password(AppIllustration.themePassword, [
    'senha',
    'password',
    'conta invadida',
    'dois fatores',
    '2fa',
  ]),
  fakeNews(AppIllustration.themeFakeNews, [
    'fake',
    'boato',
    'desinformacao',
    'noticia falsa',
    'hoax',
    'misinformation',
  ]),
  generic(AppIllustration.themeGeneric, []);

  const IllustrationTheme(this.illustration, this._keywords);

  final AppIllustration illustration;
  final List<String> _keywords;

  /// O primeiro tema, na ordem acima, com uma palavra-chave no [text]
  /// (sem diferença de maiúsculas e acentos); senão [generic].
  static IllustrationTheme fromText(String? text) {
    final String normalized = _normalize(text ?? '');
    if (normalized.isEmpty) return generic;
    for (final IllustrationTheme theme in values) {
      if (theme._keywords.any(normalized.contains)) return theme;
    }
    return generic;
  }

  /// Fundo pastel da capa; branco no alto contraste.
  Color pastel(AppPalette palette) => switch (this) {
    whatsapp || fakeNews => palette.pastelPeach,
    pix => palette.pastelSage,
    link => palette.pastelSky,
    call => palette.pastelButter,
    password => palette.pastelLilac,
    generic => palette.surface,
  };

  static const Map<String, String> _accents = {
    'á': 'a',
    'à': 'a',
    'â': 'a',
    'ã': 'a',
    'ä': 'a',
    'é': 'e',
    'ê': 'e',
    'è': 'e',
    'ë': 'e',
    'í': 'i',
    'î': 'i',
    'ì': 'i',
    'ï': 'i',
    'ó': 'o',
    'ô': 'o',
    'õ': 'o',
    'ò': 'o',
    'ö': 'o',
    'ú': 'u',
    'û': 'u',
    'ù': 'u',
    'ü': 'u',
    'ç': 'c',
    'ñ': 'n',
  };

  static String _normalize(String text) {
    final StringBuffer buffer = StringBuffer();
    for (final String char in text.toLowerCase().split('')) {
      buffer.write(_accents[char] ?? char);
    }
    return buffer.toString().trim();
  }
}
