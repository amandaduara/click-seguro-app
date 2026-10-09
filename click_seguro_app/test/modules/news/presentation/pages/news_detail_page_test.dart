import 'dart:async';

import 'package:click_seguro_app/core/errors/errors.dart';
import 'package:click_seguro_app/core/widgets/safe_offline_banner.dart';
import 'package:click_seguro_app/core/widgets/slow_request_notice.dart';
import 'package:click_seguro_app/modules/common/accessibility/accessibility_preferences_notifier.dart';
import 'package:click_seguro_app/modules/common/presentation/controller/read_aloud_controller.dart';
import 'package:click_seguro_app/modules/common/services/external_launcher_service.dart';
import 'package:click_seguro_app/modules/common/services/share_service.dart';
import 'package:click_seguro_app/modules/common/services/text_to_speech_service.dart';
import 'package:click_seguro_app/modules/common/services/user_session_service.dart';
import 'package:click_seguro_app/modules/news/domain/entities/news_detail_entity.dart';
import 'package:click_seguro_app/modules/news/domain/failures/news_failures.dart';
import 'package:click_seguro_app/modules/news/presentation/controller/news_detail_controller.dart';
import 'package:click_seguro_app/modules/news/presentation/pages/news_detail_page.dart';
import 'package:click_seguro_app/modules/news/presentation/widgets/news_detail_actions.dart';
import 'package:click_seguro_app/modules/news/presentation/widgets/read_aloud_bar.dart';
import 'package:click_seguro_app/modules/news/presentation/widgets/related_activity_card.dart';
import 'package:click_seguro_app/modules/shell/presentation/widgets/account_required_sheet.dart';
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

/// Segura o resultado até [gate] terminar, para tocar duas vezes seguidas.
class _GatedShareService extends FakeShareService {
  Completer<void>? gate;

