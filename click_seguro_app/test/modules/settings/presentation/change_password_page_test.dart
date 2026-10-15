import 'package:click_seguro_app/core/errors/errors.dart';
import 'package:click_seguro_app/core/widgets/safe_text_field.dart';
import 'package:click_seguro_app/modules/common/services/user_session_service.dart';
import 'package:click_seguro_app/modules/settings/domain/failures/settings_failures.dart';
import 'package:click_seguro_app/modules/settings/presentation/pages/change_password_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../fakes/fake_secure_storage_service.dart';
import '../../../helpers/localized_app.dart';
import '../../../helpers/settings_dependencies.dart';
import '../fakes/fake_account_repository.dart';

void main() {
  late UserSessionService session;
  late FakeAccountRepository repository;

  setUp(() async {
    session = UserSessionService(FakeSecureStorageService());
    GetIt.instance.registerSingleton<UserSessionService>(session);
    repository = registerSettingsDependencies(GetIt.instance);
    await session.saveSession(
      accessToken: 'acesso-1',
      refreshToken: 'renovacao-1',
      email: 'maria@exemplo.com',
    );
  });

  tearDown(() => GetIt.instance.reset());

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
      GoRoute(
        path: '/settings',
        builder: (context, _) => Scaffold(
          body: TextButton(
            onPressed: () => context.push('/settings/security'),
            child: const Text('page:/settings'),
          ),
        ),
        routes: [
          GoRoute(
            path: 'security',
            builder: (_, _) => const ChangePasswordPage(),
          ),
        ],
      ),
      GoRoute(
        path: '/login',
        builder: (_, _) => const Scaffold(body: Text('page:/login')),
      ),
    ],
  );

  Future<void> open(WidgetTester tester) async {
    await pumpLocalized(tester, router: buildRouter());
    await tester.tap(find.text('page:/settings'));
    await tester.pumpAndSettle();
  }

  Finder field(String label) => find.descendant(
    of: find.widgetWithText(SafeTextField, label),
    matching: find.byType(TextField),
  );

  Future<void> fill(
    WidgetTester tester, {
    String current = 'Senha@123',
    String newPassword = 'NovaSenha@456',
    String? confirmation,
  }) async {
    await tester.enterText(field('Senha atual'), current);
    await tester.enterText(field('Nova senha'), newPassword);
    await tester.enterText(
      field('Confirmar nova senha'),
      confirmation ?? newPassword,
    );
    await tester.pump();
  }

  Future<void> tapSave(WidgetTester tester) async {
    final Finder save = find.text('Salvar');
    await tester.scrollUntilVisible(
      save,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(save);
    await tester.pumpAndSettle();
  }

  testWidgets('três campos ocultos com "Mostrar senha" de 48', (tester) async {
    final semantics = tester.ensureSemantics();
    await open(tester);

    expect(find.text('Alterar senha'), findsOneWidget);
    for (final label in ['Senha atual', 'Nova senha', 'Confirmar nova senha']) {
      expect(tester.widget<TextField>(field(label)).obscureText, isTrue);
    }
    final Finder show = find.byTooltip('Mostrar senha');
    expect(show, findsNWidgets(3));
    expect(tester.getSize(show.first).height, greaterThanOrEqualTo(48));

    await tester.tap(show.first);
    await tester.pump();

    expect(tester.widget<TextField>(field('Senha atual')).obscureText, isFalse);
    expect(tester.widget<TextField>(field('Nova senha')).obscureText, isTrue);
    semantics.dispose();
  });

  testWidgets('lista de regras marca ao digitar', (tester) async {
    await open(tester);

    expect(find.text('De 8 a 64 caracteres'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsNothing);

    await tester.enterText(field('Nova senha'), 'NovaSenha@456');
    await tester.pump();

    expect(find.byIcon(Icons.check_circle), findsNWidgets(5));
  });

  testWidgets('confirmação diferente → aviso, sem pedido', (tester) async {
    await open(tester);
    await fill(tester, confirmation: 'OutraSenha@789');

    await tapSave(tester);

    expect(find.text('As senhas não são iguais.'), findsOneWidget);
    expect(repository.changeCalls, isEmpty);
  });

  testWidgets('senha atual errada → aviso no campo e continua conectada', (
    tester,
  ) async {
    repository.changeResults[0] = const Left(WrongCurrentPasswordFailure());
    await open(tester);
    await fill(tester);

    await tapSave(tester);

    expect(find.text('Senha atual incorreta'), findsOneWidget);
    expect(session.isAuthenticated, isTrue);
    expect(
      tester.widget<TextField>(field('Nova senha')).controller!.text,
      'NovaSenha@456',
    );
  });

  testWidgets('nova igual → aviso no campo da nova', (tester) async {
    repository.changeResults[0] = const Left(SamePasswordFailure());
    await open(tester);
    await fill(tester);

    await tapSave(tester);

    expect(
      find.text('A nova senha precisa ser diferente da atual.'),
      findsOneWidget,
    );
  });

  testWidgets('falha genérica → aviso e campos mantidos', (tester) async {
    repository.changeResults[0] = const Left(ConnectionFailure());
    await open(tester);
    await fill(tester);

    await tapSave(tester);

    expect(
      find.text('Não foi possível trocar a senha. Tente de novo mais tarde.'),
      findsOneWidget,
    );
    expect(
      tester.widget<TextField>(field('Senha atual')).controller!.text,
      'Senha@123',
    );
  });

  testWidgets('sucesso → "Senha alterada" e volta', (tester) async {
    await open(tester);
    await fill(tester);

    await tapSave(tester);

    expect(find.text('Senha alterada'), findsOneWidget);
    expect(find.text('page:/settings'), findsOneWidget);
    expect(session.isAuthenticated, isTrue);
  });

  testWidgets('novo login falhou → login com o aviso', (tester) async {
    repository.changeResults[0] = const Left(PasswordChangedReloginFailure());
    await open(tester);
    await fill(tester);

    await tapSave(tester);

    expect(find.text('page:/login'), findsOneWidget);
    expect(
      find.text('Senha alterada. Entre de novo com a nova senha.'),
      findsOneWidget,
    );
  });

  group('voltar com texto', () {
    Future<void> typeAndGoBack(WidgetTester tester) async {
      await open(tester);
      await tester.enterText(field('Senha atual'), 'Senha@123');
      await tester.pump();
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
    }

    testWidgets('pergunta; "Continuar editando" fica', (tester) async {
      await typeAndGoBack(tester);

      expect(find.text('Descartar alterações?'), findsOneWidget);
      await tester.tap(find.text('Continuar editando'));
      await tester.pumpAndSettle();

      expect(find.text('Senha atual'), findsOneWidget);
    });

    testWidgets('"Descartar" sai', (tester) async {
      await typeAndGoBack(tester);

      await tester.tap(find.text('Descartar'));
      await tester.pumpAndSettle();

      expect(find.text('page:/settings'), findsOneWidget);
    });
  });

  testWidgets('fonte 2× num celular: sem estouro', (tester) async {
    tester.view
      ..physicalSize = const Size(1080, 2340)
      ..devicePixelRatio = 3;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await open(tester);
    await tester.scrollUntilVisible(
      find.text('Salvar'),
      200,
      scrollable: find.byType(Scrollable).first,
    );

    expect(tester.takeException(), isNull);
  });
}
