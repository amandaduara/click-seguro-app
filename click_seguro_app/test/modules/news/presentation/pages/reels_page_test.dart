import 'dart:async';

import 'package:click_seguro_app/core/errors/errors.dart';
import 'package:click_seguro_app/core/widgets/safe_network_image.dart';
import 'package:click_seguro_app/core/widgets/safe_skeleton.dart';
import 'package:click_seguro_app/modules/common/services/external_launcher_service.dart';
import 'package:click_seguro_app/modules/common/services/user_session_service.dart';
import 'package:click_seguro_app/modules/news/domain/entities/reel_entity.dart';
import 'package:click_seguro_app/modules/news/domain/entities/reels_page_entity.dart';
import 'package:click_seguro_app/modules/news/presentation/controller/reels_controller.dart';
import 'package:click_seguro_app/modules/news/presentation/pages/reels_page.dart';
import 'package:click_seguro_app/modules/news/domain/entities/like_result_entity.dart';
import 'package:click_seguro_app/modules/news/presentation/widgets/reel_actions.dart';
import 'package:click_seguro_app/modules/news/presentation/widgets/reel_view.dart';
import 'package:click_seguro_app/modules/shell/presentation/widgets/account_required_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../../fakes/fake_external_launcher_service.dart';
import '../../../../fakes/fake_secure_storage_service.dart';
import '../../../../helpers/localized_app.dart';
import '../../fakes/fake_news_repository.dart';
import '../../fakes/reels_controller_factory.dart';

void main() {
  late UserSessionService session;
  late FakeNewsRepository repository;
  late FakeExternalLauncherService launcher;
  late ReelsController controller;

  setUp(() async {
    session = UserSessionService(FakeSecureStorageService());
    launcher = FakeExternalLauncherService();
    GetIt.instance
      ..registerSingleton<UserSessionService>(session)
      ..registerSingleton<ExternalLauncherService>(launcher);
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
        builder: (_, state) =>
            Scaffold(body: Text('detalhe ${state.pathParameters['id']}')),
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

    testWidgets('setas navegam; "anterior" não faz nada no primeiro', (
      tester,
    ) async {
      firstPage(2);
      await pumpPage(tester);

      await tapKey(tester, ReelActions.previousKey);
      expect(controller.currentIndex, 0);

      await tapKey(tester, ReelActions.nextKey);
      expect(title('r2'), findsOneWidget);
      expect(controller.currentIndex, 1);

      await tapKey(tester, ReelActions.previousKey);
      expect(title('r1'), findsOneWidget);
    });

    testWidgets('start abre no Reel pedido', (tester) async {
      firstPage(3);

      await pumpPage(tester, location: '/reels?start=r2', preload: false);
      await tester.pumpAndSettle();

      expect(title('r2'), findsOneWidget);
      expect(controller.currentIndex, 1);
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

    testWidgets('"Ler notícia completa" abre o detalhe uma vez', (
      tester,
    ) async {
      firstPage(1);
      await pumpPage(tester);

      final button = find.text('Ler notícia completa');
      await tester.tap(button);
      await tester.tap(button, warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.text('detalhe r1'), findsOneWidget);
      final navigator = tester.state<NavigatorState>(
        find.byType(Navigator).first,
      );
      navigator.pop();
      await tester.pumpAndSettle();
      expect(title('r1'), findsOneWidget);
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

      await tapKey(tester, ReelActions.nextKey);

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
        ReelActions.previousKey,
        ReelActions.nextKey,
        ReelActions.likeKey,
        ReelActions.saveKey,
        ReelActions.sourceKey,
      ]) {
        final size = tester.getSize(find.byKey(key));
        expect(size.width, greaterThanOrEqualTo(48), reason: '$key');
        expect(size.height, greaterThanOrEqualTo(48), reason: '$key');
      }
      expect(find.bySemanticsLabel('Próxima notícia'), findsOneWidget);
      expect(find.bySemanticsLabel('Notícia anterior'), findsOneWidget);
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

  group('abrir a fonte', () {
    testWidgets('visitante abre no navegador externo', (tester) async {
      onePage([reel('r1')]);
      await pumpPage(tester);

      await tapKey(tester, ReelActions.sourceKey);

      expect(launcher.openedUrls, ['https://fonte.test/r1']);
    });

    testWidgets('não abriu: aviso', (tester) async {
      launcher.openResult = false;
      onePage([reel('r1')]);
      await pumpPage(tester);

      await tapKey(tester, ReelActions.sourceKey);

      expect(find.text('Não foi possível abrir a fonte'), findsOneWidget);
    });

    testWidgets('sem endereço válido: botão ausente', (tester) async {
      onePage([reel('r1', sourceUrl: ''), reel('r2', sourceUrl: 'ftp://x')]);
      await pumpPage(tester);

      expect(find.byKey(ReelActions.sourceKey), findsNothing);
    });
  });
}
