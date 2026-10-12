import 'package:click_seguro_app/core/errors/errors.dart';
import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/theme/app_theme.dart';
import 'package:click_seguro_app/core/widgets/safe_button.dart';
import 'package:click_seguro_app/core/widgets/safe_offline_banner.dart';
import 'package:click_seguro_app/modules/common/services/user_session_service.dart';
import 'package:click_seguro_app/modules/notifications/domain/entities/alert_entity.dart';
import 'package:click_seguro_app/modules/notifications/domain/entities/alerts_snapshot.dart';
import 'package:click_seguro_app/modules/notifications/presentation/pages/notifications_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../fakes/fake_secure_storage_service.dart';
import '../../../../helpers/localized_app.dart';
import '../../../../helpers/notifications_provider.dart';
import '../../fakes/alerts_fixtures.dart';
import '../../fakes/fake_notifications_repository.dart';

void main() {
  late UserSessionService session;
  late FakeNotificationsRepository repository;
  late GoRouter router;

  setUp(() async {
    session = UserSessionService(FakeSecureStorageService());
    GetIt.instance.registerSingleton<UserSessionService>(session);
    await session.saveSession(
      accessToken: 'tk',
      refreshToken: 'rf',
      email: 'ana@test.com',
    );
    repository = FakeNotificationsRepository();
    router = GoRouter(
      initialLocation: '/notifications',
      routes: [
        GoRoute(
          path: '/notifications',
          builder: (_, _) => const NotificationsPage(),
        ),
        GoRoute(path: '/login', builder: (_, _) => const Text('tela login')),
        GoRoute(
          path: '/profile/edit',
          builder: (_, _) => Scaffold(
            appBar: AppBar(),
            body: const Text('tela editar perfil'),
          ),
        ),
        GoRoute(
          path: '/news/:id',
          builder: (_, state) => Scaffold(
            appBar: AppBar(),
            body: Text('detalhe ${state.pathParameters['id']}'),
          ),
        ),
      ],
    );
  });

  tearDown(() async => GetIt.instance.reset());

  /// Meio-dia local, [days] dias antes do "hoje" dos testes (o agrupamento
  /// usa o dia local).
  DateTime noon(int days) {
    final DateTime local = testNow.toLocal();
    return DateTime(local.year, local.month, local.day - days, 12);
  }

  AlertEntity alertAt(
    String id,
    DateTime publishedAt, {
    bool isRead = false,
    String title = 'Golpe do Pix',
  }) => alert(
    newsId: id,
    title: '$title $id',
    publishedAt: publishedAt,
    isRead: isRead,
  );

  Future<void> pumpPage(WidgetTester tester, {ThemeData? theme}) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pumpLocalized(
      tester,
      router: router,
      providers: [fakeNotificationsProvider(repository)],
      theme: theme,
    );
  }

  final Finder inScroll = find.byType(ListView);

  Finder textInScroll(String text) =>
      find.descendant(of: inScroll, matching: find.text(text));

  group('lista', () {
    testWidgets('abrir a tela confere de novo, sem esperar o intervalo', (
      tester,
    ) async {
      repository.stored = snapshot(alerts: [alertAt('a', noon(0))]);

      await pumpPage(tester);

      expect(repository.receiveCalls, 1);
      expect(repository.fetchCalls, hasLength(1));
    });

    testWidgets('título "Alertas" na barra', (tester) async {
      await pumpPage(tester);

      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.text('Alertas'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('grupos Hoje, Ontem e Anteriores, na ordem', (tester) async {
      repository.stored = snapshot(
        alerts: [
          alertAt('old', noon(5)),
          alertAt('today', noon(0)),
          alertAt('yest', noon(1)),
        ],
      );

      await pumpPage(tester);

      final double today = tester.getTopLeft(find.text('Hoje')).dy;
      final double yesterday = tester.getTopLeft(find.text('Ontem')).dy;
      final double earlier = tester.getTopLeft(find.text('Anteriores')).dy;
      expect(today, lessThan(yesterday));
      expect(yesterday, lessThan(earlier));
    });

    testWidgets('sem grupo vazio', (tester) async {
      repository.stored = snapshot(alerts: [alertAt('today', noon(0))]);

      await pumpPage(tester);

      expect(find.text('Hoje'), findsOneWidget);
      expect(find.text('Ontem'), findsNothing);
      expect(find.text('Anteriores'), findsNothing);
    });

    testWidgets('cada alerta mostra título, fonte e hora ou data', (
      tester,
    ) async {
      repository.stored = snapshot(
        alerts: [
          alertAt(
            'today',
            DateTime(noon(0).year, noon(0).month, noon(0).day, 8, 5),
          ),
          alertAt('old', noon(5)),
        ],
      );

      await pumpPage(tester);

      expect(find.text('Golpe do Pix today'), findsOneWidget);
      expect(find.textContaining('Folha de Teste · 08:05'), findsOneWidget);
      final DateTime old = noon(5);
      final String date =
          '${old.day.toString().padLeft(2, '0')}/${old.month.toString().padLeft(2, '0')}';
      expect(find.textContaining('Folha de Teste · $date'), findsOneWidget);
    });

    testWidgets('"Novo" escrito só nos não lidos', (tester) async {
      repository.stored = snapshot(
        alerts: [
          alertAt('a', noon(0)),
          alertAt('b', noon(0), isRead: true),
          alertAt('c', noon(1)),
        ],
      );

      await pumpPage(tester);

      expect(find.text('Novo'), findsNWidgets(2));
    });

    testWidgets('resumo fixo no alto, fora da lista que rola', (tester) async {
      repository.stored = snapshot(
        alerts: [alertAt('a', noon(0)), alertAt('b', noon(0))],
      );

      await pumpPage(tester);

      expect(find.text('Você tem 2 alertas novos'), findsOneWidget);
      expect(textInScroll('Você tem 2 alertas novos'), findsNothing);
      expect(textInScroll('Hoje'), findsOneWidget);
    });

    testWidgets('resumo no singular e sem não lidos', (tester) async {
      repository.stored = snapshot(
        alerts: [alertAt('a', noon(0)), alertAt('b', noon(0), isRead: true)],
      );
      await pumpPage(tester);
      expect(find.text('Você tem 1 alerta novo'), findsOneWidget);

      await tester.tap(find.text('Golpe do Pix a'));
      await tester.pumpAndSettle();
      router.pop();
      await tester.pumpAndSettle();

      expect(find.text('Você não tem alertas novos'), findsOneWidget);
    });

    testWidgets(
      'tocar marca como lido e abre a notícia; ao voltar, sem "Novo"',
      (tester) async {
        repository.stored = snapshot(
          alerts: [alertAt('a', noon(0)), alertAt('b', noon(0))],
        );
        await pumpPage(tester);

        await tester.tap(find.text('Golpe do Pix a'));
        await tester.pumpAndSettle();

        expect(find.text('detalhe a'), findsOneWidget);
        expect(
          repository.stored.alerts.firstWhere((a) => a.newsId == 'a').isRead,
          isTrue,
        );

        router.pop();
        await tester.pumpAndSettle();

        expect(find.text('Novo'), findsOneWidget);
        expect(find.text('Você tem 1 alerta novo'), findsOneWidget);
      },
    );

    testWidgets('toque duplo abre a notícia uma vez', (tester) async {
      repository.stored = snapshot(alerts: [alertAt('a', noon(0))]);
      await pumpPage(tester);

      await tester.tap(find.text('Golpe do Pix a'));
      await tester.tap(find.text('Golpe do Pix a'), warnIfMissed: false);
      await tester.pumpAndSettle();
      router.pop();
      await tester.pumpAndSettle();

      expect(find.text('detalhe a'), findsNothing);
      expect(find.byType(NotificationsPage), findsOneWidget);
    });

    testWidgets('sem alertas: mensagem e explicação', (tester) async {
      await pumpPage(tester);

      expect(find.text('Você não tem alertas.'), findsOneWidget);
      expect(
        find.text('Quando sair uma notícia nova, ela aparece aqui.'),
        findsOneWidget,
      );
      expect(find.text('Marcar todos como lidos'), findsNothing);
    });

    testWidgets('sem internet: faixa fixa no alto e a lista guardada', (
      tester,
    ) async {
      repository.stored = snapshot(alerts: [alertAt('a', noon(0))]);
      repository.receiveAlertsError = const ConnectionFailure();

      await pumpPage(tester);

      expect(find.byType(SafeOfflineBanner), findsOneWidget);
      expect(
        find.descendant(of: inScroll, matching: find.byType(SafeOfflineBanner)),
        findsNothing,
      );
      expect(find.text('Golpe do Pix a'), findsOneWidget);
    });

    testWidgets('outras falhas e sucesso: sem faixa', (tester) async {
      repository.stored = snapshot(alerts: [alertAt('a', noon(0))]);
      repository.newAlertsError = const ServerFailure();

      await pumpPage(tester);

      expect(find.byType(SafeOfflineBanner), findsNothing);
    });

    testWidgets('nenhum SnackBar nem menu de três pontos', (tester) async {
      repository.stored = snapshot(alerts: [alertAt('a', noon(0))]);
      repository.receiveAlertsError = const ConnectionFailure();

      await pumpPage(tester);

      expect(find.byType(SnackBar), findsNothing);
      expect(find.byType(PopupMenuButton<Object?>), findsNothing);
      expect(find.byType(PopupMenuButton<String>), findsNothing);
      expect(find.byIcon(Icons.more_vert), findsNothing);
    });
  });

  group('marcar todos', () {
    final Finder markAll = find.text('Marcar todos como lidos');

    testWidgets('com não lidos: botão fixo no alto, com texto e ≥ 48 dp', (
      tester,
    ) async {
      repository.stored = snapshot(
        alerts: [alertAt('a', noon(0)), alertAt('b', noon(1))],
      );

      await pumpPage(tester);

      expect(markAll, findsOneWidget);
      expect(textInScroll('Marcar todos como lidos'), findsNothing);
      final Finder button = find.ancestor(
        of: markAll,
        matching: find.byType(SafeButton),
      );
      expect(tester.getSize(button).height, greaterThanOrEqualTo(48));
      expect(
        tester.getTopLeft(markAll).dy,
        lessThan(tester.getTopLeft(find.text('Hoje')).dy),
      );
    });

    testWidgets('tocar zera tudo, sem confirmação', (tester) async {
      repository.stored = snapshot(
        alerts: [alertAt('a', noon(0)), alertAt('b', noon(1))],
      );
      await pumpPage(tester);
      expect(find.text('Novo'), findsNWidgets(2));

      await tester.tap(markAll);
      await tester.pump();

      expect(find.byType(AlertDialog), findsNothing);
      expect(find.byType(BottomSheet), findsNothing);
      expect(find.text('Novo'), findsNothing);
      expect(find.text('Você não tem alertas novos'), findsOneWidget);
      expect(markAll, findsNothing);
      await tester.pumpAndSettle();
      expect(repository.stored.unreadCount, 0);
    });

    testWidgets('sem não lidos: botão ausente', (tester) async {
      repository.stored = snapshot(
        alerts: [alertAt('a', noon(0), isRead: true)],
      );

      await pumpPage(tester);

      expect(markAll, findsNothing);
    });

    testWidgets('lista vazia: botão ausente', (tester) async {
      await pumpPage(tester);

      expect(markAll, findsNothing);
    });
  });

  group('visitante e desligado', () {
    const String disabledText = 'Os alertas novos estão desligados.';
    final Finder disabledAction = find.text('Ligar em Editar perfil');

    testWidgets('visitante: convite dentro da tela e nenhum pedido', (
      tester,
    ) async {
      await session.startGuestSession();
      repository.stored = snapshot(alerts: [alertAt('a', noon(0))]);

      await pumpPage(tester);

      expect(
        find.text('Entre na sua conta para receber alertas de notícias novas.'),
        findsOneWidget,
      );
      expect(find.byIcon(LucideIcons.bell), findsOneWidget);
      final Finder login = find.text('Entrar ou criar conta');
      expect(login, findsOneWidget);
      expect(
        tester
            .getSize(
              find.ancestor(of: login, matching: find.byType(SafeButton)),
            )
            .height,
        greaterThanOrEqualTo(48),
      );
      expect(find.text('Golpe do Pix a'), findsNothing);
      expect(find.text('Você não tem alertas.'), findsNothing);
      expect(repository.getSnapshotCalls, 0);
      expect(repository.receiveCalls, 0);
      expect(repository.fetchCalls, isEmpty);
    });

    testWidgets('visitante: o botão vai para o login', (tester) async {
      await session.startGuestSession();
      await pumpPage(tester);

      await tester.tap(find.text('Entrar ou criar conta'));
      await tester.pumpAndSettle();

      expect(find.text('tela login'), findsOneWidget);
    });

    testWidgets(
      'sessão passa a autenticada com a tela aberta: mostra a lista',
      (tester) async {
        await session.startGuestSession();
        repository.stored = snapshot(alerts: [alertAt('a', noon(0))]);
        await pumpPage(tester);
        expect(find.text('Golpe do Pix a'), findsNothing);

        await session.saveSession(
          accessToken: 'tk',
          refreshToken: 'rf',
          email: 'ana@test.com',
        );
        await tester.pumpAndSettle();

        expect(find.text('Entrar ou criar conta'), findsNothing);
        expect(find.text('Golpe do Pix a'), findsOneWidget);
      },
    );

    testWidgets('desligado: aviso fixo, botão para o perfil e lista visível', (
      tester,
    ) async {
      repository.stored = snapshot(alerts: [alertAt('a', noon(0))]);
      repository.receiveAlerts = false;

      await pumpPage(tester);

      expect(find.text(disabledText), findsOneWidget);
      expect(textInScroll(disabledText), findsNothing);
      expect(disabledAction, findsOneWidget);
      expect(
        tester
            .getSize(
              find.ancestor(
                of: disabledAction,
                matching: find.byType(SafeButton),
              ),
            )
            .height,
        greaterThanOrEqualTo(48),
      );
      expect(find.text('Golpe do Pix a'), findsOneWidget);

      await tester.tap(disabledAction);
      await tester.pumpAndSettle();

      expect(find.text('tela editar perfil'), findsOneWidget);
    });

    testWidgets('ligado ou desconhecido: sem aviso', (tester) async {
      repository.stored = snapshot(alerts: [alertAt('a', noon(0))]);
      await pumpPage(tester);
      expect(find.text(disabledText), findsNothing);
      expect(disabledAction, findsNothing);
    });

    testWidgets('desconhecido (falha ao ler a chave): sem aviso', (
      tester,
    ) async {
      repository.stored = snapshot(alerts: [alertAt('a', noon(0))]);
      repository.receiveAlertsError = const ServerFailure();

      await pumpPage(tester);

      expect(find.text(disabledText), findsNothing);
    });
  });

  group('acessibilidade (FR-020, SC-008)', () {
    void useScale2x(WidgetTester tester) {
      tester.platformDispatcher.textScaleFactorTestValue = 2.0;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    }

    /// Tela de celular pequeno (360 dp), onde a fonte 2× aperta mais.
    Future<void> pumpSmall(WidgetTester tester, {ThemeData? theme}) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await pumpLocalized(
        tester,
        router: router,
        providers: [fakeNotificationsProvider(repository)],
        theme: theme,
      );
    }

    void expectInside(Rect rect, {double width = 360}) {
      expect(rect.left, greaterThanOrEqualTo(0));
      expect(rect.right, lessThanOrEqualTo(width));
    }

    testWidgets('alvos de toque com 48 dp ou mais: alerta e botões', (
      tester,
    ) async {
      repository.stored = snapshot(
        alerts: [alertAt('a', noon(0)), alertAt('b', noon(1), isRead: true)],
      );
      repository.receiveAlerts = false;
      await pumpPage(tester);

      for (final String id in ['a', 'b']) {
        final Size tile = tester.getSize(find.byKey(ValueKey('alert-$id')));
        expect(tile.height, greaterThanOrEqualTo(48));
        expect(tile.width, greaterThanOrEqualTo(48));
      }
      for (final String label in [
        'Marcar todos como lidos',
        'Ligar em Editar perfil',
      ]) {
        final Size button = tester.getSize(
          find.ancestor(
            of: find.text(label),
            matching: find.byType(SafeButton),
          ),
        );
        expect(button.height, greaterThanOrEqualTo(48), reason: label);
      }
    });

    testWidgets('leitura na ordem: título, resumo, botão, grupos e alertas', (
      tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      repository.stored = snapshot(
        alerts: [alertAt('a', noon(0)), alertAt('b', noon(1))],
      );
      await pumpPage(tester);

      final List<double> tops = [
        tester.getTopLeft(find.text('Alertas')).dy,
        tester.getTopLeft(find.text('Você tem 2 alertas novos')).dy,
        tester.getTopLeft(find.text('Marcar todos como lidos')).dy,
        tester.getTopLeft(find.text('Hoje')).dy,
        tester
            .getTopLeft(find.bySemanticsLabel(RegExp('^Novo, Golpe do Pix a,')))
            .dy,
        tester.getTopLeft(find.text('Ontem')).dy,
        tester
            .getTopLeft(find.bySemanticsLabel(RegExp('^Novo, Golpe do Pix b,')))
            .dy,
      ];
      expect(tops, orderedEquals([...tops]..sort()));
      expect(tops.toSet(), hasLength(tops.length));
      expect(
        tester.getSemantics(find.text('Hoje')),
        matchesSemantics(label: 'Hoje', isHeader: true),
      );
      expect(
        tester.getSemantics(find.text('Você tem 2 alertas novos')),
        matchesSemantics(label: 'Você tem 2 alertas novos', isLiveRegion: true),
      );
      handle.dispose();
    });

    testWidgets('fonte 2×: lista, resumo e botão sem sobreposição', (
      tester,
    ) async {
      useScale2x(tester);
      repository.stored = snapshot(
        alerts: [
          alertAt('a', noon(0), title: 'Golpe do falso boleto enviado'),
          alertAt('b', noon(1)),
        ],
      );
      await pumpSmall(tester);

      final BuildContext context = tester.element(
        find.byType(NotificationsPage),
      );
      expect(MediaQuery.textScalerOf(context).scale(10), 20);
      expect(tester.takeException(), isNull);
      final Rect summary = tester.getRect(
        find.text('Você tem 2 alertas novos'),
      );
      final Rect button = tester.getRect(
        find.ancestor(
          of: find.text('Marcar todos como lidos'),
          matching: find.byType(SafeButton),
        ),
      );
      expect(summary.bottom, lessThanOrEqualTo(button.top));
      expect(button.height, greaterThanOrEqualTo(48));
      expectInside(summary);
      expectInside(button);
      final Rect first = tester.getRect(find.byKey(const ValueKey('alert-a')));
      expectInside(first);
      // Com fonte 2× o alto entra na lista: uma rolagem só, sem área interna.
      expect(find.byType(Scrollable), findsOneWidget);
      expect(textInScroll('Você tem 2 alertas novos'), findsOneWidget);
      expect(textInScroll('Marcar todos como lidos'), findsOneWidget);
      expect(summary.top, lessThan(tester.getTopLeft(find.text('Hoje')).dy));
    });

    testWidgets('fonte 1,3×: alto fixo sem estourar numa tela 360×800', (
      tester,
    ) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      repository.stored = snapshot(
        alerts: [alertAt('a', noon(0)), alertAt('b', noon(1))],
      );
      repository.receiveAlerts = false;
      await pumpSmall(tester);

      expect(tester.takeException(), isNull);
      expect(find.byType(Scrollable), findsOneWidget);
      expect(textInScroll('Marcar todos como lidos'), findsNothing);
      expect(textInScroll('Os alertas novos estão desligados.'), findsNothing);
      expect(find.byKey(const ValueKey('alert-a')), findsOneWidget);
    });

    testWidgets('fonte 2×: desligado e sem internet juntos, sem estouro', (
      tester,
    ) async {
      useScale2x(tester);
      // O valor guardado diz "desligado"; a conferência falha sem internet.
      repository.stored = snapshot(
        receiveAlerts: false,
        alerts: [alertAt('a', noon(0)), alertAt('b', noon(1))],
      );
      repository.receiveAlertsError = const ConnectionFailure();
      await pumpSmall(tester);

      expect(tester.takeException(), isNull);
      expect(find.byType(Scrollable), findsOneWidget);
      expect(
        textInScroll('Os alertas novos estão desligados.'),
        findsOneWidget,
      );
      expect(find.byType(SafeOfflineBanner), findsOneWidget);
    });

    testWidgets('fonte 2×: aviso de desligado, texto do botão quebra linha', (
      tester,
    ) async {
      useScale2x(tester);
      repository.stored = snapshot(alerts: [alertAt('a', noon(0))]);
      repository.receiveAlerts = false;
      await pumpSmall(tester);

      expect(tester.takeException(), isNull);
      final Finder action = find.text('Ligar em Editar perfil');
      final Rect button = tester.getRect(
        find.ancestor(of: action, matching: find.byType(SafeButton)),
      );
      final Rect text = tester.getRect(action);
      expect(text.height, greaterThan(40), reason: 'o texto quebra em linhas');
      expect(text.top, greaterThanOrEqualTo(button.top));
      expect(text.bottom, lessThanOrEqualTo(button.bottom));
      expectInside(button);
      final Rect notice = tester.getRect(
        find.text('Os alertas novos estão desligados.'),
      );
      expect(notice.bottom, lessThanOrEqualTo(button.top));
    });

    testWidgets('fonte 2×: visitante, convite e botão inteiros', (
      tester,
    ) async {
      useScale2x(tester);
      await session.startGuestSession();
      await pumpSmall(tester);

      expect(tester.takeException(), isNull);
      final Rect button = tester.getRect(
        find.ancestor(
          of: find.text('Entrar ou criar conta'),
          matching: find.byType(SafeButton),
        ),
      );
      expect(button.height, greaterThanOrEqualTo(48));
      expectInside(button);
    });

    testWidgets('fonte 2×: sem alertas, sem estouro', (tester) async {
      useScale2x(tester);
      await pumpSmall(tester);

      expect(tester.takeException(), isNull);
      expect(find.text('Você não tem alertas.'), findsOneWidget);
    });

    testWidgets('alto contraste: paleta da feature 009 na lista', (
      tester,
    ) async {
      repository.stored = snapshot(
        alerts: [alertAt('a', noon(0)), alertAt('b', noon(1), isRead: true)],
      );
      repository.receiveAlerts = false;
      await pumpPage(tester, theme: AppTheme.highContrastTheme);

      final BuildContext context = tester.element(
        find.byType(NotificationsPage),
      );
      final AppPalette colors = context.colors;
      expect(colors, AppPalette.highContrast);
      expect(tester.takeException(), isNull);

      Color colorOf(Finder finder) => tester.widget<Text>(finder).style!.color!;
      final Color unread = colorOf(find.text('Golpe do Pix a'));
      final Color read = colorOf(find.text('Golpe do Pix b'));
      expect(unread, colors.secondary);
      expect(read, colors.textMutedForeground);
      expect(colorOf(find.text('Novo')), colors.textPrimaryForeground);
      expect(
        colorOf(find.text('Os alertas novos estão desligados.')),
        colors.textForeground,
      );
      // Alerta lido legível: contraste mínimo 7:1 (AAA) sobre o cartão.
      expect(_contrast(read, colors.card), greaterThanOrEqualTo(7));
      expect(_contrast(unread, colors.card), greaterThanOrEqualTo(7));
      expect(
        _contrast(colors.textPrimaryForeground, colors.primary),
        greaterThanOrEqualTo(7),
      );
    });
  });
}

/// Razão de contraste WCAG entre duas cores opacas.
double _contrast(Color a, Color b) {
  final double la = a.computeLuminance();
  final double lb = b.computeLuminance();
  final double hi = la > lb ? la : lb;
  final double lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}
