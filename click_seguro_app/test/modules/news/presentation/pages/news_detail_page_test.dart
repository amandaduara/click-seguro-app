import 'dart:async';

import 'package:click_seguro_app/core/errors/errors.dart';
import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/theme/app_theme.dart';
import 'package:click_seguro_app/core/widgets/safe_error_state.dart';
import 'package:click_seguro_app/core/widgets/safe_offline_banner.dart';
import 'package:click_seguro_app/core/widgets/safe_skeleton.dart';
import 'package:click_seguro_app/modules/common/accessibility/accessibility_preferences_notifier.dart';
import 'package:click_seguro_app/modules/common/presentation/controller/read_aloud_controller.dart';
import 'package:click_seguro_app/modules/common/services/external_launcher_service.dart';
import 'package:click_seguro_app/modules/common/services/share_service.dart';
import 'package:click_seguro_app/modules/common/services/text_to_speech_service.dart';
import 'package:click_seguro_app/modules/common/services/user_session_service.dart';
import 'package:click_seguro_app/modules/news/domain/entities/news_detail_entity.dart';
import 'package:click_seguro_app/modules/news/domain/entities/news_item_entity.dart';
import 'package:click_seguro_app/modules/news/domain/failures/news_failures.dart';
import 'package:click_seguro_app/modules/news/presentation/controller/news_detail_controller.dart';
import 'package:click_seguro_app/modules/news/presentation/pages/news_detail_page.dart';
import 'package:click_seguro_app/modules/news/presentation/routes/news_detail_preview.dart';
import 'package:click_seguro_app/core/widgets/safe_icon_button.dart';
import 'package:click_seguro_app/modules/news/presentation/widgets/news_detail_actions.dart';
import 'package:click_seguro_app/modules/news/presentation/widgets/news_cover.dart';
import 'package:click_seguro_app/modules/news/presentation/widgets/news_detail_cover_bar.dart';
import 'package:click_seguro_app/modules/news/presentation/widgets/read_aloud_bar.dart';
import 'package:click_seguro_app/modules/news/presentation/widgets/related_activity_card.dart';
import 'package:click_seguro_app/modules/shell/presentation/widgets/account_required_sheet.dart';
import 'package:click_seguro_app/core/illustrations/app_illustration.dart';
import 'package:click_seguro_app/core/widgets/safe_illustration.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../../fakes/fake_external_launcher_service.dart';
import '../../../../fakes/fake_secure_storage_service.dart';
import '../../../../fakes/fake_share_service.dart';
import '../../../../fakes/fake_text_to_speech_service.dart';
import '../../../../helpers/localized_app.dart';
import '../../fakes/fake_news_repository.dart';
import '../../fakes/news_detail_controller_factory.dart';

class _GatedLauncherService extends FakeExternalLauncherService {
  Completer<void>? gate;

  @override
  Future<bool> openUrl(String url) async {
    final result = await super.openUrl(url);
    await gate?.future;
    return result;
  }
}

