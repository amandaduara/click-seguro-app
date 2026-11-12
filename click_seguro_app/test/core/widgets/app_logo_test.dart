import 'package:click_seguro_app/core/constants/app_identity.dart';
import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/theme/app_theme.dart';
import 'package:click_seguro_app/core/widgets/app_logo.dart';
import 'package:click_seguro_app/core/widgets/brand_mark.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

BrandMarkPainter _painter(WidgetTester tester) =>
    tester
            .widget<CustomPaint>(
              find.descendant(
                of: find.byType(AppLogo),
                matching: find.byType(CustomPaint),
              ),
            )
            .painter!
        as BrandMarkPainter;

void main() {
  testWidgets('desenha a marca em primary, no tamanho pedido', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const Center(child: AppLogo(size: 96)),
      ),
    );

    expect(tester.getSize(find.byType(AppLogo)), const Size(96, 96));
    expect(_painter(tester).color, AppPalette.light.primary);
    expect(find.byType(Image), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('no alto contraste usa o primary do alto contraste', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.highContrastTheme,
        home: const Center(child: AppLogo(size: 96)),
      ),
    );

    expect(_painter(tester).color, AppPalette.highContrast.primary);
  });

  testWidgets('logo decorativa não duplica o nome para leitor de tela', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      const MaterialApp(
        home: Column(children: [AppLogo(), Text(AppIdentity.name)]),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Click Seguro'), findsOneWidget);
    semantics.dispose();
  });
}
