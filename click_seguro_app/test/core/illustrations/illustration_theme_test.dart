import 'package:click_seguro_app/core/illustrations/app_illustration.dart';
import 'package:click_seguro_app/core/illustrations/illustration_theme.dart';
import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tema da ilustração pelo título do módulo ou pela categoria da notícia
/// (FR-014, R7 de specs/022-redesign-visual).
void main() {
  group('IllustrationTheme.fromText', () {
    const Map<String, IllustrationTheme> cases = {
      // português
      'Golpes no WhatsApp': IllustrationTheme.whatsapp,
      'Falso parente pede dinheiro': IllustrationTheme.whatsapp,
      'Pix e boletos falsos': IllustrationTheme.pix,
      'Boleto adulterado': IllustrationTheme.pix,
      'Links e mensagens suspeitas': IllustrationTheme.link,
      'Phishing por e-mail': IllustrationTheme.link,
      'Ligações falsas': IllustrationTheme.call,
      'Central falsa do banco': IllustrationTheme.call,
      'Senhas seguras': IllustrationTheme.password,
      'Conta invadida': IllustrationTheme.password,
      'Fake news nas redes': IllustrationTheme.fakeNews,
      'Boatos e desinformação': IllustrationTheme.fakeNews,
      // inglês
      'WhatsApp scams': IllustrationTheme.whatsapp,
      'Fake bank slip': IllustrationTheme.pix,
      'Suspicious email links': IllustrationTheme.link,
      'Phone call scams': IllustrationTheme.call,
      'Strong passwords': IllustrationTheme.password,
      'Hoax and misinformation': IllustrationTheme.fakeNews,
      // maiúsculas e acentos
      'LIGAÇÃO falsa': IllustrationTheme.call,
      'DESINFORMAÇÃO': IllustrationTheme.fakeNews,
      // ordem da tabela: o primeiro tema que bate vence
      'Pix pedido pelo WhatsApp': IllustrationTheme.whatsapp,
      // nada bate
      'Golpes digitais': IllustrationTheme.generic,
      '': IllustrationTheme.generic,
    };

    for (final MapEntry<String, IllustrationTheme> entry in cases.entries) {
      test('"${entry.key}" → ${entry.value.name}', () {
        expect(IllustrationTheme.fromText(entry.key), entry.value);
      });
    }

    test('sem texto → generic', () {
      expect(IllustrationTheme.fromText(null), IllustrationTheme.generic);
    });
  });

  group('ilustração e cor de cada tema', () {
    test('cada tema aponta para a sua ilustração de capa', () {
      expect(
        IllustrationTheme.whatsapp.illustration,
        AppIllustration.themeWhatsapp,
      );
      expect(IllustrationTheme.pix.illustration, AppIllustration.themePix);
      expect(IllustrationTheme.link.illustration, AppIllustration.themeLink);
      expect(IllustrationTheme.call.illustration, AppIllustration.themeCall);
      expect(
        IllustrationTheme.password.illustration,
        AppIllustration.themePassword,
      );
      expect(
        IllustrationTheme.fakeNews.illustration,
        AppIllustration.themeFakeNews,
      );
      expect(
        IllustrationTheme.generic.illustration,
        AppIllustration.themeGeneric,
      );
    });

    test('pastel do tema no claro', () {
      const AppPalette p = AppPalette.light;
      expect(IllustrationTheme.whatsapp.pastel(p), p.pastelPeach);
      expect(IllustrationTheme.pix.pastel(p), p.pastelSage);
      expect(IllustrationTheme.link.pastel(p), p.pastelSky);
      expect(IllustrationTheme.call.pastel(p), p.pastelButter);
      expect(IllustrationTheme.password.pastel(p), p.pastelLilac);
      expect(IllustrationTheme.fakeNews.pastel(p), p.pastelPeach);
      expect(IllustrationTheme.generic.pastel(p), p.surface);
    });

    test('no alto contraste, todo pastel é branco', () {
      for (final IllustrationTheme theme in IllustrationTheme.values) {
        expect(
          theme.pastel(AppPalette.highContrast),
          const Color(0xFFFFFFFF),
          reason: theme.name,
        );
      }
    });
  });

  test('toda ilustração tem um asset em assets/illustrations/', () {
    for (final AppIllustration illustration in AppIllustration.values) {
      expect(illustration.asset, startsWith('assets/illustrations/'));
      expect(illustration.asset, endsWith('.svg'));
    }
  });
}
