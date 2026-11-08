import 'package:click_seguro_app/core/illustrations/app_illustration.dart';
import 'package:click_seguro_app/core/theme/app_theme.dart';
import 'package:click_seguro_app/core/widgets/safe_illustration.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

/// Ilustração decorativa em SVG, recolorida no alto contraste (FR-002,
/// FR-017, R5 de specs/022-redesign-visual).
void main() {
  Future<SvgAssetLoader> pump(WidgetTester tester, ThemeData theme) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: const Scaffold(
          body: SafeIllustration(AppIllustration.stateError, height: 120),
        ),
      ),
    );
    final SvgPicture picture = tester.widget(find.byType(SvgPicture));
    return picture.bytesLoader as SvgAssetLoader;
  }

  testWidgets('desenha o SVG da ilustração pedida, na altura pedida', (
    tester,
  ) async {
    final SvgAssetLoader loader = await pump(tester, AppTheme.lightTheme);

    expect(loader.assetName, AppIllustration.stateError.asset);
    expect(tester.getSize(find.byType(SafeIllustration)).height, 120);
  });

  testWidgets('é decorativa: fica fora da árvore de semântica', (tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await pump(tester, AppTheme.lightTheme);

    expect(
      find.descendant(
        of: find.byType(SafeIllustration),
        matching: find.byWidgetPredicate(
          (widget) => widget is Semantics && widget.properties.label != null,
        ),
      ),
      findsNothing,
    );
    expect(find.byType(ExcludeSemantics), findsWidgets);
    handle.dispose();
  });

  testWidgets('tema normal: cores originais', (tester) async {
    final SvgAssetLoader loader = await pump(tester, AppTheme.lightTheme);

    expect(loader.colorMapper, isNull);
  });

  testWidgets('alto contraste: troca as cores da ilustração', (tester) async {
    final SvgAssetLoader loader = await pump(
      tester,
      AppTheme.highContrastTheme,
    );

    final ColorMapper mapper = loader.colorMapper!;
    Color map(int hex) => mapper.substitute(null, 'path', 'fill', Color(hex));

    expect(map(0xFFFFD9CE), const Color(0xFFFFFFFF)); // pêssego → branco
    expect(map(0xFF1B2440), const Color(0xFF000000)); // tinta → preto
    expect(map(0xFFE31C3D), const Color(0xFF9E0019)); // coral → coral AAA
    expect(map(0xFF0F7B4F), const Color(0xFF005A3C)); // verde → verde AAA
  });
}
