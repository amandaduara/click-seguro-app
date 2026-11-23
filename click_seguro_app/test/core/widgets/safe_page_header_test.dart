import 'package:click_seguro_app/core/theme/app_theme.dart';
import 'package:click_seguro_app/core/widgets/safe_page_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  final Finder back = find.byKey(SafePageHeader.defaultBackKey);

  void usePhone(WidgetTester tester, {double textScale = 1}) {
    tester.view
      ..physicalSize = const Size(1080, 2340)
      ..devicePixelRatio = 3;
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  }

  /// `/home` e `/page` (com o cabeçalho); abre em [initialLocation].
  Future<void> pumpRouter(
    WidgetTester tester, {
    required String initialLocation,
    required SafePageHeader header,
    bool canPop = true,
  }) async {
    final GoRouter router = GoRouter(
      initialLocation: initialLocation,
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, _) => Scaffold(
            body: TextButton(
              onPressed: () => context.push('/page'),
              child: const Text('início'),
            ),
          ),
        ),
        GoRoute(
          path: '/page',
          builder: (_, _) => PopScope(
            canPop: canPop,
            child: SafePageScaffold(header: header, body: const Text('corpo')),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MaterialApp.router(theme: AppTheme.lightTheme, routerConfig: router),
    );
    await tester.pumpAndSettle();
  }

  Future<void> pumpPushed(
    WidgetTester tester,
    SafePageHeader header, {
    bool canPop = true,
  }) async {
    await pumpRouter(
      tester,
      initialLocation: '/home',
      header: header,
      canPop: canPop,
    );
    await tester.tap(find.text('início'));
    await tester.pumpAndSettle();
  }

  testWidgets('voltar usa o maybePop: volta para a tela de trás', (
    tester,
  ) async {
    await pumpPushed(tester, const SafePageHeader(title: 'Alertas'));

    await tester.tap(back);
    await tester.pumpAndSettle();

    expect(find.text('início'), findsOneWidget);
    expect(find.text('Alertas'), findsNothing);
  });

  testWidgets('voltar respeita o PopScope da tela', (tester) async {
    await pumpPushed(
      tester,
      const SafePageHeader(title: 'Alertas', fallbackLocation: '/home'),
      canPop: false,
    );

    await tester.tap(back);
    await tester.pumpAndSettle();

    expect(find.text('Alertas'), findsOneWidget);
  });

  testWidgets('aberta por link direto: o voltar leva ao fallback', (
    tester,
  ) async {
    await pumpRouter(
      tester,
      initialLocation: '/page',
      header: const SafePageHeader(title: 'Alertas', fallbackLocation: '/home'),
    );

    await tester.tap(back);
    await tester.pumpAndSettle();

    expect(find.text('início'), findsOneWidget);
  });

  testWidgets('sem fallback e sem nada atrás, não há voltar', (tester) async {
    await pumpRouter(
      tester,
      initialLocation: '/page',
      header: const SafePageHeader(title: 'Alertas'),
    );

    expect(back, findsNothing);
    expect(find.text('Alertas'), findsOneWidget);
  });

  testWidgets('onBack troca o maybePop', (tester) async {
    int taps = 0;
    await pumpPushed(tester, SafePageHeader(title: 'A', onBack: () => taps++));

    await tester.tap(back);
    await tester.pumpAndSettle();

    expect(taps, 1);
    expect(find.text('A'), findsOneWidget);
  });

  testWidgets('o título fica na mesma linha, logo à direita do voltar; '
      'as ações à direita', (tester) async {
    usePhone(tester);
    await pumpPushed(
      tester,
      const SafePageHeader(
        title: 'Alertas',
        actions: [SizedBox.square(key: Key('ação'), dimension: 48)],
      ),
    );

    final Rect backRect = tester.getRect(back);
    final Rect title = tester.getRect(find.text('Alertas'));
    final Rect action = tester.getRect(find.byKey(const Key('ação')));

    expect(backRect.width, greaterThanOrEqualTo(48));
    expect(title.left, greaterThan(backRect.right));
    expect(title.left - backRect.right, lessThanOrEqualTo(24));
    expect(title.center.dy, moreOrLessEquals(backRect.center.dy, epsilon: 2));
    expect(action.left, greaterThanOrEqualTo(title.right));
    expect(
      tester.getTopLeft(find.text('corpo')).dy,
      greaterThanOrEqualTo(backRect.bottom),
    );
  });

  testWidgets('o título é cabeçalho e o voltar é botão para o leitor de tela', (
    tester,
  ) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    await pumpPushed(tester, const SafePageHeader(title: 'Alertas'));

    expect(
      tester.getSemantics(find.text('Alertas')),
      matchesSemantics(label: 'Alertas', isHeader: true),
    );
    expect(
      tester.getSemantics(back),
      matchesSemantics(
        label: 'Back',
        isButton: true,
        hasEnabledState: true,
        isEnabled: true,
        hasTapAction: true,
      ),
    );
    semantics.dispose();
  });

  testWidgets('voltar desativado: o toque só faz o onBack; leitor de tela '
      'ouve desativado e a dica', (tester) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    int warnings = 0;
    await pumpPushed(
      tester,
      SafePageHeader(
        title: 'Editar',
        backEnabled: false,
        backHint: 'Aguarde o envio.',
        onBack: () => warnings++,
      ),
    );

    await tester.tap(back);
    await tester.pumpAndSettle();
    expect(warnings, 1);
    expect(find.text('Editar'), findsOneWidget);

    expect(
      tester.getSemantics(back),
      matchesSemantics(
        label: 'Back',
        hint: 'Aguarde o envio.',
        isButton: true,
        hasEnabledState: true,
        isEnabled: false,
        hasTapAction: true,
      ),
    );
    semantics.dispose();
  });

  testWidgets('letra 2×: o título longo quebra linha ao lado do voltar, '
      'sem estouro', (tester) async {
    usePhone(tester, textScale: 2);
    await pumpPushed(
      tester,
      const SafePageHeader(title: 'Notícias que você salvou para depois'),
    );

    expect(tester.takeException(), isNull);
    final Rect backRect = tester.getRect(back);
    final Rect title = tester.getRect(
      find.text('Notícias que você salvou para depois'),
    );
    expect(title.left, greaterThan(backRect.right));
    expect(title.right, lessThanOrEqualTo(360));
    expect(title.height, greaterThan(backRect.height));
  });
}
