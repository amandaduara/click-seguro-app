import 'package:click_seguro_app/core/errors/errors.dart';
import 'package:click_seguro_app/modules/common/services/user_session_service.dart';
import 'package:click_seguro_app/modules/settings/domain/entities/account_summary_entity.dart';
import 'package:click_seguro_app/modules/settings/domain/entities/language_choice.dart';
import 'package:click_seguro_app/modules/settings/presentation/pages/settings_page.dart';
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

  testWidgets('cartão da conta abre o Perfil', (tester) async {
    await open(tester);

    expect(find.text('MS'), findsOneWidget);
    expect(find.text('Maria da Silva'), findsOneWidget);
    expect(find.text('Ver e editar seu perfil'), findsOneWidget);

    await tapAndSettle(tester, find.text('Ver e editar seu perfil'));
    expectPage('/profile');
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
      ('Sobre o SafeNews', '/settings/about'),
    ]) {
      await tapAndSettle(tester, find.text(label));
      expectPage(path);
      await back(tester);
    }
  });

  testWidgets('"Sobre o SafeNews" mostra a versão', (tester) async {
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

    await tester.scrollUntilVisible(
      logout,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      find.text(
        'Ao sair, seus contatos de emergência continuam guardados neste '
        'celular.',
      ),
      findsOneWidget,
    );

    await tester.tap(logout);
    await tester.tap(logout, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    expectPage('/login');
    expect(session.endReason, SessionEndReason.userLogout);
  });

  testWidgets('conta com erro: nome da sessão e linhas funcionando', (
    tester,
  ) async {
    repository.accountResults[0] = const Left(ConnectionFailure());
    await open(tester);

    expect(find.text('Maria da Silva'), findsOneWidget);
    expect(find.text('MS'), findsOneWidget);

    await tapAndSettle(tester, find.text('Dados pessoais'));
    expectPage('/profile/edit');
  });

  testWidgets('voltar da edição de dados recarrega o cartão', (tester) async {
    await open(tester);
    final int before = repository.accountCalls;
    repository.accountResults[0] = const Right(
      AccountSummaryEntity(name: 'Maria Souza', receiveNotifications: true),
    );

    await tapAndSettle(tester, find.text('Dados pessoais'));
    await back(tester);

    expect(repository.accountCalls, before + 1);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, 1000));
    await tester.pumpAndSettle();
    expect(find.text('Maria Souza'), findsOneWidget);
  });

  group('sem conta', () {
    testWidgets('visitante por link direto vê o convite, sem pedido', (
      tester,
    ) async {
      await session.startGuestSession();
      await open(tester);

      expect(find.text('Entre na sua conta'), findsOneWidget);
      expect(repository.totalCalls, 0);

      await tapAndSettle(tester, find.text('Entrar ou criar conta'));
      expectPage('/login');
    });

    testWidgets('sessão expira com a tela aberta → convite', (tester) async {
      await open(tester);

      await session.expire();
      await tester.pumpAndSettle();

      expect(find.text('Entre na sua conta'), findsOneWidget);
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

    testWidgets('falha → volta e avisa', (tester) async {
      repository.alertsResults[0] = const Left(ConnectionFailure());
      await open(tester);

      await tester.tap(alertsSwitch());
      await tester.pumpAndSettle();

      expect(tester.widget<Switch>(alertsSwitch()).value, isTrue);
      expect(
        find.text('Não foi possível mudar os alertas. Tente de novo.'),
        findsOneWidget,
      );
    });

    testWidgets('conta com erro → chave desabilitada e tentar de novo', (
      tester,
    ) async {
      repository.accountResults
        ..[0] = const Left(ConnectionFailure())
        ..add(const Right(testAccount));
      await open(tester);

      expect(tester.widget<Switch>(alertsSwitch()).onChanged, isNull);
      expect(find.text('Não foi possível carregar'), findsOneWidget);

      await tester.tap(find.text('Tentar novamente'));
      await tester.pumpAndSettle();

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

    testWidgets('English troca o app na hora e guarda; depois volta ao '
        'celular', (tester) async {
      await open(tester);

      await openSheet(tester, 'Idioma');
      await choose(tester, 'English');

      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('English'), findsOneWidget);
      expect(languages.saved, [LanguageChoice.english]);

      await openSheet(tester, 'Language');
      await choose(tester, 'Phone language');

      expect(languages.saved, [LanguageChoice.english, LanguageChoice.device]);
    });
  });
}
