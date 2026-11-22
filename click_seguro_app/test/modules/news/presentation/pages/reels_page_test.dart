import 'dart:async';

import 'package:click_seguro_app/core/errors/errors.dart';
import 'package:click_seguro_app/core/widgets/safe_network_image.dart';
import 'package:click_seguro_app/core/widgets/safe_skeleton.dart';
import 'package:click_seguro_app/modules/common/accessibility/accessibility_preferences_notifier.dart';
import 'package:click_seguro_app/modules/common/presentation/controller/read_aloud_controller.dart';
import 'package:click_seguro_app/modules/common/services/share_service.dart';
import 'package:click_seguro_app/modules/common/services/user_session_service.dart';
import 'package:click_seguro_app/modules/news/domain/entities/reel_entity.dart';
import 'package:click_seguro_app/modules/news/domain/entities/reels_page_entity.dart';
import 'package:click_seguro_app/modules/news/presentation/controller/reels_controller.dart';
import 'package:click_seguro_app/modules/news/presentation/pages/reels_page.dart';
import 'package:click_seguro_app/modules/news/presentation/routes/news_detail_preview.dart';
import 'package:click_seguro_app/modules/news/domain/entities/like_result_entity.dart';
import 'package:click_seguro_app/modules/news/presentation/widgets/reel_actions.dart';
import 'package:click_seguro_app/modules/news/presentation/widgets/reel_view.dart';
import 'package:click_seguro_app/modules/shell/presentation/widgets/account_required_sheet.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../../fakes/fake_secure_storage_service.dart';
import '../../../../fakes/fake_share_service.dart';
import '../../../../fakes/fake_text_to_speech_service.dart';
import '../../../../helpers/localized_app.dart';
import '../../fakes/fake_news_repository.dart';
import '../../fakes/reels_controller_factory.dart';

