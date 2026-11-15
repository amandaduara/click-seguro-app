import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/theme/app_theme.dart';
import 'package:click_seguro_app/modules/help/presentation/widgets/emergency_call_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/localized_app.dart';

void main() {
  late int calls;

  setUp(() => calls = 0);

  Future<void> pump(
    WidgetTester tester, {
    ThemeData? theme,
    Locale locale = const Locale('pt', 'BR'),
  }) => pumpLocalized(
    tester,
    theme: theme,
    locale: locale,
    child: Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [EmergencyCallCard(onCall: () => calls++)],
      ),
    ),
  );

  testWidgets('título, texto e o botão de ligar', (tester) async {
    await pump(tester);

    expect(find.text('Caiu em um golpe?'), findsOneWidget);
    expect(
      find.text('Ligue agora para a polícia e para o seu banco.'),
      findsOneWidget,
    );
    expect(find.text('Ligar para 190'), findsOneWidget);
  });

  testWidgets('em inglês', (tester) async {
    await pump(tester, locale: const Locale('en', 'US'));

    expect(find.text('Fell for a scam?'), findsOneWidget);
    expect(
      find.text('Call the police and your bank right now.'),
      findsOneWidget,
    );
    expect(find.text('Call 190'), findsOneWidget);
  });

  testWidgets('título lido como cabeçalho', (tester) async {
    final semantics = tester.ensureSemantics();
    await pump(tester);

    expect(
      tester.getSemantics(find.text('Caiu em um golpe?')),
      isSemantics(isHeader: true),
    );
    semantics.dispose();
  });

  testWidgets('botão "Ligar para 190": botão na semântica e 48 ou mais', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pump(tester);

    expect(
      tester.getSemantics(find.text('Ligar para 190')),
      isSemantics(label: 'Ligar para 190', isButton: true, hasTapAction: true),
    );
    final Size size = tester.getSize(find.byType(InkWell));
    expect(size.height, greaterThanOrEqualTo(48));
    expect(size.width, greaterThanOrEqualTo(48));
    semantics.dispose();
  });

  // O leitor de tela liga pelo nó do botão (ação de toque da semântica).
  testWidgets('tocar pelo leitor de tela também chama onCall', (tester) async {
    final semantics = tester.ensureSemantics();
    await pump(tester);

    tester.semantics.tap(find.semantics.byLabel('Ligar para 190'));

    expect(calls, 1);
    semantics.dispose();
  });

  testWidgets('tocar no botão chama onCall', (tester) async {
    await pump(tester);

    await tester.tap(find.text('Ligar para 190'));

    expect(calls, 1);
  });

  testWidgets('alto contraste: cores do tema de alto contraste', (
    tester,
  ) async {
    await pump(tester, theme: AppTheme.highContrastTheme);

    final BoxDecoration card =
        tester
                .widget<Container>(
                  find
                      .descendant(
                        of: find.byType(EmergencyCallCard),
                        matching: find.byType(Container),
                      )
                      .first,
                )
                .decoration!
            as BoxDecoration;
    expect(card.color, AppPalette.highContrast.primary);
    expect(
      tester.widget<Text>(find.text('Ligar para 190')).style?.color,
      AppPalette.highContrast.primary,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('letra 2× numa tela estreita: sem estouro', (tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await pump(tester, theme: AppTheme.highContrastTheme);

    expect(tester.takeException(), isNull);
    expect(find.text('Ligar para 190'), findsOneWidget);
    expect(
      tester.getSize(find.byType(InkWell)).height,
      greaterThanOrEqualTo(48),
    );
  });
}
