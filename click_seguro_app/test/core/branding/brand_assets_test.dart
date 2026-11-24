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
  const String res = 'android/app/src/main/res';

  test('o logo oficial (SVG) só usa a cor primary', () {
    final String svg = File(
      'assets/branding/click_seguro_logo.svg',
    ).readAsStringSync();
    final Iterable<String> colors = RegExp(
      r'#[0-9A-Fa-f]{6}',
    ).allMatches(svg).map((match) => match.group(0)!.toUpperCase());

    expect(colors, isNotEmpty);
    expect(colors, everyElement(primary));
  });

  test('o manifest web usa primary e o fundo do app', () {
    final Map<String, dynamic> manifest =
        jsonDecode(File('web/manifest.json').readAsStringSync())
            as Map<String, dynamic>;

    expect(manifest['theme_color'], primary);
    expect(manifest['background_color'], background);
  });

  test('o fundo da abertura nativa do Android é o fundo do app', () {
    final String xml = File('$res/values/colors.xml').readAsStringSync();

    expect(
      xml,
      contains('<color name="launcher_background">$background</color>'),
    );
  });

  for (final String folder in ['drawable', 'drawable-v21']) {
    test('$folder/launch_background.xml não tem logo estático (bitmap)', () {
      final String xml = File(
        '$res/$folder/launch_background.xml',
      ).readAsStringSync();

      expect(xml, isNot(contains('<bitmap')));
    });
  }

  // Ícone do app: logo branco sobre o vermelho da marca. O fundo do ícone
  // adaptativo tem cor própria; a abertura nativa continua no fundo do app.
  test('o ícone adaptativo do Android tem o fundo primary', () {
    const String res = 'android/app/src/main/res';
    final String adaptive = File(
      '$res/mipmap-anydpi-v26/ic_launcher.xml',
    ).readAsStringSync();
    final String colors = File('$res/values/colors.xml').readAsStringSync();

    expect(adaptive, contains('@color/ic_launcher_background'));
    expect(
      colors,
      contains('<color name="ic_launcher_background">$primary</color>'),
    );
  });

  test('o fundo da abertura nativa do iOS é o fundo do app', () {
    final String storyboard = File(
      'ios/Runner/Base.lproj/LaunchScreen.storyboard',
    ).readAsStringSync();
    String channel(double value) =>
        value.toStringAsFixed(3).replaceFirst(RegExp(r'\.?0+$'), '');
    const Color bg = AppColors.background;

    expect(
      storyboard,
      contains(
        'red="${channel(bg.r)}" green="${channel(bg.g)}" '
        'blue="${channel(bg.b)}"',
      ),
    );
  });
}
