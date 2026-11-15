import 'dart:convert';
import 'dart:io';

import 'package:click_seguro_app/core/theme/app_colors.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

/// `#RRGGBB` de uma cor do design system.
String _hex(Color color) =>
    '#${(color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

/// Os arquivos de marca do projeto (SVG, manifest web, abertura nativa)
/// seguem as cores do design system em vigor (`AppColors`), não valores
/// fixos: assim acompanham a paleta 2.0 (specs/023, specs/024).
void main() {
  final String primary = _hex(AppColors.primary);
  final String background = _hex(AppColors.background);

  group('logo oficial', () {
    late String svg;

    setUpAll(
      () => svg = File(
        'assets/branding/click_seguro_logo.svg',
      ).readAsStringSync(),
    );

    test('não tem mais o terracota antigo: só cores primary', () {
      final Iterable<String> colors = RegExp(
        r'#[0-9A-Fa-f]{6}',
      ).allMatches(svg).map((match) => match.group(0)!.toUpperCase());

      expect(colors, isNotEmpty);
      expect(colors, everyElement(primary));
    });

    test('usa primary no preenchimento e no traço', () {
      expect(svg, contains('fill="$primary"'));
      expect(svg, contains('stroke="$primary"'));
    });
  });

  test('o manifest web usa primary e o fundo do app', () {
    final Map<String, dynamic> manifest =
        jsonDecode(File('web/manifest.json').readAsStringSync())
            as Map<String, dynamic>;

    expect(manifest['theme_color'], primary);
    expect(manifest['background_color'], background);
  });

  test('o fundo da abertura nativa do Android é o fundo do app', () {
    final String xml = File(
      'android/app/src/main/res/values/colors.xml',
    ).readAsStringSync();

    expect(
      xml,
      contains('<color name="launcher_background">$background</color>'),
    );
  });

  group('abertura nativa só com o fundo (sem logo estático)', () {
    const String res = 'android/app/src/main/res';

    for (final String folder in ['drawable', 'drawable-v21']) {
      test('$folder/launch_background.xml não tem bitmap', () {
        final String xml = File(
          '$res/$folder/launch_background.xml',
        ).readAsStringSync();

        expect(xml, isNot(contains('<bitmap')));
        expect(xml, contains('@color/launcher_background'));
      });
    }

    for (final String folder in ['values-v31', 'values-night-v31']) {
      test('$folder aponta o ícone animado para o drawable transparente', () {
        final String xml = File('$res/$folder/styles.xml').readAsStringSync();

        expect(
          xml,
          contains(
            '<item name="android:windowSplashScreenAnimatedIcon">'
            '@drawable/splash_icon_transparent</item>',
          ),
        );
      });
    }

    test('o drawable transparente existe e não desenha nada', () {
      final String xml = File(
        '$res/drawable/splash_icon_transparent.xml',
      ).readAsStringSync();

      expect(xml, contains('<shape'));
      expect(xml, contains('android:color="@android:color/transparent"'));
    });

    test('as imagens da abertura saíram do Android e do iOS', () {
      for (final String density in [
        'mdpi',
        'hdpi',
        'xhdpi',
        'xxhdpi',
        'xxxhdpi',
      ]) {
        expect(
          File('$res/drawable-$density/launch_logo.png').existsSync(),
          isFalse,
          reason: 'launch_logo.png ($density)',
        );
      }
      expect(
        Directory(
          'ios/Runner/Assets.xcassets/LaunchImage.imageset',
        ).existsSync(),
        isFalse,
      );
    });

    test('LaunchScreen.storyboard: sem imagem e com o fundo do app', () {
      final String storyboard = File(
        'ios/Runner/Base.lproj/LaunchScreen.storyboard',
      ).readAsStringSync();

      expect(storyboard, isNot(contains('LaunchImage')));
      expect(storyboard, isNot(contains('<imageView')));
      // O fundo da abertura emenda com a primeira tela da splash.
      String channel(int value) =>
          (value / 255).toStringAsFixed(3).replaceFirst(RegExp(r'\.?0+$'), '');
      const Color bg = AppColors.background;
      expect(
        storyboard,
        contains(
          'red="${channel((bg.r * 255).round())}" '
          'green="${channel((bg.g * 255).round())}" '
          'blue="${channel((bg.b * 255).round())}"',
        ),
      );
    });
  });
}
