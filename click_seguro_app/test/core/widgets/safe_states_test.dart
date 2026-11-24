import 'package:click_seguro_app/core/errors/errors.dart';
import 'package:click_seguro_app/core/widgets/safe_empty_state.dart';
import 'package:click_seguro_app/core/widgets/safe_error_state.dart';
import 'package:click_seguro_app/core/widgets/safe_loading_state.dart';
import 'package:click_seguro_app/core/widgets/safe_offline_banner.dart';
import 'package:click_seguro_app/core/illustrations/app_illustration.dart';
import 'package:click_seguro_app/core/widgets/safe_illustration.dart';
import 'package:click_seguro_app/core/widgets/safe_skeleton.dart';
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

      expect(find.byType(SafeSkeleton), findsWidgets);
      expect(find.bySemanticsLabel('Carregando'), findsOneWidget);
      semantics.dispose();
    });
  });

  group('SafeErrorState', () {
    testWidgets('mensagem e "Tentar novamente" que repete', (tester) async {
      var retries = 0;
      await pump(
        tester,
        SafeErrorState(
          failure: null,
          message: 'Falhou',
          onRetry: () => retries++,
        ),
      );

      expect(find.text('Falhou'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is SafeIllustration &&
              widget.illustration == AppIllustration.stateError,
        ),
        findsOneWidget,
      );
      expect(fontSizeOf(tester, 'Falhou'), greaterThanOrEqualTo(16));

      await tester.tap(find.text('Tentar novamente'));
      await tester.pumpAndSettle();
      expect(retries, 1);
    });

    testWidgets('botão com pelo menos 48×48', (tester) async {
      await pump(
        tester,
        SafeErrorState(failure: null, message: 'Falhou', onRetry: () {}),
      );

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

  // specs/027: o desenho e a frase saem do tipo da falha, não do texto.
  group('SafeErrorState decide pela falha', () {
    Finder illustration(AppIllustration which) => find.byWidgetPredicate(
      (widget) => widget is SafeIllustration && widget.illustration == which,
    );
    const String offline = 'Sem conexão com a internet. Verifique sua rede.';

    testWidgets(
      'sem conexão: nuvem e a frase padrão, mesmo com texto da tela',
      (tester) async {
        var retries = 0;
        await pump(
          tester,
          SafeErrorState(
            failure: const ConnectionFailure(),
            message: 'Texto da tela',
            onRetry: () => retries++,
          ),
        );

        expect(illustration(AppIllustration.stateOffline), findsOneWidget);
        expect(find.text(offline), findsOneWidget);
        expect(find.text('Texto da tela'), findsNothing);
        await tester.tap(find.text('Tentar novamente'));
        expect(retries, 1);
      },
    );

    testWidgets('servidor: tomada e o texto da tela', (tester) async {
      await pump(
        tester,
        SafeErrorState(
          failure: const ServerFailure(),
          message: 'Texto da tela',
          onRetry: () {},
        ),
      );

      expect(illustration(AppIllustration.stateError), findsOneWidget);
      expect(find.text('Texto da tela'), findsOneWidget);
    });

    testWidgets('servidor sem texto da tela: o texto da falha', (tester) async {
      await pump(
        tester,
        SafeErrorState(failure: const ServerFailure(), onRetry: () {}),
      );

      expect(illustration(AppIllustration.stateError), findsOneWidget);
      // A mensagem padrão do ServerFailure.
      expect(
        find.text(
          'Não foi possível completar a ação. Tente novamente mais tarde.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('sem falha nem texto: a mensagem genérica', (tester) async {
      await pump(tester, SafeErrorState(failure: null, onRetry: () {}));

      expect(illustration(AppIllustration.stateError), findsOneWidget);
      expect(
        find.text(
          'Não foi possível completar a ação. Tente novamente mais tarde.',
        ),
        findsOneWidget,
      );
    });

    // FR-012: quem usa leitor de tela ouve o aviso quando a tela troca.
    testWidgets('a frase é anunciada ao leitor de tela', (tester) async {
      final semantics = tester.ensureSemantics();
      await pump(
        tester,
        SafeErrorState(failure: const ConnectionFailure(), onRetry: () {}),
      );

      expect(
        tester.getSemantics(find.text(offline)),
        isSemantics(label: offline, isLiveRegion: true),
      );
      semantics.dispose();
    });
  });

  group('SafeEmptyState', () {
    testWidgets('mensagem padrão e nenhum botão', (tester) async {
      await pump(tester, const SafeEmptyState());

      expect(find.text('Nada por aqui ainda.'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is SafeIllustration &&
              widget.illustration == AppIllustration.stateEmpty,
        ),
        findsOneWidget,
      );
      expect(
        fontSizeOf(tester, 'Nada por aqui ainda.'),
        greaterThanOrEqualTo(16),
      );
      expect(find.byType(GestureDetector), findsNothing);
    });

    // O mesmo tamanho das listas do perfil (validação da usuária,
    // specs/024): 16 em seminegrito e a dica mais clara embaixo.
    testWidgets('mensagem em 16 seminegrito e dica opcional', (tester) async {
      await pump(
        tester,
        const SafeEmptyState(message: 'Sem contatos.', hint: 'Cadastre um.'),
      );

      final Text message = tester.widget<Text>(find.text('Sem contatos.'));
      expect(message.style?.fontSize, 16);
      expect(message.style?.fontWeight, FontWeight.w600);
      expect(find.text('Cadastre um.'), findsOneWidget);
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
    testWidgets('faixa de largura total com o aviso em 15 px', (tester) async {
      await pump(tester, const Column(children: [SafeOfflineBanner()]));

      const text = 'Você está sem internet. Mostrando o conteúdo salvo.';
      expect(find.text(text), findsOneWidget);
      expect(fontSizeOf(tester, text), greaterThanOrEqualTo(15));
      expect(
        tester.getSize(find.byType(SafeOfflineBanner)).width,
        tester.view.physicalSize.width / tester.view.devicePixelRatio,
      );
    });

    // FR-011 de specs/027: sem conteúdo salvo, a faixa não promete nada.
    testWidgets('variação curta, sem falar em conteúdo salvo', (tester) async {
      final semantics = tester.ensureSemantics();
      await pump(
        tester,
        const Column(children: [SafeOfflineBanner(showsSavedContent: false)]),
      );

      const text = 'Você está sem internet.';
      expect(find.text(text), findsOneWidget);
      expect(
        find.text('Você está sem internet. Mostrando o conteúdo salvo.'),
        findsNothing,
      );
      expect(
        tester.getSemantics(find.text(text)),
        isSemantics(label: text, isLiveRegion: true),
      );
      semantics.dispose();
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
          const SizedBox(height: 200, child: SafeLoadingState()),
          SizedBox(
            height: 300,
            child: SafeErrorState(
              failure: null,
              message: 'Falhou',
              onRetry: () {},
            ),
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

  testWidgets('estados continuam utilizáveis em viewport curto e estreito', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(240, 180);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    var retries = 0;
    await pump(
      tester,
      SafeErrorState(
        failure: null,
        message: 'Falhou ao carregar',
        onRetry: () => retries++,
      ),
    );

    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('Tentar novamente'));
    await tester.tap(find.text('Tentar novamente'));
    expect(retries, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ilustrações são decorativas para acessibilidade', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pump(
      tester,
      SafeErrorState(failure: null, message: 'Falhou', onRetry: () {}),
    );

    expect(find.bySemanticsLabel('Falhou'), findsOneWidget);
    expect(find.bySemanticsLabel('Tentar novamente'), findsOneWidget);
    expect(find.bySemanticsLabel('circleAlert'), findsNothing);
    semantics.dispose();
  });
}