void main() {
  late UserSessionService session;
  late FakeNewsRepository repository;
  late FakeShareService share;
  late ReelsController controller;
  late FakeTextToSpeechService tts;
  late AccessibilityPreferencesNotifier preferences;

  setUp(() async {
    session = UserSessionService(FakeSecureStorageService());
    share = FakeShareService();
    tts = FakeTextToSpeechService();
    preferences = AccessibilityPreferencesNotifier();
    GetIt.instance
      ..registerSingleton<UserSessionService>(session)
      ..registerSingleton<ShareService>(share)
      ..registerSingleton<AccessibilityPreferencesNotifier>(preferences)
      ..registerFactory(
        () => ReadAloudController(tts, preferences: preferences),
      );
    await session.startGuestSession();
    repository = FakeNewsRepository();
    controller = buildReelsController(repository, session.sessionStatus);
  });

  tearDown(() async {
    controller.dispose();
    await GetIt.instance.reset();
  });

  void firstPage(int count, {String? next}) => repository.reelsResults[null] =
      Right(ReelsPageEntity(items: reels(count), nextCursor: next));

  /// O `extra` com que o detalhe foi aberto pelo Reel.
  Object? detailExtra;

  GoRouter router({String location = '/reels', Object? extra}) => GoRouter(
    initialLocation: location,
    initialExtra: extra,
    routes: [
      GoRoute(
        path: '/reels',
        builder: (_, state) => ReelsPage.fromState(state),
      ),
      GoRoute(
        path: '/news/:id',
        builder: (_, state) {
          detailExtra = state.extra;
          return Scaffold(body: Text('detalhe ${state.pathParameters['id']}'));
        },
      ),
      GoRoute(
        path: '/login',
        builder: (_, _) => const Scaffold(body: Text('login')),
      ),
    ],
  );

  /// Com [preload], carrega antes de montar: o carregando anima sem fim.
  Future<void> pumpPage(
    WidgetTester tester, {
    String location = '/reels',
    Object? extra,
    bool preload = true,
  }) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    if (preload) await controller.open();
    await pumpLocalized(
      tester,
      router: router(location: location, extra: extra),
      providers: [
        ChangeNotifierProvider<ReelsController>.value(value: controller),
      ],
      settle: preload,
    );
  }

  Finder title(String id) => find.text('Notícia $id');

  Future<void> tapKey(WidgetTester tester, Key key) async {
    await tester.tap(find.byKey(key));
    await tester.pumpAndSettle();
  }

  group('navegação', () {
    testWidgets('carregando mostra o esqueleto', (tester) async {
      firstPage(2);
      repository.reelsGate = Completer<void>();

      await pumpPage(tester, preload: false);
      await tester.pump();

      expect(
        find.byWidgetPredicate((w) => w is SafeSkeleton && w.enabled),
        findsOneWidget,
      );
      expect(find.byType(CircularProgressIndicator), findsNothing);
      // Sobre o preto, o brilho clareia; não escurece numa faixa preta.
      final effect =
          tester
                  .widget<Skeletonizer>(
                    find.byWidgetPredicate((w) => w is Skeletonizer),
                  )
                  .effect
              as ShimmerEffect;
      double onBlack(Color c) =>
          Color.alphaBlend(c, Colors.black).computeLuminance();
      expect(onBlack(effect.colors[1]), greaterThan(onBlack(effect.colors[0])));
      repository.reelsGate!.complete();
      await tester.pumpAndSettle();
      expect(title('r1'), findsOneWidget);
    });

    testWidgets('erro com "Tentar novamente" recarrega', (tester) async {
      repository.reelsResults[null] = const Left(ConnectionFailure());
      await pumpPage(tester);

      expect(find.text('Tentar novamente'), findsOneWidget);

      firstPage(2);
      await tester.tap(find.text('Tentar novamente'));
      await tester.pumpAndSettle();

      expect(title('r1'), findsOneWidget);
    });

    testWidgets('sem Reels: vazio com "Atualizar"', (tester) async {
      await pumpPage(tester);

      expect(find.text('Nenhuma notícia por aqui ainda.'), findsOneWidget);

      firstPage(1);
      await tester.tap(find.text('Atualizar'));
      await tester.pumpAndSettle();

      expect(title('r1'), findsOneWidget);
    });

    testWidgets('primeiro Reel: título, categorias, trecho, fonte e data', (
      tester,
    ) async {
      firstPage(2);
      await pumpPage(tester);

      expect(title('r1'), findsOneWidget);
      expect(find.text('Phishing'), findsOneWidget);
      expect(find.text('Texto do reel'), findsOneWidget);
      expect(find.textContaining('Folha de Teste'), findsOneWidget);
    });

    testWidgets('arrastar para cima vai ao próximo; para baixo, volta', (
      tester,
    ) async {
      firstPage(3);
      await pumpPage(tester);

      await tester.fling(find.byType(PageView), const Offset(0, -600), 2000);
      await tester.pumpAndSettle();
      expect(title('r2'), findsOneWidget);
      expect(controller.currentIndex, 1);

      await tester.fling(find.byType(PageView), const Offset(0, 600), 2000);
      await tester.pumpAndSettle();
      expect(title('r1'), findsOneWidget);
    });

    testWidgets('start abre no Reel pedido', (tester) async {
      firstPage(3);

      await pumpPage(tester, location: '/reels?start=r2', preload: false);
      await tester.pumpAndSettle();

      expect(title('r2'), findsOneWidget);
      expect(controller.currentIndex, 1);
    });

    // Erro visto no aparelho (setState durante o build): com os Reels já
    // abertos, tocar noutro Reel do carrossel muda o `start` e a página
    // abria o pedido no meio da construção.
    testWidgets('outro start com a página aberta abre sem erro', (
      tester,
    ) async {
      firstPage(3);
      final GoRouter routes = router(location: '/reels?start=r1');
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await pumpLocalized(
        tester,
        router: routes,
        providers: [
          ChangeNotifierProvider<ReelsController>.value(value: controller),
        ],
      );
      expect(title('r1'), findsOneWidget);

      routes.go('/reels?start=r3');
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(title('r3'), findsOneWidget);
      expect(controller.currentIndex, 2);
    });

    // specs/022 FR-019: a imagem do Reel tocado no carrossel já aparece
    // enquanto a lista carrega; só o texto fica em esqueleto.
    testWidgets('pelo carrossel: carregando já mostra a imagem tocada', (
      tester,
    ) async {
      const String url = 'https://img.test/r2.jpg';
      firstPage(3);
      repository.reelsGate = Completer<void>();

      await pumpPage(
        tester,
        location: '/reels?start=r2',
        extra: newsItem('r2', imageUrl: url),
        preload: false,
      );
      await tester.pump();

      final Finder image = find.byWidgetPredicate(
        (w) => w is SafeNetworkImage && w.url == url,
      );
      expect(
        find.byWidgetPredicate((w) => w is SafeSkeleton && w.enabled),
        findsOneWidget,
      );
      expect(image, findsOneWidget);
      expect(
        find.ancestor(
          of: image,
          matching: find.byWidgetPredicate((w) => w is Skeleton),
        ),
        findsOneWidget,
      );
      repository.reelsGate!.complete();
      await tester.pumpAndSettle();
      expect(title('r2'), findsOneWidget);
    });

    testWidgets('prévia de outra notícia é ignorada', (tester) async {
      firstPage(3);
      repository.reelsGate = Completer<void>();

      await pumpPage(
        tester,
        location: '/reels?start=r2',
        extra: newsItem('r9', imageUrl: 'https://img.test/r9.jpg'),
        preload: false,
      );
      await tester.pump();

      expect(find.byType(SafeNetworkImage), findsNothing);
      repository.reelsGate!.complete();
      await tester.pumpAndSettle();
    });

    testWidgets('tocar no texto abre o detalhe uma vez, com a prévia e as '
        'tags dos botões', (tester) async {
      firstPage(1);
      await pumpPage(tester);
      expect(find.text('Ler notícia completa'), findsNothing);

      final text = find.byKey(ReelView.readFullKey);
      await tester.tap(text);
      await tester.tap(text, warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.text('detalhe r1'), findsOneWidget);
      final preview = detailExtra! as NewsDetailPreview;
      expect(preview.item.id, 'r1');
      expect(preview.heroTag, isNull);
      expect(preview.actionTags, NewsActionsPreview.tagsFor('r1'));
      expect(preview.actions!.likesCount, controller.reels.first.likesCount);
      final navigator = tester.state<NavigatorState>(
        find.byType(Navigator).first,
      );
      navigator.pop();
      await tester.pumpAndSettle();
      expect(title('r1'), findsOneWidget);
    });

    testWidgets('um toque na imagem também abre o detalhe', (tester) async {
      firstPage(1);
      await pumpPage(tester);

      await tester.tap(find.byKey(ReelView.doubleTapKey));
      // Espera o tempo do segundo toque, que curtiria.
      await tester.pump(kDoubleTapTimeout);
      await tester.pumpAndSettle();

      expect(find.text('detalhe r1'), findsOneWidget);
      expect(repository.likeCalls, isEmpty);
    });

    testWidgets('o texto é um botão "Ler notícia completa" para o leitor de '
        'tela', (tester) async {
      final handle = tester.ensureSemantics();
      firstPage(1);
      await pumpPage(tester);

      expect(
        tester.getSemantics(find.byKey(ReelView.readFullKey)),
        isSemantics(
          isButton: true,
          hasTapAction: true,
          hint: 'Ler notícia completa',
        ),
      );
      expect(find.bySemanticsLabel(RegExp('Notícia r1')), findsOneWidget);
      handle.dispose();
    });

    testWidgets('último Reel com fim: "Você viu todas as notícias"', (
      tester,
    ) async {
      firstPage(1);
      await pumpPage(tester);

      expect(find.text('Você viu todas as notícias'), findsOneWidget);
    });

    testWidgets('falha da parte seguinte: aviso com "Tentar novamente"', (
      tester,
    ) async {
      firstPage(2, next: 'c2');
      repository.reelsResults['c2'] = const Left(ServerFailure());
      await pumpPage(tester);

      await tester.fling(find.byType(PageView), const Offset(0, -600), 2000);
      await tester.pumpAndSettle();

      expect(find.text('Não foi possível carregar mais.'), findsOneWidget);
      repository.reelsResults['c2'] = Right(
        ReelsPageEntity(items: reels(1, start: 3), nextCursor: null),
      );
      await tester.tap(find.text('Tentar novamente'));
      await tester.pumpAndSettle();
      expect(controller.reels, hasLength(3));
    });

    testWidgets('Reel sem imagem ou com imagem quebrada não quebra a tela', (
      tester,
    ) async {
      repository.reelsResults[null] = Right(
        ReelsPageEntity(
          items: [reel('r1', imageUrl: 'https://img.test/x.jpg')],
          nextCursor: null,
        ),
      );
      await pumpPage(tester);

      expect(title('r1'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('botões com 48×48 e rótulo', (tester) async {
      firstPage(2);
      await pumpPage(tester);

      for (final key in [
        ReelActions.likeKey,
        ReelActions.saveKey,
        ReelActions.shareKey,
      ]) {
        final size = tester.getSize(find.byKey(key));
        expect(size.width, greaterThanOrEqualTo(48), reason: '$key');
        expect(size.height, greaterThanOrEqualTo(48), reason: '$key');
      }
      // Só curtir, salvar e compartilhar ao lado.
      expect(find.bySemanticsLabel('Próxima notícia'), findsNothing);
      expect(find.bySemanticsLabel('Notícia anterior'), findsNothing);
      expect(find.bySemanticsLabel('Abrir fonte'), findsNothing);
    });
  });

  group('ouvir', () {
    Finder listen(String id) => find.byKey(ReelsPage.listenKeyFor(id));
    const String spokenR1 = 'Notícia r1.\n\nTexto do reel';

    Future<void> next(WidgetTester tester) async {
      await tester.fling(find.byType(PageView), const Offset(0, -600), 2000);
      await tester.pumpAndSettle();
    }

    testWidgets('"Ouvir" acima do título, longe dos botões laterais, 48 dp', (
      tester,
    ) async {
      firstPage(2);
      await pumpPage(tester);

      expect(listen('r1'), findsOneWidget);
      final Rect button = tester.getRect(listen('r1'));
      final Rect heading = tester.getRect(title('r1'));
      expect(button.bottom, lessThanOrEqualTo(heading.top));
      expect(button.left, closeTo(heading.left, 1));
      expect(button.height, greaterThanOrEqualTo(48));
      expect(
        button.right,
        lessThan(tester.getRect(find.byKey(ReelActions.likeKey)).left),
      );
    });

    testWidgets('lê título e resumo do Reel; de novo, para', (tester) async {
      firstPage(2);
      await pumpPage(tester);

      await tester.tap(listen('r1'));
      await tester.pump();
      expect(tts.spoken.single.text, spokenR1);
      expect(find.text('Parar'), findsOneWidget);

      await tester.tap(listen('r1'));
      await tester.pump();
      expect(tts.stopCalls, 1);
      expect(find.text('Parar'), findsNothing);
      // O toque no "Ouvir" não abre o detalhe.
      expect(find.text('detalhe r1'), findsNothing);
      await tester.pumpAndSettle();
    });

    testWidgets('trocar de Reel para a leitura; o novo não lê sozinho', (
      tester,
    ) async {
      firstPage(3);
      await pumpPage(tester);
      await tester.tap(listen('r1'));
      await tester.pump();

      await next(tester);

      expect(title('r2'), findsOneWidget);
      expect(tts.stopCalls, 1);
      expect(tts.spoken, hasLength(1));
      expect(find.text('Parar'), findsNothing);
    });

    testWidgets('leitura automática: lê o Reel na tela e o novo ao trocar', (
      tester,
    ) async {
      preferences.value = preferences.value.copyWith(autoReadAloud: true);
      firstPage(3);
      await pumpPage(tester);

      expect(tts.spoken.single.text, spokenR1);

      await next(tester);

      expect(tts.spoken.map((s) => s.text), [
        spokenR1,
        'Notícia r2.\n\nTexto do reel',
      ]);
      expect(find.text('Parar'), findsOneWidget);
    });

    testWidgets('abrir o detalhe para a leitura', (tester) async {
      firstPage(1);
      await pumpPage(tester);
      await tester.tap(listen('r1'));
      await tester.pump();

      await tester.tap(find.byKey(ReelView.readFullKey));
      await tester.pumpAndSettle();

      expect(find.text('detalhe r1'), findsOneWidget);
      expect(tts.stopCalls, greaterThanOrEqualTo(1));
    });

    testWidgets('sem voz no idioma: sem "Ouvir" e sem leitura automática', (
      tester,
    ) async {
      tts.availableLanguages = {};
      preferences.value = preferences.value.copyWith(autoReadAloud: true);
      firstPage(2);
      await pumpPage(tester);

      expect(title('r1'), findsOneWidget);
      expect(listen('r1'), findsNothing);
      expect(tts.spoken, isEmpty);
      expect(tester.takeException(), isNull);
    });
  });

  Future<void> signIn() => session.saveSession(
    accessToken: 'tk',
    refreshToken: 'rf',
    email: 'ana@test.com',
    userName: 'Ana',
  );

  void onePage(List<ReelEntity> items) => repository.reelsResults[null] = Right(
    ReelsPageEntity(items: items, nextCursor: null),
  );

  group('curtir', () {
    testWidgets('visitante: convite e nenhum pedido', (tester) async {
      onePage([reel('r1')]);
      await pumpPage(tester);

      await tapKey(tester, ReelActions.likeKey);

      expect(find.byType(AccountRequiredSheet), findsOneWidget);
      expect(repository.likeCalls, isEmpty);
      expect(controller.reels.first.isLiked, isFalse);
    });

    testWidgets('com conta: coração e contagem do servidor', (tester) async {
      await signIn();
      onePage([reel('r1', likesCount: 3)]);
      repository.likeResults.add(
        const Right(LikeResultEntity(liked: true, likesCount: 4)),
      );
      await pumpPage(tester);
      expect(find.bySemanticsLabel('Curtir, 3 curtidas'), findsOneWidget);

      await tapKey(tester, ReelActions.likeKey);

      expect(repository.likeCalls, ['r1']);
      expect(find.text('4'), findsOneWidget);
      expect(find.bySemanticsLabel('Curtido, 4 curtidas'), findsOneWidget);
    });

    testWidgets('falha: volta e mostra a mensagem', (tester) async {
      await signIn();
      onePage([reel('r1', likesCount: 3)]);
      repository.likeResults.add(const Left(ConnectionFailure()));
      await pumpPage(tester);

      await tapKey(tester, ReelActions.likeKey);

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(controller.reels.first.isLiked, isFalse);
    });

    group('microinterações (specs/022 FR-021)', () {
      final List<Object?> vibrations = [];

      setUp(() {
        vibrations.clear();
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, (call) async {
              if (call.method == 'HapticFeedback.vibrate') {
                vibrations.add(call.arguments);
              }
              return null;
            });
      });

      tearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, null),
      );

      Future<void> doubleTapImage(WidgetTester tester) async {
        final Finder image = find.byKey(ReelView.doubleTapKey);
        await tester.tap(image);
        await tester.pump(const Duration(milliseconds: 50));
        await tester.tap(image);
        await tester.pumpAndSettle();
      }

      double pulse(WidgetTester tester) => tester
          .widget<ScaleTransition>(find.byKey(ReelActions.likePulseKey))
          .scale
          .value;

      testWidgets('curtir pulsa o coração e vibra uma vez', (tester) async {
        await signIn();
        onePage([reel('r1', likesCount: 3)]);
        repository.likeResults.add(
          const Right(LikeResultEntity(liked: true, likesCount: 4)),
        );
        await pumpPage(tester);

        await tester.tap(find.byKey(ReelActions.likeKey));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        expect(pulse(tester), greaterThan(1));

        await tester.pumpAndSettle();
        expect(pulse(tester), 1);
        expect(vibrations, ['HapticFeedbackType.selectionClick']);
      });

      testWidgets('dois toques na imagem curtem; de novo, não descurtem', (
        tester,
      ) async {
        await signIn();
        onePage([reel('r1', likesCount: 3)]);
        repository.likeResults.add(
          const Right(LikeResultEntity(liked: true, likesCount: 4)),
        );
        await pumpPage(tester);

        await doubleTapImage(tester);
        expect(repository.likeCalls, ['r1']);
        expect(controller.reels.first.isLiked, isTrue);

        await doubleTapImage(tester);
        expect(repository.likeCalls, ['r1']);
        expect(controller.reels.first.isLiked, isTrue);
        expect(vibrations, hasLength(2));
      });

      testWidgets('visitante: dois toques mostram o convite', (tester) async {
        onePage([reel('r1')]);
        await pumpPage(tester);

        await doubleTapImage(tester);

        expect(find.byType(AccountRequiredSheet), findsOneWidget);
        expect(repository.likeCalls, isEmpty);
        expect(vibrations, isEmpty);
      });
    });
  });

  group('salvar', () {
    testWidgets('visitante: convite, sem pedido e marcador vazio', (
      tester,
    ) async {
      onePage([reel('r1', isSaved: true)]);
      await pumpPage(tester);
      expect(find.bySemanticsLabel('Salvar'), findsOneWidget);

      await tapKey(tester, ReelActions.saveKey);

      expect(find.byType(AccountRequiredSheet), findsOneWidget);
      expect(repository.saveCalls, isEmpty);
    });

    testWidgets('com conta: salvar e remover, com aviso', (tester) async {
      await signIn();
      onePage([reel('r1')]);
      repository.saveResults.addAll([const Right(true), const Right(false)]);
      await pumpPage(tester);

      await tapKey(tester, ReelActions.saveKey);
      expect(find.text('Notícia salva'), findsOneWidget);
      expect(find.bySemanticsLabel('Salvo'), findsOneWidget);

      await tapKey(tester, ReelActions.saveKey);
      expect(find.text('Removida dos salvos'), findsOneWidget);
      expect(find.bySemanticsLabel('Salvar'), findsOneWidget);
    });
  });

  group('compartilhar', () {
    testWidgets('visitante abre o menu com título, fonte e endereço', (
      tester,
    ) async {
      onePage([reel('r1')]);
      await pumpPage(tester);

      await tapKey(tester, ReelActions.shareKey);

      expect(share.shared.single.subject, 'Notícia r1');
      expect(share.shared.single.text, contains('https://fonte.test/r1'));
      expect(find.byType(AccountRequiredSheet), findsNothing);
    });

    testWidgets('toque duplo: um menu só', (tester) async {
      share.gate = Completer<void>();
      onePage([reel('r1')]);
      await pumpPage(tester);

      await tester.tap(find.byKey(ReelActions.shareKey));
      await tester.tap(find.byKey(ReelActions.shareKey));
      share.gate!.complete();
      await tester.pumpAndSettle();

      expect(share.shared, hasLength(1));
    });
  });
}
