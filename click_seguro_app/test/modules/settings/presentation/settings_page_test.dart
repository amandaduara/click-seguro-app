import 'dart:async';

import 'package:click_seguro_app/core/errors/errors.dart';
import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/modules/common/services/user_session_service.dart';
import 'package:click_seguro_app/modules/settings/domain/entities/account_summary_entity.dart';
import 'package:click_seguro_app/modules/settings/domain/entities/language_choice.dart';
import 'package:click_seguro_app/modules/settings/presentation/pages/settings_page.dart';
import 'package:click_seguro_app/modules/settings/presentation/widgets/alerts_switch_tile.dart';
import 'package:click_seguro_app/modules/settings/presentation/widgets/settings_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../fakes/fake_secure_storage_service.dart';
import '../../../helpers/localized_app.dart';
import '../../../helpers/settings_dependencies.dart';
import '../fakes/fake_account_repository.dart';
import '../fakes/fake_language_repository.dart';

void main() {
  late UserSessionService session;
  late FakeAccountRepository repository;
  late GoRouter router;

  const placeholders = [
    '/profile',
    '/profile/edit',
    '/settings/security',
    '/settings/accessibility',
    '/settings/privacy',
    '/settings/about',
    '/login',
  ];

  /// Como o roteador do app: só a saída pedida pela pessoa leva ao login.
  GoRouter buildRouter() => GoRouter(
    initialLocation: '/settings',
    refreshListenable: session.sessionStatus,
    redirect: (_, state) =>
        session.sessionStatus.value == UserSessionStatus.unauthenticated &&
            session.endReason == SessionEndReason.userLogout &&
            state.matchedLocation != '/login'
        ? '/login'
        : null,
    routes: [
      GoRoute(path: '/settings', builder: (_, _) => const SettingsPage()),
      for (final path in placeholders)
        GoRoute(
          path: path,
          builder: (_, _) =>
              Scaffold(appBar: AppBar(), body: Text('page:$path')),
        ),
    ],
  );

  setUp(() async {
    session = UserSessionService(FakeSecureStorageService());
    GetIt.instance.registerSingleton<UserSessionService>(session);
    repository = registerSettingsDependencies(GetIt.instance);
    await session.saveSession(
      accessToken: 'acesso-1',
      refreshToken: 'renovacao-1',
      email: 'maria@exemplo.com',
      userName: 'Maria da Silva',
    );
    router = buildRouter();
  });

  tearDown(() => GetIt.instance.reset());

  Future<void> open(WidgetTester tester) =>
      pumpLocalized(tester, router: router);

  Future<void> tapAndSettle(WidgetTester tester, Finder finder) async {
    if (finder.evaluate().isEmpty) {
      await tester.scrollUntilVisible(
        finder,
        200,
        scrollable: find.byType(Scrollable).first,
      );
    }
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  void expectPage(String path) =>
      expect(find.text('page:$path'), findsOneWidget);

  Future<void> back(WidgetTester tester) async {
    router.pop();
    await tester.pumpAndSettle();
  }

  /// O título grande rola com a lista: volta ao topo para vê-lo.
  Future<void> scrollToTop(WidgetTester tester) async {
    await tester.drag(find.byType(Scrollable).first, const Offset(0, 2000));
    await tester.pumpAndSettle();
  }

  // O cartão "Editar perfil" saiu (abria a mesma tela de "Dados
  // pessoais"), a pedido da usuária (specs/023).
  testWidgets('sem o cartão "Editar perfil"; "Dados pessoais" abre a edição '
      'e volta às Configurações', (tester) async {
    await open(tester);

    expect(find.text('Editar perfil'), findsNothing);
    expect(find.text('Maria da Silva'), findsNothing);

    await tapAndSettle(tester, find.text('Dados pessoais'));
    expectPage('/profile/edit');
    expect(find.text('page:/profile'), findsNothing);

    await back(tester);
    await scrollToTop(tester);
    expect(find.text('Configurações'), findsOneWidget);
  });

  testWidgets('"Dados pessoais" com as rotas do app (aba Perfil): abre a '
      'edição, não o Perfil, e volta às Configurações', (tester) async {
    final GlobalKey<NavigatorState> rootKey = GlobalKey<NavigatorState>();
    // Mesma forma do app: o Perfil é aba do shell, a edição é filha dele
    // sobre as abas e as Configurações ficam no navegador raiz.
    final GoRouter appShaped = GoRouter(
      navigatorKey: rootKey,
      initialLocation: '/profile',
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (_, _, shell) => Scaffold(body: shell),
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/profile',
                  builder: (context, _) => TextButton(
                    onPressed: () => context.push('/settings'),
                    child: const Text('page:/profile'),
                  ),
                  routes: [
                    GoRoute(
                      path: 'edit',
                      parentNavigatorKey: rootKey,
                      builder: (_, _) =>
                          const Scaffold(body: Text('page:/profile/edit')),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        GoRoute(
          path: '/settings',
          parentNavigatorKey: rootKey,
          builder: (_, _) => const SettingsPage(),
        ),
      ],
    );
    await pumpLocalized(tester, router: appShaped);
    await tester.tap(find.text('page:/profile'));
    await tester.pumpAndSettle();

    await tapAndSettle(tester, find.text('Dados pessoais'));
    expectPage('/profile/edit');

    appShaped.pop();
    await tester.pumpAndSettle();
    await scrollToTop(tester);
    expect(find.text('Configurações'), findsOneWidget);
    expect(find.text('Dados pessoais'), findsOneWidget);
  });

  testWidgets('voltar redondo sai das Configurações', (tester) async {
    final GoRouter withHome = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, _) => TextButton(
            onPressed: () => context.push('/settings'),
            child: const Text('page:/home'),
          ),
        ),
        GoRoute(path: '/settings', builder: (_, _) => const SettingsPage()),
      ],
    );
    await pumpLocalized(tester, router: withHome);
    await tester.tap(find.text('page:/home'));
    await tester.pumpAndSettle();

    final semantics = tester.ensureSemantics();
    expect(find.bySemanticsLabel('Voltar'), findsOneWidget);
    semantics.dispose();
    await tester.tap(find.byKey(SettingsBackButton.buttonKey));
    await tester.pumpAndSettle();

    expect(find.text('page:/home'), findsOneWidget);
  });

  testWidgets('seções na ordem do quadro', (tester) async {
    await open(tester);

    final double conta = tester.getTopLeft(find.text('Conta')).dy;
    final double leitura = tester
        .getTopLeft(find.text('Leitura e aparência'))
        .dy;
    expect(conta, lessThan(leitura));
    await tester.scrollUntilVisible(
      find.text('Sobre'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Sobre'), findsOneWidget);
  });

  testWidgets('cada linha abre a sua tela', (tester) async {
    await open(tester);

    expect(find.text('Nome, e-mail, telefone e foto'), findsOneWidget);
    for (final (label, path) in [
      ('Dados pessoais', '/profile/edit'),
      ('Alterar senha', '/settings/security'),
      ('Acessibilidade', '/settings/accessibility'),
      ('Privacidade', '/settings/privacy'),
      ('Sobre o Click Seguro', '/settings/about'),
    ]) {
      await tapAndSettle(tester, find.text(label));
      expectPage(path);
      await back(tester);
    }
  });

  testWidgets('"Sobre o Click Seguro" mostra a versão', (tester) async {
    await open(tester);
    await tester.scrollUntilVisible(
      find.text('Versão 1.0.0'),
      200,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.text('Versão 1.0.0'), findsOneWidget);
  });

  testWidgets('sair: frase dos contatos e login na hora, sem aviso', (
    tester,
  ) async {
    await open(tester);
    final Finder logout = find.text('Sair da conta');

    // A frase fica abaixo do botão; com a letra maior, rola até ela também.
    final Finder phrase = find.text(
      'Ao sair, seus contatos de emergência continuam guardados neste '
      'celular.',
    );
    await tester.scrollUntilVisible(
      phrase,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(logout, findsOneWidget);
    expect(phrase, findsOneWidget);

    await tester.ensureVisible(logout);
    await tester.pumpAndSettle();
    await tester.tap(logout);
    await tester.tap(logout, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    expectPage('/login');
    expect(session.endReason, SessionEndReason.userLogout);
  });

  testWidgets('conta com erro: as linhas continuam funcionando', (
    tester,
  ) async {
    repository.accountResults[0] = const Left(ConnectionFailure());
    await open(tester);

    await tapAndSettle(tester, find.text('Dados pessoais'));
    expectPage('/profile/edit');
  });

  testWidgets('voltar da edição de dados recarrega a conta', (tester) async {
    await open(tester);
    final int before = repository.accountCalls;
    repository.accountResults[0] = const Right(
      AccountSummaryEntity(name: 'Maria Souza', receiveNotifications: true),
    );

    await tapAndSettle(tester, find.text('Dados pessoais'));
    await back(tester);

    expect(repository.accountCalls, before + 1);
  });

  group('sem conta', () {
    const List<String> accountOnly = [
      'Maria da Silva',
      'Conta',
      'Dados pessoais',
      'Alterar senha',
      'Alertas',
      'Alertas de notícias novas',
      'Sair da conta',
      'Entre na sua conta',
      'Entrar ou criar conta',
    ];

    void expectGuestList() {
      for (final text in [
        'Leitura e aparência',
        'Acessibilidade',
        'Idioma',
        'Sobre',
        'Privacidade',
        'Sobre o Click Seguro',
        'Versão 1.0.0',
      ]) {
        expect(find.text(text), findsOneWidget, reason: text);
      }
      for (final text in accountOnly) {
        expect(find.text(text), findsNothing, reason: text);
      }
    }

    testWidgets('visitante vê só o que não precisa de conta, sem pedido', (
      tester,
    ) async {
      await session.startGuestSession();
      await open(tester);

      expectGuestList();
      expect(repository.totalCalls, 0);
    });

    testWidgets('visitante: cada linha abre a sua tela', (tester) async {
      await session.startGuestSession();
      await open(tester);

      for (final (row, path) in [
        ('Acessibilidade', '/settings/accessibility'),
        ('Privacidade', '/settings/privacy'),
        ('Sobre o Click Seguro', '/settings/about'),
      ]) {
        await tapAndSettle(tester, find.text(row));
        expectPage(path);
        await back(tester);
      }
    });

    testWidgets('sessão expira com a tela aberta → lista do visitante', (
      tester,
    ) async {
      await open(tester);

      await session.expire();
      await tester.pumpAndSettle();

      expectGuestList();
      expect(tester.takeException(), isNull);
    });

    testWidgets('visitante com fonte 2× num celular: sem estouro', (
      tester,
    ) async {
      tester.view
        ..physicalSize = const Size(1080, 2340)
        ..devicePixelRatio = 3;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await session.startGuestSession();

      await open(tester);
      await tester.scrollUntilVisible(
        find.text('Sobre o Click Seguro'),
        300,
        scrollable: find.byType(Scrollable).first,
      );

      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('fonte 2× num celular: sem estouro e linhas com 48+', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(1080, 2340)
      ..devicePixelRatio = 3;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await open(tester);
    await tester.scrollUntilVisible(
      find.text('Sair da conta'),
      300,
      scrollable: find.byType(Scrollable).first,
    );

    expect(tester.takeException(), isNull);
    expect(
      tester.getSize(find.byType(InkWell).first).height,
      greaterThanOrEqualTo(48),
    );
  });

  group('alertas', () {
    Finder alertsSwitch() => find.byType(Switch);

    testWidgets('linha com o texto e a chave com o valor da conta', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await open(tester);

      expect(find.text('Alertas'), findsOneWidget);
      expect(find.text('Alertas de notícias novas'), findsOneWidget);
      expect(
        find.text('Avisamos quando sair uma notícia de golpe'),
        findsOneWidget,
      );
      expect(tester.widget<Switch>(alertsSwitch()).value, isTrue);
      expect(
        tester.getSemantics(alertsSwitch()),
        isSemantics(hasToggledState: true, isToggled: true, isEnabled: true),
      );
      semantics.dispose();
    });

    testWidgets('tocar desliga na hora e salva', (tester) async {
      await open(tester);

      await tester.tap(alertsSwitch());
      await tester.pumpAndSettle();

      expect(tester.widget<Switch>(alertsSwitch()).value, isFalse);
      expect(repository.alertsCalls, [false]);
    });

    // Carregamento no lugar da chave enquanto salva (validação da usuária,
    // specs/023): a pessoa vê que a escolha está indo.
    testWidgets('salvando: carregamento no lugar da chave', (tester) async {
      await open(tester);
      repository.alertsGate = Completer<void>();

      await tester.tap(alertsSwitch());
      await tester.pump();

      expect(alertsSwitch(), findsNothing);
      expect(find.byKey(AlertsSwitchTile.busyKey), findsOneWidget);

      repository.alertsGate!.complete();
      await tester.pumpAndSettle();
      expect(find.byKey(AlertsSwitchTile.busyKey), findsNothing);
      expect(tester.widget<Switch>(alertsSwitch()).value, isFalse);
    });

    Finder retryIcon() => find.byKey(AlertsSwitchTile.retryKey);

    testWidgets('falha ao salvar → ícone vermelho no lugar da chave e aviso', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      repository.alertsResults[0] = const Left(ConnectionFailure());
      await open(tester);

      await tester.tap(alertsSwitch());
      await tester.pumpAndSettle();

      expect(alertsSwitch(), findsNothing);
      expect(find.text('Tentar novamente'), findsNothing);
      expect(retryIcon(), findsOneWidget);
      final Icon icon = tester.widget<Icon>(
        find.descendant(of: retryIcon(), matching: find.byType(Icon)),
      );
      expect(icon.icon, LucideIcons.rotateCcw);
      expect(icon.color, AppPalette.light.destructive);
      final Size size = tester.getSize(retryIcon());
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));
      expect(
        find.text('Não foi possível mudar os alertas. Tente de novo.'),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel(RegExp('Tentar de novo')), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('ícone reenvia o valor pedido, com carregamento no lugar', (
      tester,
    ) async {
      repository.alertsResults
        ..[0] = const Left(ConnectionFailure())
        ..add(const Right(unit));
      await open(tester);
      await tester.tap(alertsSwitch());
      await tester.pumpAndSettle();
      repository.alertsGate = Completer<void>();

      await tester.tap(retryIcon());
      await tester.pump();

      expect(find.byKey(AlertsSwitchTile.busyKey), findsOneWidget);
      expect(retryIcon(), findsNothing);

      repository.alertsGate!.complete();
      await tester.pumpAndSettle();

      expect(repository.alertsCalls, [false, false]);
      expect(retryIcon(), findsNothing);
      expect(tester.widget<Switch>(alertsSwitch()).value, isFalse);
    });

    testWidgets('conta com erro → ícone no lugar da chave e recarrega', (
      tester,
    ) async {
      repository.accountResults
        ..[0] = const Left(ConnectionFailure())
        ..add(const Right(testAccount));
      await open(tester);

      expect(alertsSwitch(), findsNothing);
      expect(find.text('Tentar novamente'), findsNothing);
      expect(find.text('Não foi possível carregar'), findsOneWidget);

      await tapAndSettle(tester, retryIcon());

      expect(repository.accountCalls, 2);
      expect(retryIcon(), findsNothing);
      expect(tester.widget<Switch>(alertsSwitch()).onChanged, isNotNull);
    });
  });

  group('idioma', () {
    late FakeLanguageRepository languages;

    setUp(() async {
      await GetIt.instance.reset();
      session = UserSessionService(FakeSecureStorageService());
      GetIt.instance.registerSingleton<UserSessionService>(session);
      languages = FakeLanguageRepository();
      repository = registerSettingsDependencies(
        GetIt.instance,
        languages: languages,
      );
      await session.saveSession(
        accessToken: 'acesso-1',
        refreshToken: 'renovacao-1',
        email: 'maria@exemplo.com',
        userName: 'Maria da Silva',
      );
      router = buildRouter();
    });

    /// A troca de idioma carrega o arquivo de tradução de verdade.
    Future<void> choose(WidgetTester tester, String option) async {
      await tester.tap(find.text(option).last);
      // A folha fecha num quadro; só então a tradução carrega (fora do
      // relógio falso).
      for (var i = 0; i < 3; i++) {
        await tester.pumpAndSettle();
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)),
        );
      }
      await tester.pumpAndSettle();
    }

    Future<void> openSheet(WidgetTester tester, String row) =>
        tapAndSettle(tester, find.text(row));

    testWidgets('linha mostra a escolha e a folha tem as três opções', (
      tester,
    ) async {
      await open(tester);

      expect(find.text('Idioma do celular'), findsOneWidget);
      await openSheet(tester, 'Idioma');

      for (final option in ['Idioma do celular', 'Português', 'English']) {
        final Finder tile = find.ancestor(
          of: find.text(option).last,
          matching: find.byType(ListTile),
        );
        expect(tester.getSize(tile).height, greaterThanOrEqualTo(56));
      }
      expect(find.byIcon(LucideIcons.check), findsOneWidget);
    });

    // A folha é a mesma da conta (_ReadingSection); a troca de tradução já é
    // coberta no teste abaixo. Escolher "Português" evita carregar o inglês
    // duas vezes no mesmo arquivo, o que o easy_localization não refaz.
    testWidgets('visitante escolhe o idioma: guarda, sem pedido', (
      tester,
    ) async {
      await session.startGuestSession();
      await open(tester);

      await openSheet(tester, 'Idioma');
      await choose(tester, 'Português');

      expect(find.text('Português'), findsOneWidget);
      expect(languages.saved, [LanguageChoice.portuguese]);
      expect(repository.totalCalls, 0);
    });

    testWidgets('English troca o app na hora e guarda; depois volta ao '
        'celular', (tester) async {
      await open(tester);

      await openSheet(tester, 'Idioma');
      await choose(tester, 'English');

      await scrollToTop(tester);
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('English'), findsOneWidget);
      expect(languages.saved, [LanguageChoice.english]);

      await openSheet(tester, 'Language');
      await choose(tester, 'Phone language');

      expect(languages.saved, [LanguageChoice.english, LanguageChoice.device]);
    });
  });
}
