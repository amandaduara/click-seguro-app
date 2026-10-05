import 'package:click_seguro_app/core/widgets/safe_empty_state.dart';
import 'package:click_seguro_app/core/widgets/safe_error_state.dart';
import 'package:click_seguro_app/core/widgets/safe_loading_state.dart';
import 'package:click_seguro_app/core/widgets/safe_offline_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/localized_app.dart';

/// FR-015/FR-016 de specs/005-shell-navegacao-base: os quatro estados comuns,
/// com 48 dp de toque e 16 sp nos textos de leitura.
void main() {
  // TickerMode desligado: o indicador de progresso anima sem fim e impediria
  // o pumpAndSettle do helper de terminar.
  Future<void> pump(WidgetTester tester, Widget state) => pumpLocalized(
    tester,
    child: Scaffold(body: TickerMode(enabled: false, child: state)),
  );

  double fontSizeOf(WidgetTester tester, String text) {
    final RenderParagraph paragraph = tester.renderObject(find.text(text));
    return paragraph.text.style!.fontSize!;
  }

  void expectTapTarget(WidgetTester tester, Finder finder) {
    final size = tester.getSize(finder);
    expect(size.width, greaterThanOrEqualTo(48));
    expect(size.height, greaterThanOrEqualTo(48));
  }

  group('SafeLoadingState', () {
    testWidgets('indicador com semântica "Carregando"', (tester) async {
      final semantics = tester.ensureSemantics();
      await pump(tester, const SafeLoadingState());

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.bySemanticsLabel('Carregando'), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('texto opcional com 16 px', (tester) async {
      await pump(tester, const SafeLoadingState(message: 'Buscando notícias'));

      expect(fontSizeOf(tester, 'Buscando notícias'), greaterThanOrEqualTo(16));
    });
  });

  group('SafeErrorState', () {
    testWidgets('mensagem e "Tentar novamente" que repete', (tester) async {
      var retries = 0;
      await pump(
        tester,
        SafeErrorState(message: 'Falhou', onRetry: () => retries++),
      );

      expect(find.text('Falhou'), findsOneWidget);
      expect(fontSizeOf(tester, 'Falhou'), greaterThanOrEqualTo(16));

      await tester.tap(find.text('Tentar novamente'));
      await tester.pumpAndSettle();
      expect(retries, 1);
    });

    testWidgets('botão com pelo menos 48×48', (tester) async {
      await pump(tester, SafeErrorState(message: 'Falhou', onRetry: () {}));

      expectTapTarget(
        tester,
        find
            .ancestor(
              of: find.text('Tentar novamente'),
              matching: find.byType(GestureDetector),
            )
            .first,
      );
    });
  });

  group('SafeEmptyState', () {
    testWidgets('mensagem padrão e nenhum botão', (tester) async {
      await pump(tester, const SafeEmptyState());

      expect(find.text('Nada por aqui ainda.'), findsOneWidget);
      expect(
        fontSizeOf(tester, 'Nada por aqui ainda.'),
        greaterThanOrEqualTo(16),
      );
      expect(find.byType(GestureDetector), findsNothing);
    });

    testWidgets('mensagem e ação da tela', (tester) async {
      var actions = 0;
      await pump(
        tester,
        SafeEmptyState(
          message: 'Nenhum contato',
          actionLabel: 'Adicionar',
          onAction: () => actions++,
        ),
      );

      expect(find.text('Nenhum contato'), findsOneWidget);
      final button = find
          .ancestor(
            of: find.text('Adicionar'),
            matching: find.byType(GestureDetector),
          )
          .first;
      expectTapTarget(tester, button);

      await tester.tap(button);
      expect(actions, 1);
    });
  });

  group('SafeOfflineBanner', () {
    testWidgets('faixa de largura total com o aviso em 16 px', (tester) async {
      await pump(tester, const Column(children: [SafeOfflineBanner()]));

      const text = 'Você está sem internet. Mostrando o conteúdo salvo.';
      expect(find.text(text), findsOneWidget);
      expect(fontSizeOf(tester, text), greaterThanOrEqualTo(16));
      expect(
        tester.getSize(find.byType(SafeOfflineBanner)).width,
        tester.view.physicalSize.width / tester.view.devicePixelRatio,
      );
    });
  });

  testWidgets('fonte em 200% não estoura nenhum estado', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await pump(
      tester,
      ListView(
        children: [
          const SafeOfflineBanner(),
          const SizedBox(
            height: 200,
            child: SafeLoadingState(message: 'Buscando'),
          ),
          SizedBox(
            height: 300,
            child: SafeErrorState(message: 'Falhou', onRetry: () {}),
          ),
          SizedBox(
            height: 300,
            child: SafeEmptyState(actionLabel: 'Adicionar', onAction: () {}),
          ),
        ],
      ),
    );

    expect(tester.takeException(), isNull);
  });
}