void main() {
  late UserSessionService session;
  late FakeShareService share;
  late _GatedLauncherService launcher;
  late FakeNewsRepository repository;
  late FakeTextToSpeechService tts;
  late AccessibilityPreferencesNotifier preferences;
  late GoRouter router;

  setUp(() async {
    session = UserSessionService(FakeSecureStorageService());
    tts = FakeTextToSpeechService();
    preferences = AccessibilityPreferencesNotifier();
    share = FakeShareService();
    launcher = _GatedLauncherService();
    GetIt.instance
      ..registerSingleton<UserSessionService>(session)
      ..registerSingleton<ShareService>(share)
      ..registerSingleton<ExternalLauncherService>(launcher)
      ..registerSingleton<AccessibilityPreferencesNotifier>(preferences)
      ..registerFactory<ReadAloudController>(
        () => ReadAloudController(tts, preferences: preferences),
      );
    await session.startGuestSession();
    repository = FakeNewsRepository();
  });

  tearDown(() async => GetIt.instance.reset());

  GoRouter buildRouter() => GoRouter(
    initialLocation: '/start',
    routes: [
      GoRoute(
        path: '/start',
        builder: (_, _) => const Scaffold(body: Text('tela anterior')),
      ),
      GoRoute(
        path: '/login',
        builder: (_, _) => const Scaffold(body: Text('login')),
      ),
      GoRoute(
        path: '/activities/:moduleId',
        builder: (_, state) =>
            Scaffold(body: Text('módulo ${state.pathParameters['moduleId']}')),
      ),
      GoRoute(
        path: '/news/:id',
        builder: (_, state) {
          final id = state.pathParameters['id']!;
          return ChangeNotifierProvider(
            create: (_) => buildNewsDetailController(
              repository,
              session.sessionStatus,
              newsId: id,
            )..load(),
            child: NewsDetailPage(
              newsId: id,
              preview: state.extra as NewsDetailPreview?,
            ),
          );
        },
      ),
    ],
  );

  /// Monta o app na tela anterior e abre `/news/n1` por cima, como as listas
  /// fazem. Com [settle] falso, não espera o carregando (que anima sem fim).
  Future<void> pumpPage(
    WidgetTester tester, {
    bool settle = true,
    Locale locale = const Locale('pt', 'BR'),
    Size size = const Size(800, 1600),
    ThemeData? theme,
    NewsDetailPreview? preview,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    router = buildRouter();
    await pumpLocalized(tester, router: router, locale: locale, theme: theme);
    unawaited(router.push<void>('/news/n1', extra: preview));
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
    }
  }

  NewsDetailController controllerOf(WidgetTester tester) =>
      tester.element(find.byType(NewsDetailPage)).read<NewsDetailController>();

  Finder backButton() => find.byKey(NewsDetailCoverBar.backKey);

  Future<void> signIn() => session.saveSession(
    accessToken: 'tk',
    refreshToken: 'rf',
    email: 'ana@test.com',
    userName: 'Ana',
  );

  group('leitura', () {
    testWidgets('carregando: sem barra com título, com o voltar redondo', (
      tester,
    ) async {
      repository.detailGate = Completer<void>();

      await pumpPage(tester, settle: false);

      expect(find.text('Notícia'), findsNothing);
      expect(backButton(), findsOneWidget);
      // Esqueleto da capa e do conteúdo, sem imagem.
      expect(find.byType(SafeSkeleton), findsNWidgets(2));
      expect(find.byType(NewsCover), findsNothing);
      // Sem detalhe ainda: sem curtir, compartilhar e salvar.
      expect(find.byKey(NewsDetailActions.likeKey), findsNothing);
      expect(find.byKey(NewsDetailActions.shareKey), findsNothing);
      repository.detailGate!.complete();
      await tester.pumpAndSettle();
    });

    group('prévia (specs/022 FR-017)', () {
      final preview = NewsDetailPreview(
        item: newsItem('n1', imageUrl: 'https://img.test/n.jpg'),
        heroTag: 'news-image-recent-n1',
      );

      Finder coverHero() => find.byWidgetPredicate(
        (w) => w is Hero && w.tag == 'news-image-recent-n1',
      );

      testWidgets('com a prévia: enquanto carrega, só o esqueleto no lugar '
          'da capa e do conteúdo, sem imagem; a capa (com o Hero de volta ao '
          'cartão) só com o detalhe', (tester) async {
        repository
          ..detailGate = Completer<void>()
          ..detailResults.add(
            Right(
              NewsDetailResult(
                detail: newsDetail('n1', imageUrl: 'https://img.test/n.jpg'),
                isFromCache: false,
              ),
            ),
          );

        await pumpPage(tester, settle: false, preview: preview);

        expect(find.byType(NewsCover), findsNothing);
        expect(coverHero(), findsNothing);
        expect(find.text('Notícia n1'), findsNothing);
        expect(find.text('Phishing'), findsNothing);
        expect(find.byType(SafeSkeleton), findsNWidgets(2));
        expect(backButton(), findsOneWidget);

        repository.detailGate!.complete();
        await tester.pumpAndSettle();
        expect(find.byType(NewsCover), findsOneWidget);
        expect(coverHero(), findsOneWidget);
        expect(find.text('Notícia n1'), findsOneWidget);
        expect(find.byType(SafeSkeleton), findsNothing);
        expect(find.text('Texto'), findsOneWidget);
      });

      testWidgets('sem a prévia: esqueleto completo, sem título', (
        tester,
      ) async {
        repository.detailGate = Completer<void>();

        await pumpPage(tester, settle: false);

        expect(find.byType(SafeSkeleton), findsNWidgets(2));
        expect(find.text('Notícia n1'), findsNothing);
        expect(find.byType(Hero), findsNothing);
        repository.detailGate!.complete();
        await tester.pumpAndSettle();
        expect(find.text('Notícia n1'), findsOneWidget);
      });

      testWidgets('falha com a prévia: o erro aparece abaixo do título', (
        tester,
      ) async {
        repository.detailResults.add(const Left(ConnectionFailure()));

        await pumpPage(tester, preview: preview);

        expect(find.text('Notícia n1'), findsOneWidget);
        expect(find.byType(SafeErrorState), findsOneWidget);
        expect(
          tester.getTopLeft(find.byType(SafeErrorState)).dy,
          greaterThan(tester.getTopLeft(find.text('Notícia n1')).dy),
        );
      });
    });

    group('aberto por um Reel', () {
      final reelPreview = NewsDetailPreview(
        item: newsItem('n1'),
        actions: const NewsActionsPreview(
          isLiked: true,
          likesCount: 7,
          isSaved: true,
        ),
      );
      final NewsActionTags tags = NewsActionsPreview.tagsFor('n1');

      Finder heroWith(String tag) =>
          find.byWidgetPredicate((w) => w is Hero && w.tag == tag);

      testWidgets('antes da carga: curtir, compartilhar e salvar já no topo, '
          'com o estado do Reel e as tags do Hero', (tester) async {
        await signIn();
        repository.detailGate = Completer<void>();

        await pumpPage(tester, settle: false, preview: reelPreview);

        expect(find.byKey(NewsDetailActions.likeKey), findsOneWidget);
        expect(find.byKey(NewsDetailActions.shareKey), findsOneWidget);
        expect(find.byKey(NewsDetailActions.saveKey), findsOneWidget);
        expect(find.byIcon(Icons.favorite), findsOneWidget);
        expect(find.byIcon(LucideIcons.bookmarkCheck), findsOneWidget);
        for (final String tag in [tags.like, tags.share, tags.save]) {
          expect(heroWith(tag), findsOneWidget, reason: tag);
        }
        // Sem detalhe, desativados: tocar não faz nada.
        expect(
          tester
              .widget<SafeIconButton>(find.byKey(NewsDetailActions.shareKey))
              .onPressed,
          isNull,
        );
        await tester.tap(find.byKey(NewsDetailActions.likeKey));
        await tester.tap(find.byKey(NewsDetailActions.shareKey));
        await tester.pump();
        expect(repository.likeCalls, isEmpty);
        expect(share.shared, isEmpty);

        repository.detailGate!.complete();
        await tester.pumpAndSettle();
        // Com o detalhe, o estado é o do serviço e os Hero continuam únicos.
        expect(find.byIcon(LucideIcons.heart), findsOneWidget);
        for (final String tag in [tags.like, tags.share, tags.save]) {
          expect(heroWith(tag), findsOneWidget, reason: tag);
        }
        expect(tester.takeException(), isNull);
      });

      testWidgets('visitante: coração e marcador vazios', (tester) async {
        repository.detailGate = Completer<void>();

        await pumpPage(tester, settle: false, preview: reelPreview);

        expect(find.byIcon(LucideIcons.heart), findsOneWidget);
        expect(find.byIcon(LucideIcons.bookmark), findsOneWidget);
        repository.detailGate!.complete();
        await tester.pumpAndSettle();
      });

      testWidgets('aberto por um cartão: botões sem Hero', (tester) async {
        await pumpPage(
          tester,
          preview: NewsDetailPreview(item: newsItem('n1')),
        );

        expect(find.byKey(NewsDetailActions.likeKey), findsOneWidget);
        expect(find.byType(Hero), findsNothing);
      });
    });

    testWidgets('carregando demorado: sem aviso de servidor lento', (
      tester,
    ) async {
      repository.detailGate = Completer<void>();
      await pumpPage(tester, settle: false);

      await tester.pump(const Duration(seconds: 10));

      expect(find.textContaining('Conectando ao servidor'), findsNothing);
      repository.detailGate!.complete();
      await tester.pumpAndSettle();
    });

    testWidgets('erro com "Tentar novamente" recarrega', (tester) async {
      repository.detailResults.add(const Left(ConnectionFailure()));
      await pumpPage(tester);

      expect(find.text('Tentar novamente'), findsOneWidget);

      repository.detailResults
        ..clear()
        ..add(
          Right(NewsDetailResult(detail: newsDetail('n1'), isFromCache: false)),
        );
      await tester.tap(find.text('Tentar novamente'));
      await tester.pumpAndSettle();

      expect(find.text('Notícia n1'), findsOneWidget);
      expect(find.text('Tentar novamente'), findsNothing);
    });

    testWidgets('não encontrada: mensagem e voltar, sem "Tentar novamente"', (
      tester,
    ) async {
      repository.detailResults.add(const Left(NewsNotFoundFailure()));
      await pumpPage(tester);

      expect(find.text('Notícia não encontrada'), findsOneWidget);
      expect(find.text('Tentar novamente'), findsNothing);
      expect(backButton(), findsOneWidget);
      expect(find.byKey(NewsDetailActions.likeKey), findsNothing);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is SafeIllustration &&
              widget.illustration == AppIllustration.stateEmpty,
        ),
        findsOneWidget,
      );
    });

    testWidgets('não encontrada: fonte 2× pode rolar em tela baixa', (
      tester,
    ) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      repository.detailResults.add(const Left(NewsNotFoundFailure()));
      await pumpPage(tester, size: const Size(360, 240));

      expect(find.text('Notícia não encontrada'), findsOneWidget);
      expect(find.text('Tentar novamente'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('Notícia não encontrada'));
      expect(tester.takeException(), isNull);
    });

    testWidgets('detalhe completo: imagem, categorias, título, fonte, data, '
        'tempo de leitura, curtidas e texto', (tester) async {
      repository.detailResults.add(
        Right(
          NewsDetailResult(
            detail: newsDetail(
              'n1',
              content: 'Texto completo da notícia',
              imageUrl: 'https://img.test/n.jpg',
            ),
            isFromCache: false,
          ),
        ),
      );

      await pumpPage(tester);

      expect(find.byType(Image), findsOneWidget);
      expect(find.text('Phishing'), findsOneWidget);
      expect(find.text('Notícia n1'), findsOneWidget);
      expect(
        find.text('Folha de Teste · 20 de set. · 1 min de leitura'),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(NewsDetailActions.likeKey),
          matching: find.text('2'),
        ),
        findsOneWidget,
      );
      expect(find.text('Texto completo da notícia'), findsOneWidget);
      expect(find.byType(SafeOfflineBanner), findsNothing);
    });

    testWidgets('texto longo rola', (tester) async {
      repository.detailResults.add(
        Right(
          NewsDetailResult(
            detail: newsDetail('n1', content: 'Parágrafo. ' * 600),
            isFromCache: false,
          ),
        ),
      );
      await pumpPage(tester);

      final ScrollableState scroll = tester.state(find.byType(Scrollable));
      expect(scroll.position.maxScrollExtent, greaterThan(0));
    });

    testWidgets('sem imagem não quebra e não sobra espaço', (tester) async {
      await pumpPage(tester);

      expect(find.byType(Image), findsNothing);
      expect(find.text('Notícia n1'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('texto vazio mostra o aviso', (tester) async {
      repository.detailResults.add(
        Right(
          NewsDetailResult(
            detail: newsDetail('n1', content: ' '),
            isFromCache: false,
          ),
        ),
      );

      await pumpPage(tester);

      expect(
        find.text('O texto completo desta notícia não está disponível.'),
        findsOneWidget,
      );
    });

    testWidgets('cópia do aparelho mostra o aviso de offline', (tester) async {
      repository.detailResults.add(
        Right(NewsDetailResult(detail: newsDetail('n1'), isFromCache: true)),
      );

      await pumpPage(tester);

      expect(find.byType(SafeOfflineBanner), findsOneWidget);
      expect(find.text('Notícia n1'), findsOneWidget);
    });

    testWidgets('voltar mantém a tela anterior', (tester) async {
      await pumpPage(tester);

      await tester.tap(backButton());
      await tester.pumpAndSettle();

      expect(find.text('tela anterior'), findsOneWidget);
      expect(find.text('Notícia n1'), findsNothing);
    });
  });

  group('ouvir', () {
    const spokenN1 = 'Notícia n1.\n\nTexto';

    // O botão redondo de tocar não tem texto: tocar ou parar pelo ícone.
    Finder listen() => find.byKey(ReadAloudBar.listenKey);
    Finder playIcon() => find.byIcon(LucideIcons.play);
    Finder stopIcon() => find.byIcon(LucideIcons.square);

    testWidgets('com voz: "Ouvir" e a velocidade guardada no cartão', (
      tester,
    ) async {
      preferences.value = preferences.value.copyWith(
        readingSpeed: ReadingSpeed.fast,
      );

      await pumpPage(tester);

      expect(playIcon(), findsOneWidget);
      expect(find.text('Velocidade: rápida'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(ReadAloudBar.speedKey),
          matching: find.text('2x'),
        ),
        findsOneWidget,
      );
      // A pílula fica dentro do cartão "Ouvir notícia", na mesma linha.
      final listen = tester.getRect(find.byKey(ReadAloudBar.listenKey));
      final speed = tester.getRect(find.byKey(ReadAloudBar.speedKey));
      expect(speed.center.dy, closeTo(listen.center.dy, 1));
      expect(find.text('lenta'), findsNothing);
      expect(tts.spoken, isEmpty);
    });

    testWidgets('a pílula alterna 1x, 2x, 0,5x e volta a 1x', (tester) async {
      await pumpPage(tester);
      Finder pill(String text) => find.descendant(
        of: find.byKey(ReadAloudBar.speedKey),
        matching: find.text(text),
      );

      expect(pill('1x'), findsOneWidget);
      expect(find.text('Velocidade: normal'), findsOneWidget);
      for (final (label, name) in [
        ('2x', 'rápida'),
        ('0,5x', 'lenta'),
        ('1x', 'normal'),
      ]) {
        await tester.tap(find.byKey(ReadAloudBar.speedKey));
        await tester.pump();
        expect(pill(label), findsOneWidget);
        expect(find.text('Velocidade: $name'), findsOneWidget);
      }
    });

    testWidgets('"Ouvir" lê título e texto e vira "Parar"', (tester) async {
      await pumpPage(tester);

      await tester.tap(listen());
      await tester.pump();

      expect(tts.spoken.single, (
        text: spokenN1,
        language: SpeechLanguage.ptBr,
        speed: ReadingSpeed.normal,
      ));
      expect(stopIcon(), findsOneWidget);
      expect(playIcon(), findsNothing);
    });

    testWidgets('"Parar" para a voz e volta a "Ouvir"', (tester) async {
      await pumpPage(tester);
      await tester.tap(listen());
      await tester.pump();

      await tester.tap(listen());
      await tester.pump();

      expect(tts.stopCalls, 1);
      expect(playIcon(), findsOneWidget);
    });

    testWidgets('trocar a velocidade vale para a próxima leitura e não muda '
        'a preferência', (tester) async {
      await pumpPage(tester);

      await tester.tap(find.byKey(ReadAloudBar.speedKey));
      await tester.pump();
      expect(find.text('Velocidade: rápida'), findsOneWidget);
      await tester.tap(listen());
      await tester.pump();

      expect(tts.spoken.single.speed, ReadingSpeed.fast);
      expect(preferences.value.readingSpeed, ReadingSpeed.normal);
    });

    testWidgets('texto vazio: lê só o título', (tester) async {
      repository.detailResults.add(
        Right(
          NewsDetailResult(
            detail: newsDetail('n1', content: ''),
            isFromCache: false,
          ),
        ),
      );
      await pumpPage(tester);

      await tester.tap(listen());
      await tester.pump();

      expect(tts.spoken.single.text, 'Notícia n1');
    });

    testWidgets('leitura automática começa sozinha, uma vez só', (
      tester,
    ) async {
      preferences.value = preferences.value.copyWith(autoReadAloud: true);

      await pumpPage(tester);

      expect(tts.spoken.single.text, spokenN1);
      expect(stopIcon(), findsOneWidget);

      tts.finishSpeaking();
      await tester.pump();
      await controllerOf(tester).retry();
      await tester.pumpAndSettle();

      expect(tts.spoken, hasLength(1));
    });

    testWidgets('"Parar" logo depois da leitura automática não recomeça', (
      tester,
    ) async {
      preferences.value = preferences.value.copyWith(autoReadAloud: true);
      await pumpPage(tester);

      await tester.tap(listen());
      await tester.pump();
      await controllerOf(tester).retry();
      await tester.pumpAndSettle();

      expect(tts.spoken, hasLength(1));
      expect(playIcon(), findsOneWidget);
    });

    testWidgets('sem voz: sem "Ouvir", sem velocidade, sem leitura '
        'automática e sem erro', (tester) async {
      tts.availableLanguages = {};
      preferences.value = preferences.value.copyWith(autoReadAloud: true);

      await pumpPage(tester);

      expect(listen(), findsNothing);
      expect(find.byType(ReadAloudBar), findsOneWidget);
      expect(find.textContaining('Velocidade'), findsNothing);
      expect(tts.spoken, isEmpty);
      expect(find.text('Notícia n1'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('app em inglês: voz em inglês', (tester) async {
      await pumpPage(tester, locale: const Locale('en', 'US'));

      await tester.tap(listen());
      await tester.pump();

      expect(tts.spoken.single.language, SpeechLanguage.enUs);
      expect(tts.spoken.single.text, spokenN1);
    });

    testWidgets('sair da tela para a voz', (tester) async {
      await pumpPage(tester);
      await tester.tap(listen());
      await tester.pump();

      await tester.tap(backButton());
      await tester.pumpAndSettle();

      expect(tts.stopCalls, greaterThanOrEqualTo(1));
    });

    testWidgets('rótulos de acessibilidade e botões de 48 dp', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpPage(tester);

      expect(find.bySemanticsLabel('Ouvir'), findsOneWidget);
      expect(
        tester.getSemantics(find.byKey(ReadAloudBar.speedKey)),
        isSemantics(
          label: 'Velocidade: normal, 1x',
          hint: 'Toque para mudar a velocidade',
          isButton: true,
          hasTapAction: true,
        ),
      );
      final listenSize = tester.getSize(listen());
      expect(listenSize.height, greaterThanOrEqualTo(48));
      expect(listenSize.width, greaterThanOrEqualTo(48));
      final speedSize = tester.getSize(find.byKey(ReadAloudBar.speedKey));
      expect(speedSize.width, greaterThanOrEqualTo(48));
      expect(speedSize.height, greaterThanOrEqualTo(48));

      await tester.tap(listen());
      await tester.pump();
      expect(find.bySemanticsLabel('Parar'), findsOneWidget);
      handle.dispose();
    });
  });

  group('salvar', () {
    /// "Salvar" ou "Salvo": o rótulo do botão redondo sobre a capa.
    String saveLabel(WidgetTester tester) => tester
        .widget<SafeIconButton>(find.byKey(NewsDetailActions.saveKey))
        .semanticLabel;

    void detailSaved({required bool isSaved}) => repository.detailResults.add(
      Right(
        NewsDetailResult(
          detail: newsDetail('n1', isSaved: isSaved),
          isFromCache: false,
        ),
      ),
    );

    Future<void> tapSave(WidgetTester tester) async {
      await tester.tap(find.byKey(NewsDetailActions.saveKey));
      await tester.pumpAndSettle();
    }

    testWidgets('visitante: convite, sem pedido e marcador vazio mesmo com '
        'isSaved no JSON', (tester) async {
      detailSaved(isSaved: true);
      await pumpPage(tester);
      expect(saveLabel(tester), 'Salvar');
      expect(find.byIcon(LucideIcons.bookmark), findsOneWidget);

      await tapSave(tester);

      expect(find.byType(AccountRequiredSheet), findsOneWidget);
      expect(repository.saveCalls, isEmpty);
      expect(find.byIcon(LucideIcons.bookmarkCheck), findsNothing);
    });

    testWidgets('com conta: o marcador reflete o isSaved do serviço', (
      tester,
    ) async {
      await signIn();
      detailSaved(isSaved: true);

      await pumpPage(tester);

      expect(saveLabel(tester), 'Salvo');
      expect(find.byIcon(LucideIcons.bookmarkCheck), findsOneWidget);
    });

    testWidgets('com conta: alterna na hora e avisa "salva" e "removida"', (
      tester,
    ) async {
      await signIn();
      detailSaved(isSaved: false);
      repository.saveResults.addAll([const Right(true), const Right(false)]);
      await pumpPage(tester);
      repository.saveGate = Completer<void>();

      await tester.tap(find.byKey(NewsDetailActions.saveKey));
      await tester.pump();
      await tester.pump();

      expect(find.byType(SnackBar), findsNothing);

      repository.saveGate!.complete();
      await tester.pumpAndSettle();

      expect(find.text('Notícia salva'), findsOneWidget);
      expect(saveLabel(tester), 'Salvo');

      repository.saveGate = null;
      await tapSave(tester);

      expect(find.text('Removida dos salvos'), findsOneWidget);
      expect(saveLabel(tester), 'Salvar');
      expect(repository.saveCalls, ['n1', 'n1']);
    });

    testWidgets('em andamento: carregando no lugar do marcador, botão '
        'desativado e "carregando" para o leitor de tela', (tester) async {
      final handle = tester.ensureSemantics();
      await signIn();
      await pumpPage(tester);
      repository.saveGate = Completer<void>();

      await tester.tap(find.byKey(NewsDetailActions.saveKey));
      await tester.pump();

      final Finder save = find.byKey(NewsDetailActions.saveKey);
      expect(
        find.descendant(
          of: save,
          matching: find.byKey(NewsDetailActions.loadingKey),
        ),
        findsOneWidget,
      );
      expect(find.byType(SafeIconButton), findsNWidgets(2)); // voltar e
      // compartilhar: o salvar não é mais o botão comum.
      expect(
        tester.getSemantics(save),
        matchesSemantics(
          label: 'Salvar: carregando, aguarde',
          isButton: true,
          hasEnabledState: true,
          isLiveRegion: true,
        ),
      );
      expect(tester.getSize(save).width, greaterThanOrEqualTo(48));

      // Novo toque durante o pedido: nenhum pedido a mais.
      await tester.tap(save);
      await tester.pump();
      expect(repository.saveCalls, ['n1']);

      repository.saveGate!.complete();
      await tester.pumpAndSettle();
      expect(find.byKey(NewsDetailActions.loadingKey), findsNothing);
      expect(saveLabel(tester), 'Salvo');
      handle.dispose();
    });

    testWidgets('falha: o marcador volta e o aviso mostra o erro', (
      tester,
    ) async {
      await signIn();
      repository.saveResults.add(const Left(ConnectionFailure()));
      await pumpPage(tester);

      await tapSave(tester);

      expect(
        find.text('Sem conexão com a internet. Verifique sua rede.'),
        findsOneWidget,
      );
      expect(saveLabel(tester), 'Salvar');
    });

    testWidgets('404 ao salvar mostra "Notícia não encontrada"', (
      tester,
    ) async {
      await signIn();
      repository.saveResults.add(const Left(NewsNotFoundFailure()));
      await pumpPage(tester);

      await tapSave(tester);

      expect(find.text('Notícia não encontrada'), findsOneWidget);
      expect(find.byKey(NewsDetailActions.saveKey), findsNothing);
    });

    testWidgets('visitante que entra na conta com a tela aberta: detalhe '
        'recarregado com o estado de salvo', (tester) async {
      repository.detailResults
        ..add(
          Right(NewsDetailResult(detail: newsDetail('n1'), isFromCache: false)),
        )
        ..add(
          Right(
            NewsDetailResult(
              detail: newsDetail('n1', isSaved: true),
              isFromCache: false,
            ),
          ),
        );
      await pumpPage(tester);
      expect(saveLabel(tester), 'Salvar');

      await signIn();
      await tester.pumpAndSettle();

      expect(repository.detailCalls, ['n1', 'n1']);
      expect(saveLabel(tester), 'Salvo');
    });

    testWidgets('rótulos "Salvar"/"Salvo" e área de 48 dp', (tester) async {
      final handle = tester.ensureSemantics();
      await signIn();
      await pumpPage(tester);

      expect(find.bySemanticsLabel('Salvar'), findsOneWidget);
      final size = tester.getSize(find.byKey(NewsDetailActions.saveKey));
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));

      await tapSave(tester);
      expect(find.bySemanticsLabel('Salvo'), findsOneWidget);
      handle.dispose();
    });
  });

  group('curtir', () {
    Finder likeButton() => find.byKey(NewsDetailActions.likeKey);
    Finder likeText(String count) =>
        find.descendant(of: likeButton(), matching: find.text(count));

    testWidgets('visitante: convite, sem pedido e coração vazio mesmo com '
        'isLiked no JSON', (tester) async {
      repository.detailResults.add(
        Right(
          NewsDetailResult(
            detail: newsDetail('n1', isLiked: true),
            isFromCache: false,
          ),
        ),
      );
      await pumpPage(tester);
      expect(find.byIcon(LucideIcons.heart), findsOneWidget);

      await tester.tap(likeButton());
      await tester.pumpAndSettle();

      expect(find.byType(AccountRequiredSheet), findsOneWidget);
      expect(repository.likeCalls, isEmpty);
      expect(likeText('2'), findsOneWidget);
    });

    testWidgets('com conta: +1 na hora e depois o número do serviço', (
      tester,
    ) async {
      await signIn();
      await pumpPage(tester);
      repository.likeGate = Completer<void>();

      await tester.tap(likeButton());
      await tester.pump();
      await tester.pump();

      expect(likeText('3'), findsOneWidget);

      repository.likeGate!.complete();
      await tester.pumpAndSettle();

      expect(likeText('4'), findsOneWidget);
      expect(find.byIcon(Icons.favorite), findsOneWidget);
      expect(repository.likeCalls, ['n1']);
    });

    testWidgets('em andamento: carregando no lugar do coração, botão '
        'desativado e "carregando" para o leitor de tela', (tester) async {
      final handle = tester.ensureSemantics();
      await signIn();
      await pumpPage(tester);
      repository.likeGate = Completer<void>();

      await tester.tap(likeButton());
      await tester.pump();

      expect(
        find.descendant(
          of: likeButton(),
          matching: find.byKey(NewsDetailActions.loadingKey),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(of: likeButton(), matching: find.byType(Icon)),
        findsNothing,
      );
      expect(
        tester.getSemantics(likeButton()),
        matchesSemantics(
          label: 'Curtir: carregando, aguarde',
          isButton: true,
          hasEnabledState: true,
          isLiveRegion: true,
        ),
      );

      await tester.tap(likeButton());
      await tester.pump();
      expect(repository.likeCalls, ['n1']);

      repository.likeGate!.complete();
      await tester.pumpAndSettle();
      expect(find.byKey(NewsDetailActions.loadingKey), findsNothing);
      expect(find.bySemanticsLabel('Curtido, 4 curtidas'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('falha: volta a contagem e avisa', (tester) async {
      await signIn();
      repository.likeResults.add(const Left(ConnectionFailure()));
      await pumpPage(tester);

      await tester.tap(likeButton());
      await tester.pumpAndSettle();

      expect(
        find.text('Sem conexão com a internet. Verifique sua rede.'),
        findsOneWidget,
      );
      expect(likeText('2'), findsOneWidget);
      expect(find.byIcon(LucideIcons.heart), findsOneWidget);
    });

    testWidgets('rótulo "Curtir, 2 curtidas" e área de 48 dp', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpPage(tester);

      expect(find.bySemanticsLabel('Curtir, 2 curtidas'), findsOneWidget);
      final size = tester.getSize(likeButton());
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));
      handle.dispose();
    });
  });

  group('compartilhar e fonte', () {
    Finder shareButton() => find.byKey(NewsDetailActions.shareKey);
    Finder sourceButton() => find.byKey(NewsDetailPage.sourceKey);

    testWidgets('"Compartilhar" abre o menu com texto e título', (
      tester,
    ) async {
      await pumpPage(tester);

      await tester.tap(shareButton());
      await tester.pumpAndSettle();

      expect(share.shared, [
        (
          text: 'Notícia n1\nFolha de Teste\nhttps://fonte.test/n',
          subject: 'Notícia n1',
        ),
      ]);
    });

    for (final outcome in [ShareOutcome.cancelled, ShareOutcome.failed]) {
      testWidgets('$outcome: volta ao detalhe sem aviso', (tester) async {
        share.outcome = outcome;
        await pumpPage(tester);

        await tester.tap(shareButton());
        await tester.pumpAndSettle();

        expect(find.byType(SnackBar), findsNothing);
        expect(find.text('Notícia n1'), findsOneWidget);
      });
    }

    testWidgets('"Abrir fonte" abre o endereço, também para visitante', (
      tester,
    ) async {
      await pumpPage(tester);

      await tester.tap(sourceButton());
      await tester.pumpAndSettle();

      expect(launcher.openedUrls, ['https://fonte.test/n']);
      expect(find.byType(AccountRequiredSheet), findsNothing);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('não abriu: aviso e continua no detalhe', (tester) async {
      launcher.openResult = false;
      await pumpPage(tester);

      await tester.tap(sourceButton());
      await tester.pumpAndSettle();

      expect(find.text('Não foi possível abrir a fonte'), findsOneWidget);
      expect(find.text('Notícia n1'), findsOneWidget);
    });

    testWidgets('sem endereço válido: sem "Abrir fonte", com "Compartilhar"', (
      tester,
    ) async {
      repository.detailResults.add(
        Right(
          NewsDetailResult(
            detail: newsDetail('n1', sourceUrl: ''),
            isFromCache: false,
          ),
        ),
      );

      await pumpPage(tester);

      expect(find.text('Abrir fonte'), findsNothing);
      expect(sourceButton(), findsNothing);
      expect(shareButton(), findsOneWidget);
    });

    testWidgets('texto vazio mantém "Abrir fonte"', (tester) async {
      repository.detailResults.add(
        Right(
          NewsDetailResult(
            detail: newsDetail('n1', content: ' '),
            isFromCache: false,
          ),
        ),
      );

      await pumpPage(tester);

      expect(find.text('Abrir fonte'), findsOneWidget);
    });

    testWidgets('toque duplo em "Compartilhar": um menu só', (tester) async {
      share.gate = Completer<void>();
      await pumpPage(tester);

      await tester.tap(shareButton());
      await tester.tap(shareButton());
      await tester.pump();

      expect(share.shared, hasLength(1));
      share.gate!.complete();
      await tester.pumpAndSettle();

      await tester.tap(shareButton());
      await tester.pumpAndSettle();
      expect(share.shared, hasLength(2));
    });

    testWidgets('toque duplo em "Abrir fonte": uma abertura só', (
      tester,
    ) async {
      launcher.gate = Completer<void>();
      await pumpPage(tester);

      await tester.tap(sourceButton());
      await tester.tap(sourceButton());
      await tester.pump();

      expect(launcher.openedUrls, hasLength(1));
      launcher.gate!.complete();
      await tester.pumpAndSettle();
    });

    // Sem perder a ação no leitor de tela (excludeSemantics sem onTap).
    testWidgets('"Abrir fonte" pelo leitor de tela: botão com toque', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpPage(tester);

      expect(
        tester.getSemantics(sourceButton()),
        isSemantics(label: 'Abrir fonte', isButton: true, hasTapAction: true),
      );
      tester.semantics.tap(find.semantics.byLabel('Abrir fonte'));
      await tester.pumpAndSettle();

      expect(launcher.openedUrls, ['https://fonte.test/n']);
      handle.dispose();
    });

    testWidgets('rótulos e botões de 48 dp', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpPage(tester);

      expect(find.bySemanticsLabel('Compartilhar'), findsOneWidget);
      expect(find.bySemanticsLabel('Abrir fonte'), findsOneWidget);
      expect(find.byIcon(LucideIcons.share2), findsOneWidget);
      expect(find.byIcon(LucideIcons.externalLink), findsOneWidget);
      for (final key in [
        NewsDetailActions.shareKey,
        NewsDetailPage.sourceKey,
      ]) {
        final size = tester.getSize(find.byKey(key));
        expect(size.width, greaterThanOrEqualTo(48));
        expect(size.height, greaterThanOrEqualTo(48));
      }
      handle.dispose();
    });
  });

  group('atividade relacionada', () {
    const module = SuggestedModuleEntity(
      id: 'm1',
      title: 'Golpes no WhatsApp',
      description: 'Aprenda a reconhecer golpes.',
      lessonsCount: 3,
    );

    void detailWith({SuggestedModuleEntity? suggested = module}) =>
        repository.detailResults.add(
          Right(
            NewsDetailResult(
              detail: newsDetail('n1', suggestedModule: suggested),
              isFromCache: false,
            ),
          ),
        );

    Finder card() => find.byKey(RelatedActivityCard.cardKey);

    testWidgets('visitante vê o bloco depois do texto', (tester) async {
      detailWith();

      await pumpPage(tester);

      expect(find.text('Pratique o que aprendeu'), findsOneWidget);
      expect(find.text('Golpes no WhatsApp'), findsOneWidget);
      expect(find.text('Aprenda a reconhecer golpes.'), findsOneWidget);
      expect(find.text('3 perguntas'), findsOneWidget);
      expect(
        tester.getTopLeft(card()).dy,
        greaterThan(tester.getBottomLeft(find.text('Texto')).dy),
      );
    });

    testWidgets('com conta também vê o bloco', (tester) async {
      await session.saveSession(
        accessToken: 'tk',
        refreshToken: 'rf',
        email: 'ana@test.com',
        userName: 'Ana',
      );
      detailWith();

      await pumpPage(tester);

      expect(card(), findsOneWidget);
    });

    testWidgets('tocar abre /activities/m1 e ao voltar o detalhe segue igual', (
      tester,
    ) async {
      detailWith();
      await pumpPage(tester);

      await tester.tap(card());
      await tester.pumpAndSettle();

      expect(find.text('módulo m1'), findsOneWidget);

      router.pop();
      await tester.pumpAndSettle();

      expect(find.text('Notícia n1'), findsOneWidget);
      expect(card(), findsOneWidget);
      expect(repository.detailCalls, ['n1']);
    });

    testWidgets('toque duplo: uma navegação só', (tester) async {
      detailWith();
      await pumpPage(tester);

      await tester.tap(card());
      await tester.tap(card());
      await tester.pumpAndSettle();
      router.pop();
      await tester.pumpAndSettle();

      expect(find.text('Notícia n1'), findsOneWidget);
      expect(find.text('módulo m1'), findsNothing);
    });

    testWidgets('no fim, o bloco fica acima da barra de navegação do '
        'aparelho, com respiro', (tester) async {
      repository.detailResults.add(
        Right(
          NewsDetailResult(
            detail: newsDetail(
              'n1',
              content: List<String>.filled(600, 'palavra').join(' '),
              suggestedModule: const SuggestedModuleEntity(
                id: 'm1',
                title: 'Golpes no WhatsApp',
                description: 'Aprenda a reconhecer',
                lessonsCount: 3,
              ),
            ),
            isFromCache: false,
          ),
        ),
      );
      // Barra de navegação do Android de 48 dp sobre a tela.
      tester.view.padding = const FakeViewPadding(bottom: 48);
      await pumpPage(tester, size: const Size(400, 800));

      await tester.drag(find.byType(CustomScrollView), const Offset(0, -20000));
      await tester.pumpAndSettle();

      final double cardBottom = tester
          .getBottomLeft(find.byType(RelatedActivityCard))
          .dy;
      expect(800 - cardBottom, moreOrLessEquals(48 + 24));
    });

    testWidgets('sem módulo sugerido: sem bloco', (tester) async {
      detailWith(suggested: null);

      await pumpPage(tester);

      expect(card(), findsNothing);
      expect(find.text('Pratique o que aprendeu'), findsNothing);
      expect(find.byKey(NewsDetailActions.likeKey), findsOneWidget);
    });

    testWidgets('sem barra fixa embaixo: a atividade só no bloco do texto', (
      tester,
    ) async {
      detailWith();
      await pumpPage(tester);

      expect(find.text('Praticar com quiz'), findsNothing);
      final Scaffold scaffold = tester.widget<Scaffold>(
        find
            .ancestor(
              of: find.byType(CustomScrollView),
              matching: find.byType(Scaffold),
            )
            .first,
      );
      expect(scaffold.bottomNavigationBar, isNull);
    });

    testWidgets('descrição vazia não deixa buraco', (tester) async {
      detailWith(
        suggested: const SuggestedModuleEntity(
          id: 'm1',
          title: 'Golpes no WhatsApp',
          description: '',
          lessonsCount: 3,
        ),
      );

      await pumpPage(tester);

      expect(card(), findsOneWidget);
      expect(find.byKey(RelatedActivityCard.descriptionKey), findsNothing);
    });

    testWidgets('rótulo e área de 48 dp', (tester) async {
      final handle = tester.ensureSemantics();
      detailWith();
      await pumpPage(tester);

      expect(
        find.bySemanticsLabel(RegExp('Pratique o que aprendeu, Golpes')),
        findsOneWidget,
      );
      final size = tester.getSize(card());
      expect(size.height, greaterThanOrEqualTo(48));
      handle.dispose();
    });
  });

  group('acessibilidade (FR-022, SC-008)', () {
    const module = SuggestedModuleEntity(
      id: 'm1',
      title: 'Golpes no WhatsApp',
      description: 'Aprenda a reconhecer golpes.',
      lessonsCount: 3,
    );
    const longTitle =
        'Golpistas usam falsas centrais de atendimento para roubar dados '
        'de aposentados em todo o país';
    final longContent = List.filled(
      6,
      'Texto completo da notícia, com várias frases para quebrar de linha.',
    ).join(' ');

    void fullDetail() => repository.detailResults.add(
      Right(
        NewsDetailResult(
          detail: newsDetail(
            'n1',
            content: longContent,
            suggestedModule: module,
          ),
          isFromCache: false,
        ),
      ),
    );

    NewsDetailEntity withTitle(NewsDetailEntity detail, String title) {
      final news = detail.news;
      return NewsDetailEntity(
        news: NewsItemEntity(
          id: news.id,
          title: title,
          source: news.source,
          sourceUrl: news.sourceUrl,
          originalPublishedAt: news.originalPublishedAt,
          categories: news.categories,
          interaction: news.interaction,
        ),
        content: detail.content,
        likesCount: detail.likesCount,
        readsCount: detail.readsCount,
        suggestedModule: detail.suggestedModule,
      );
    }

    final interactive = <Finder>[
      find.byKey(NewsDetailCoverBar.backKey),
      find.byKey(NewsDetailActions.shareKey),
      find.byKey(NewsDetailActions.saveKey),
      find.byKey(NewsDetailPage.sourceKey),
      find.byKey(ReadAloudBar.listenKey),
      find.byKey(ReadAloudBar.speedKey),
      find.byKey(RelatedActivityCard.cardKey),
      find.byKey(NewsDetailActions.likeKey),
    ];

    /// Todo controle com pelo menos 48×48 dp, visível na tela.
    void expectTouchTargets(WidgetTester tester) {
      for (final finder in interactive) {
        expect(finder, findsOneWidget);
        final size = tester.getSize(finder);
        expect(size.width, greaterThanOrEqualTo(48), reason: '$finder');
        expect(size.height, greaterThanOrEqualTo(48), reason: '$finder');
      }
    }

    /// Topo, na tela, do nó de acessibilidade com o rótulo.
    testWidgets('padrão: todos os controles com 48×48 dp ou mais', (
      tester,
    ) async {
      await signIn();
      fullDetail();
      await pumpPage(tester);

      expectTouchTargets(tester);
      expect(tester.takeException(), isNull);
    });

    testWidgets('fonte 2×: sem sobreposição, sem estourar a largura e texto '
        'quebrando de linha', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2.0;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await signIn();
      repository.detailResults.add(
        Right(
          NewsDetailResult(
            detail: withTitle(
              newsDetail('n1', content: longContent, suggestedModule: module),
              longTitle,
            ),
            isFromCache: false,
          ),
        ),
      );
      await pumpPage(tester, size: const Size(360, 800));

      final context = tester.element(find.byType(NewsDetailPage));
      expect(MediaQuery.textScalerOf(context).scale(10), 20);
      expect(tester.takeException(), isNull);
      expectTouchTargets(tester);
      // O título quebra em várias linhas.
      expect(tester.getSize(find.text(longTitle)).height, greaterThan(100));
      // Botões sobre a capa: lado a lado, sem tocar, dentro da tela.
      final back = tester.getRect(find.byKey(NewsDetailCoverBar.backKey));
      final like = tester.getRect(find.byKey(NewsDetailActions.likeKey));
      final share = tester.getRect(find.byKey(NewsDetailActions.shareKey));
      final save = tester.getRect(find.byKey(NewsDetailActions.saveKey));
      expect(back.left, greaterThanOrEqualTo(0));
      expect(like.left, greaterThanOrEqualTo(back.right));
      expect(share.left, greaterThanOrEqualTo(like.right));
      expect(save.left, greaterThanOrEqualTo(share.right));
      expect(save.right, lessThanOrEqualTo(360));
      // Fonte, depois o cartão de ouvir, um abaixo do outro.
      await tester.ensureVisible(find.byKey(ReadAloudBar.listenKey));
      await tester.pumpAndSettle();
      final source = tester.getRect(find.byKey(NewsDetailPage.sourceKey));
      final listen = tester.getRect(find.byKey(ReadAloudBar.listenKey));
      expect(listen.top, greaterThanOrEqualTo(source.bottom));
      expect(source.right, lessThanOrEqualTo(360));
      // A pílula de velocidade fica dentro do cartão, sem estourar.
      final speed = tester.getRect(find.byKey(ReadAloudBar.speedKey));
      expect(speed.left, greaterThanOrEqualTo(listen.right));
      expect(speed.right, lessThanOrEqualTo(360));
      // Rolando até o fim, o bloco de atividade também cabe.
      await tester.scrollUntilVisible(
        find.byKey(RelatedActivityCard.cardKey),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(tester.takeException(), isNull);
      final card = tester.getRect(find.byKey(RelatedActivityCard.cardKey));
      expect(card.right, lessThanOrEqualTo(360));
    });

    testWidgets('ordem de leitura: botões da capa, categoria, título, fonte, '
        'ouvir, velocidade, texto e atividade', (tester) async {
      final handle = tester.ensureSemantics();
      await signIn();
      fullDetail();
      await pumpPage(tester, size: const Size(800, 3200));

      // Ordem de leitura: de cima para baixo e, na mesma linha (voltar,
      // curtir, compartilhar e salvar; ouvir e velocidade), da esquerda para
      // a direita.
      Offset at(Pattern label) =>
          tester.getTopLeft(find.bySemanticsLabel(label));
      final List<Offset> order = [
        at('Voltar'),
        at('Curtir, 2 curtidas'),
        at('Compartilhar'),
        at('Salvar'),
        at('Phishing'),
        at(RegExp('^Notícia n1, Folha de Teste, ')),
        at('Abrir fonte'),
        at('Ouvir'),
        at('Velocidade: normal, 1x'),
        at(RegExp('^Texto completo da notícia')),
        at(RegExp('^Pratique o que aprendeu')),
      ];
      for (int i = 1; i < order.length; i++) {
        final Offset before = order[i - 1];
        final Offset after = order[i];
        expect(
          after.dy > before.dy ||
              (after.dy == before.dy && after.dx > before.dx),
          isTrue,
          reason: 'item $i ($after) deveria vir depois de $before',
        );
      }
      handle.dispose();
    });

    testWidgets('alto contraste: paleta da feature 009, texto legível e '
        '48 dp', (tester) async {
      await signIn();
      fullDetail();
      await pumpPage(tester, theme: AppTheme.highContrastTheme);

      final context = tester.element(find.byType(NewsDetailPage));
      expect(context.colors, AppPalette.highContrast);
      expect(
        tester.widget<Text>(find.text('Notícia n1')).style?.color,
        // Redesign 2.0: títulos na cor de texto principal (preto no alto
        // contraste).
        AppPalette.highContrast.textForeground,
      );
      expect(
        tester.widget<Text>(find.text(longContent)).style?.color,
        AppPalette.highContrast.textForeground,
      );
      expectTouchTargets(tester);
      expect(tester.takeException(), isNull);
    });
  });

  group('saída durante curtir ou salvar', () {
    const String wait = 'Aguarde: salvando sua escolha.';

    testWidgets('salvando: o voltar do aparelho não sai e avisa; depois sai', (
      tester,
    ) async {
      await signIn();
      await pumpPage(tester);
      repository.saveGate = Completer<void>();
      await tester.tap(find.byKey(NewsDetailActions.saveKey));
      await tester.pump();

      await tester.binding.handlePopRoute();
      await tester.pump();

      expect(find.text(wait), findsOneWidget);
      expect(find.byType(NewsDetailPage), findsOneWidget);
      expect(find.text('tela anterior'), findsNothing);

      repository.saveGate!.complete();
      await tester.pumpAndSettle();

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.text('tela anterior'), findsOneWidget);
      expect(find.byType(NewsDetailPage), findsNothing);
    });

    testWidgets('curtindo: o botão voltar fica desativado e avisa; depois '
        'volta a funcionar', (tester) async {
      final handle = tester.ensureSemantics();
      await signIn();
      await pumpPage(tester);
      repository.likeGate = Completer<void>();
      await tester.tap(find.byKey(NewsDetailActions.likeKey));
      await tester.pump();

      expect(
        tester.getSemantics(backButton()),
        isSemantics(
          label: 'Voltar',
          isButton: true,
          hasEnabledState: true,
          isEnabled: false,
        ),
      );
      expect(tester.getSize(backButton()).width, greaterThanOrEqualTo(48));

      await tester.tap(backButton());
      await tester.pump();

      expect(find.text(wait), findsOneWidget);
      expect(find.byType(NewsDetailPage), findsOneWidget);

      repository.likeGate!.complete();
      await tester.pumpAndSettle();

      expect(
        tester.getSemantics(backButton()),
        isSemantics(label: 'Voltar', isEnabled: true),
      );

      await tester.tap(backButton());
      await tester.pumpAndSettle();

      expect(find.text('tela anterior'), findsOneWidget);
      handle.dispose();
    });
  });
}