  @override
  Future<ShareOutcome> shareText(String text, {String? subject}) async {
    final outcome = await super.shareText(text, subject: subject);
    await gate?.future;
    return outcome;
  }
}

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
  late _GatedShareService share;
  late _GatedLauncherService launcher;
  late FakeNewsRepository repository;
  late FakeTextToSpeechService tts;
  late AccessibilityPreferencesNotifier preferences;
  late GoRouter router;

  setUp(() async {
    session = UserSessionService(FakeSecureStorageService());
    tts = FakeTextToSpeechService();
    preferences = AccessibilityPreferencesNotifier();
    share = _GatedShareService();
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
            child: NewsDetailPage(newsId: id),
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
  }) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    router = buildRouter();
    await pumpLocalized(tester, router: router, locale: locale);
    unawaited(router.push<void>('/news/n1'));
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
    }
  }

  NewsDetailController controllerOf(WidgetTester tester) =>
      tester.element(find.byType(NewsDetailPage)).read<NewsDetailController>();

  group('leitura', () {
    testWidgets('carregando com barra superior e voltar', (tester) async {
      repository.detailGate = Completer<void>();

      await pumpPage(tester, settle: false);

      expect(find.byType(AppBar), findsOneWidget);
      expect(find.byType(BackButton), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      repository.detailGate!.complete();
      await tester.pumpAndSettle();
    });

    testWidgets('"Conectando ao servidor…" depois de alguns segundos', (
      tester,
    ) async {
      repository.detailGate = Completer<void>();
      await pumpPage(tester, settle: false);
      const slow = 'Conectando ao servidor. Isso pode levar até um minuto.';

      expect(find.text(slow), findsNothing);
      await tester.pump(SlowRequestNotice.delay);

      expect(find.text(slow), findsOneWidget);
      repository.detailGate!.complete();
      await tester.pumpAndSettle();
      expect(find.text(slow), findsNothing);
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
      expect(find.byType(BackButton), findsOneWidget);
    });

    testWidgets('detalhe completo: imagem, categorias, título, fonte, data, '
        'curtidas e texto', (tester) async {
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
      expect(find.text('Folha de Teste · 20 de set.'), findsOneWidget);
      expect(find.text('2 curtidas'), findsOneWidget);
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

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      expect(find.text('tela anterior'), findsOneWidget);
      expect(find.text('Notícia n1'), findsNothing);
    });
  });

  group('ouvir', () {
    const spokenN1 = 'Notícia n1.\n\nTexto';

    testWidgets('com voz: "Ouvir" e velocidades, na velocidade guardada', (
      tester,
    ) async {
      preferences.value = preferences.value.copyWith(
        readingSpeed: ReadingSpeed.fast,
      );

      await pumpPage(tester);

      expect(find.text('Ouvir'), findsOneWidget);
      expect(find.text('Velocidade: rápida'), findsOneWidget);
      expect(find.text('lenta'), findsOneWidget);
      expect(find.text('normal'), findsOneWidget);
      expect(find.text('rápida'), findsOneWidget);
      expect(tts.spoken, isEmpty);
    });

    testWidgets('"Ouvir" lê título e texto e vira "Parar"', (tester) async {
      await pumpPage(tester);

      await tester.tap(find.text('Ouvir'));
      await tester.pump();

      expect(tts.spoken.single, (
        text: spokenN1,
        language: SpeechLanguage.ptBr,
        speed: ReadingSpeed.normal,
      ));
      expect(find.text('Parar'), findsOneWidget);
      expect(find.text('Ouvir'), findsNothing);
    });

    testWidgets('"Parar" para a voz e volta a "Ouvir"', (tester) async {
      await pumpPage(tester);
      await tester.tap(find.text('Ouvir'));
      await tester.pump();

      await tester.tap(find.text('Parar'));
      await tester.pump();

      expect(tts.stopCalls, 1);
      expect(find.text('Ouvir'), findsOneWidget);
    });

    testWidgets('trocar a velocidade vale para a próxima leitura e não muda '
        'a preferência', (tester) async {
      await pumpPage(tester);

      await tester.tap(find.text('rápida'));
      await tester.pump();
      expect(find.text('Velocidade: rápida'), findsOneWidget);
      await tester.tap(find.text('Ouvir'));
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

      await tester.tap(find.text('Ouvir'));
      await tester.pump();

      expect(tts.spoken.single.text, 'Notícia n1');
    });

    testWidgets('leitura automática começa sozinha, uma vez só', (
      tester,
    ) async {
      preferences.value = preferences.value.copyWith(autoReadAloud: true);

      await pumpPage(tester);

      expect(tts.spoken.single.text, spokenN1);
      expect(find.text('Parar'), findsOneWidget);

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

      await tester.tap(find.text('Parar'));
      await tester.pump();
      await controllerOf(tester).retry();
      await tester.pumpAndSettle();

      expect(tts.spoken, hasLength(1));
      expect(find.text('Ouvir'), findsOneWidget);
    });

    testWidgets('sem voz: sem "Ouvir", sem velocidade, sem leitura '
        'automática e sem erro', (tester) async {
      tts.availableLanguages = {};
      preferences.value = preferences.value.copyWith(autoReadAloud: true);

      await pumpPage(tester);

      expect(find.text('Ouvir'), findsNothing);
      expect(find.byType(ReadAloudBar), findsOneWidget);
      expect(find.textContaining('Velocidade'), findsNothing);
      expect(tts.spoken, isEmpty);
      expect(find.text('Notícia n1'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('app em inglês: voz em inglês', (tester) async {
      await pumpPage(tester, locale: const Locale('en', 'US'));

      await tester.tap(find.text('Listen'));
      await tester.pump();

      expect(tts.spoken.single.language, SpeechLanguage.enUs);
      expect(tts.spoken.single.text, spokenN1);
    });

    testWidgets('sair da tela para a voz', (tester) async {
      await pumpPage(tester);
      await tester.tap(find.text('Ouvir'));
      await tester.pump();

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      expect(tts.stopCalls, greaterThanOrEqualTo(1));
    });

    testWidgets('rótulos de acessibilidade e botões de 48 dp', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpPage(tester);

      expect(find.bySemanticsLabel('Ouvir'), findsOneWidget);
      expect(find.bySemanticsLabel('Velocidade: normal'), findsOneWidget);
      final listen = tester.getSize(find.byKey(ReadAloudBar.listenKey));
      expect(listen.height, greaterThanOrEqualTo(48));
      for (final speed in ReadingSpeed.values) {
        final size = tester.getSize(find.byKey(ReadAloudBar.speedKey(speed)));
        expect(size.width, greaterThanOrEqualTo(48), reason: '$speed');
        expect(size.height, greaterThanOrEqualTo(48), reason: '$speed');
      }

      await tester.tap(find.text('Ouvir'));
      await tester.pump();
      expect(find.bySemanticsLabel('Parar'), findsOneWidget);
      handle.dispose();
    });
  });

  group('salvar', () {
    Future<void> signIn() => session.saveSession(
      accessToken: 'tk',
      refreshToken: 'rf',
      email: 'ana@test.com',
      userName: 'Ana',
    );

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
      expect(find.text('Salvar'), findsOneWidget);
      expect(find.text('Salvo'), findsNothing);
      expect(find.byIcon(LucideIcons.bookmark), findsOneWidget);

      await tapSave(tester);

      expect(find.byType(AccountRequiredSheet), findsOneWidget);
      expect(repository.saveCalls, isEmpty);
      expect(find.text('Salvo'), findsNothing);
    });

    testWidgets('com conta: o marcador reflete o isSaved do serviço', (
      tester,
    ) async {
      await signIn();
      detailSaved(isSaved: true);

      await pumpPage(tester);

      expect(find.text('Salvo'), findsOneWidget);
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

      expect(find.text('Salvo'), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);

      repository.saveGate!.complete();
      await tester.pumpAndSettle();

      expect(find.text('Notícia salva'), findsOneWidget);
      expect(find.text('Salvo'), findsOneWidget);

      repository.saveGate = null;
      await tapSave(tester);

      expect(find.text('Removida dos salvos'), findsOneWidget);
      expect(find.text('Salvar'), findsOneWidget);
      expect(repository.saveCalls, ['n1', 'n1']);
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
      expect(find.text('Salvar'), findsOneWidget);
      expect(find.text('Salvo'), findsNothing);
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
      expect(find.text('Salvar'), findsOneWidget);

      await signIn();
      await tester.pumpAndSettle();

      expect(repository.detailCalls, ['n1', 'n1']);
      expect(find.text('Salvo'), findsOneWidget);
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

  group('compartilhar e fonte', () {
    Finder shareButton() => find.byKey(NewsDetailActions.shareKey);
    Finder sourceButton() => find.byKey(NewsDetailActions.sourceKey);

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
      expect(find.text('Compartilhar'), findsOneWidget);
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

    testWidgets('rótulos e botões de 48 dp', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpPage(tester);

      expect(find.bySemanticsLabel('Compartilhar'), findsOneWidget);
      expect(find.bySemanticsLabel('Abrir fonte'), findsOneWidget);
      expect(find.byIcon(LucideIcons.share2), findsOneWidget);
      expect(find.byIcon(LucideIcons.externalLink), findsOneWidget);
      for (final key in [
        NewsDetailActions.shareKey,
        NewsDetailActions.sourceKey,
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

    testWidgets('sem módulo sugerido: sem bloco', (tester) async {
      detailWith(suggested: null);

      await pumpPage(tester);

      expect(card(), findsNothing);
      expect(find.text('Pratique o que aprendeu'), findsNothing);
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
}
