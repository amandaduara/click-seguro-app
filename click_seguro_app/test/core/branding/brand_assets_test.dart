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
}
