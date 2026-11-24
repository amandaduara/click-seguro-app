import 'package:click_seguro_app/core/widgets/app_logo.dart';
import 'package:click_seguro_app/modules/authentication/presentation/widgets/auth_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/localized_app.dart';

void main() {
  Future<void> pump(
    WidgetTester tester, {
    Locale locale = const Locale('pt', 'BR'),
  }) => pumpLocalized(
    tester,
    locale: locale,
    child: const Scaffold(body: AuthHeader()),
  );

  // Versão A (specs/026 FR-011): a marca, o título e o slogan da splash,
  // centralizados.
  testWidgets('marca, título e slogan centralizados, nessa ordem', (
    tester,
  ) async {
    await pump(tester);

    final Finder title = find.text('Bem-vindo ao Click Seguro');
    final Finder tagline = find.text('Sua segurança em primeiro lugar');
    expect(find.byType(AppLogo), findsOneWidget);
    expect(title, findsOneWidget);
    expect(tagline, findsOneWidget);

    final double center = tester.getSize(find.byType(Scaffold)).width / 2;
    for (final Finder finder in [find.byType(AppLogo), title, tagline]) {
      expect(tester.getCenter(finder).dx, closeTo(center, 1));
    }
    expect(
      tester.getBottomLeft(find.byType(AppLogo)).dy,
      lessThanOrEqualTo(tester.getTopLeft(title).dy),
    );
    expect(
      tester.getBottomLeft(title).dy,
      lessThanOrEqualTo(tester.getTopLeft(tagline).dy),
    );
  });

  testWidgets('a marca tem 68 de largura', (tester) async {
    await pump(tester);

    expect(tester.getSize(find.byType(AppLogo)).width, 68);
  });

  testWidgets('leitor de tela: um só cabeçalho com título e slogan', (
    tester,
  ) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await pump(tester);

    final data = tester
        .getSemantics(find.byType(AuthHeader))
        .getSemanticsData();
    expect(data.flagsCollection.isHeader, isTrue);
    expect(data.label, contains('Bem-vindo ao Click Seguro'));
    expect(data.label, contains('Sua segurança em primeiro lugar'));
    handle.dispose();
  });

  testWidgets('em inglês', (tester) async {
    await pump(tester, locale: const Locale('en', 'US'));

    expect(find.text('Welcome to Click Seguro'), findsOneWidget);
    expect(find.text('Your safety comes first'), findsOneWidget);
  });
}
