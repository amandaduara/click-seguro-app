import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Os arquivos de marca do projeto (SVG, manifest web) seguem a cor primary
/// do design system (`#FE3152`), não o terracota antigo (specs/023).
void main() {
  group('logo oficial', () {
    late String svg;

    setUpAll(
      () => svg = File(
        'assets/branding/click_seguro_logo.svg',
      ).readAsStringSync(),
    );

    test('não tem mais o terracota antigo', () {
      expect(svg.toUpperCase(), isNot(contains('C0503E')));
    });

    test('usa primary no preenchimento e no traço', () {
      expect(svg, contains('fill="#FE3152"'));
      expect(svg, contains('stroke="#FE3152"'));
    });
  });

  test('o manifest web usa primary como theme_color', () {
    final Map<String, dynamic> manifest =
        jsonDecode(File('web/manifest.json').readAsStringSync())
            as Map<String, dynamic>;

    expect(manifest['theme_color'], '#FE3152');
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

    test('LaunchScreen.storyboard: sem imagem e com o fundo #FFFDFB', () {
      final String storyboard = File(
        'ios/Runner/Base.lproj/LaunchScreen.storyboard',
      ).readAsStringSync();

      expect(storyboard, isNot(contains('LaunchImage')));
      expect(storyboard, isNot(contains('<imageView')));
      expect(storyboard, contains('red="1" green="0.992" blue="0.984"'));
    });
  });
}
