import 'dart:async';

import 'package:click_seguro_app/core/errors/errors.dart';
import 'package:click_seguro_app/core/widgets/safe_button.dart';
import 'package:click_seguro_app/core/widgets/safe_text_field.dart';
import 'package:click_seguro_app/modules/common/services/image_storage_service.dart';
import 'package:click_seguro_app/modules/common/services/user_session_service.dart';
import 'package:click_seguro_app/modules/profile/domain/entities/profile_entity.dart';
import 'package:click_seguro_app/modules/profile/domain/failures/profile_failures.dart';
import 'package:click_seguro_app/modules/profile/presentation/pages/profile_edit_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../../fakes/fake_image_storage_service.dart';
import '../../../../fakes/fake_secure_storage_service.dart';
import '../../../../helpers/localized_app.dart';
import '../../../../helpers/profile_dependencies.dart';
import '../../fakes/fake_profile_repository.dart';

void main() {
  late UserSessionService session;
  late FakeProfileRepository repository;
  late FakeImageStorageService storage;

  const ProfileEntity withPhone = ProfileEntity(
    name: 'Maria da Silva',
    email: 'maria@exemplo.com',
    phone: '+5511912345678',
  );

  setUp(() async {
    session = UserSessionService(FakeSecureStorageService());
    GetIt.instance.registerSingleton<UserSessionService>(session);
    storage = FakeImageStorageService();
    repository = registerProfileDependencies(
      GetIt.instance,
      imageStorage: storage,
    )..profileResults[0] = const Right(withPhone);
    await session.saveSession(
      accessToken: 'token',
      refreshToken: 'refresh',
      email: 'maria@exemplo.com',
      userName: 'Maria da Silva',
    );
  });

  tearDown(() => GetIt.instance.reset());

  GoRouter buildRouter() => GoRouter(
    initialLocation: '/start',
    routes: [
      GoRoute(
        path: '/start',
        builder: (context, _) => Scaffold(
          body: TextButton(
            onPressed: () => context.push('/edit'),
            child: const Text('abrir'),
          ),
        ),
      ),
      GoRoute(path: '/edit', builder: (_, _) => const ProfileEditPage()),
      GoRoute(
        path: '/login',
        builder: (_, _) => const Scaffold(body: Text('page:/login')),
      ),
    ],
  );

  Future<void> open(WidgetTester tester) async {
    await pumpLocalized(tester, router: buildRouter());
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
  }

  Finder field(String label) => find.descendant(
    of: find.widgetWithText(SafeTextField, label),
    matching: find.byType(TextField),
  );

  String textOf(WidgetTester tester, String label) =>
      tester.widget<TextField>(field(label)).controller!.text;

  Finder saveButton() => find.widgetWithText(SafeButton, 'Salvar');

  bool saveDisabled(WidgetTester tester) =>
      tester.widget<SafeButton>(saveButton()).disabled;

  /// O quadro seguinte ao texto digitado já tem o botão habilitado.
  Future<void> tapSave(WidgetTester tester) async {
    await tester.pump();
    await tester.ensureVisible(saveButton());
    await tester.tap(saveButton());
    await tester.pumpAndSettle();
  }

  testWidgets('visitante vê o convite e nenhum pedido sai', (tester) async {
    await session.startGuestSession();

    await open(tester);

    expect(find.text('Entre na sua conta'), findsOneWidget);
    expect(repository.totalCalls, 0);
  });

  testWidgets('campos preenchidos, telefone com máscara', (tester) async {
    await open(tester);

    expect(textOf(tester, 'Nome'), 'Maria da Silva');
    expect(textOf(tester, 'E-mail'), 'maria@exemplo.com');
    expect(textOf(tester, 'Telefone'), '(11) 91234-5678');
  });

  testWidgets('a máscara se aplica ao digitar', (tester) async {
    await open(tester);

    await tester.enterText(field('Telefone'), '11934567890');
    await tester.pump();

    expect(textOf(tester, 'Telefone'), '(11) 93456-7890');
  });

  testWidgets('"Salvar" desabilitado sem mudança', (tester) async {
    await open(tester);

    expect(saveDisabled(tester), isTrue);

    await tester.enterText(field('Nome'), 'Maria Souza');
    await tester.pump();

    expect(saveDisabled(tester), isFalse);
  });

  testWidgets('nome curto → erro no campo, sem pedido', (tester) async {
    await open(tester);

    await tester.enterText(field('Nome'), 'Ana');
    await tapSave(tester);

    expect(find.text('O nome precisa ter de 6 a 150 letras.'), findsOneWidget);
    expect(repository.updateCalls, isEmpty);
  });

  testWidgets('salvar ok → "Dados salvos"', (tester) async {
    await open(tester);

    await tester.enterText(field('Nome'), 'Maria Souza');
    await tapSave(tester);

    expect(find.text('Dados salvos'), findsOneWidget);
    expect(repository.updateCalls.single.name, 'Maria Souza');
    expect(saveDisabled(tester), isTrue);
  });

  testWidgets('e-mail em uso → aviso no campo', (tester) async {
    repository.updateResults[0] = const Left(EmailInUseFailure());
    await open(tester);

    await tester.enterText(field('E-mail'), 'ja@exemplo.com');
    await tapSave(tester);

    expect(find.text('Este e-mail já está em uso.'), findsOneWidget);
  });

  testWidgets('falha do serviço → aviso e o texto continua', (tester) async {
    repository.updateResults[0] = const Left(ServerFailure());
    await open(tester);

    await tester.enterText(field('Nome'), 'Maria Souza');
    await tapSave(tester);

    expect(
      find.text('Não foi possível salvar. Tente de novo mais tarde.'),
      findsOneWidget,
    );
    expect(textOf(tester, 'Nome'), 'Maria Souza');
  });

  testWidgets('apagar telefone já salvo → "Informe um telefone com DDD."', (
    tester,
  ) async {
    await open(tester);

    await tester.enterText(field('Telefone'), '');
    await tapSave(tester);

    expect(find.text('Informe um telefone com DDD.'), findsOneWidget);
    expect(repository.updateCalls, isEmpty);
  });

  group('voltar com mudança', () {
    Future<void> changeAndGoBack(WidgetTester tester) async {
      await open(tester);
      await tester.enterText(field('Nome'), 'Maria Souza');
      await tester.pump();
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
    }

    testWidgets('pergunta; "Continuar editando" fica', (tester) async {
      await changeAndGoBack(tester);

      expect(find.text('Descartar alterações?'), findsOneWidget);
      await tester.tap(find.text('Continuar editando'));
      await tester.pumpAndSettle();

      expect(textOf(tester, 'Nome'), 'Maria Souza');
    });

    testWidgets('"Descartar" sai', (tester) async {
      await changeAndGoBack(tester);

      await tester.tap(find.text('Descartar'));
      await tester.pumpAndSettle();

      expect(find.text('abrir'), findsOneWidget);
    });

    testWidgets('sem mudança, volta direto', (tester) async {
      await open(tester);

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      expect(find.text('abrir'), findsOneWidget);
    });
  });

  testWidgets('falha ao carregar → erro e tentar de novo', (tester) async {
    repository.profileResults
      ..[0] = const Left(ConnectionFailure())
      ..add(const Right(withPhone));
    await open(tester);

    await tester.tap(find.text('Tentar novamente'));
    await tester.pumpAndSettle();

    expect(textOf(tester, 'E-mail'), 'maria@exemplo.com');
  });

  testWidgets('"Salvar" com ao menos 48 de altura', (tester) async {
    await open(tester);

    expect(tester.getSize(saveButton()).height, greaterThanOrEqualTo(48));
  });

  testWidgets('fonte 2× num celular: sem estouro', (tester) async {
    tester.view
      ..physicalSize = const Size(1080, 2340)
      ..devicePixelRatio = 3;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await open(tester);
    await tester.ensureVisible(saveButton());
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  group('foto', () {
    const ProfileEntity withAvatar = ProfileEntity(
      name: 'Maria da Silva',
      email: 'maria@exemplo.com',
      avatarUrl: 'https://img.test/antiga.png',
    );

    Finder photo() => find.bySemanticsLabel('Trocar foto');

    Future<void> openSheet(WidgetTester tester) async {
      await tester.tap(photo());
      await tester.pumpAndSettle();
    }

    testWidgets('foto com rótulo e 48 de toque; folha sem "Remover"', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await open(tester);

      expect(tester.getSize(photo()).height, greaterThanOrEqualTo(48));
      await openSheet(tester);

      expect(find.text('Galeria'), findsOneWidget);
      expect(find.text('Câmera'), findsOneWidget);
      expect(find.text('Remover foto'), findsNothing);
      semantics.dispose();
    });

    testWidgets('com foto, a folha tem "Remover foto"', (tester) async {
      final semantics = tester.ensureSemantics();
      repository.profileResults[0] = const Right(withAvatar);
      await open(tester);

      await openSheet(tester);

      expect(find.text('Remover foto'), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('escolher → "Enviando foto…" e depois some', (tester) async {
      final semantics = tester.ensureSemantics();
      storage.nextResult = const PickedImage('/app/images/img_1.png');
      repository.uploadGate = Completer<void>();
      await open(tester);

      await openSheet(tester);
      await tester.tap(find.text('Galeria'));
      // O indicador gira enquanto envia: sem pumpAndSettle.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Enviando foto…'), findsOneWidget);
      expect(storage.pickedSources, [PhotoSource.gallery]);

      repository.uploadGate!.complete();
      await tester.pumpAndSettle();

      expect(find.text('Enviando foto…'), findsNothing);
      expect(repository.uploadCalls, ['/app/images/img_1.png']);
      semantics.dispose();
    });

    testWidgets('sem permissão → explicação', (tester) async {
      final semantics = tester.ensureSemantics();
      storage.nextResult = const PickImagePermissionDenied();
      await open(tester);

      await openSheet(tester);
      await tester.tap(find.text('Câmera'));
      await tester.pumpAndSettle();

      expect(find.text('Sem acesso às fotos'), findsOneWidget);
      expect(
        find.text(
          'Para escolher uma foto, libere o acesso nas configurações do '
          'celular.',
        ),
        findsOneWidget,
      );
      semantics.dispose();
    });

    testWidgets('remover pede confirmação e chama o serviço', (tester) async {
      final semantics = tester.ensureSemantics();
      repository.profileResults[0] = const Right(withAvatar);
      await open(tester);

      await openSheet(tester);
      await tester.tap(find.text('Remover foto'));
      await tester.pumpAndSettle();

      expect(find.text('Remover a foto?'), findsOneWidget);
      await tester.tap(find.text('Remover'));
      await tester.pumpAndSettle();

      expect(repository.removeCalls, 1);
      semantics.dispose();
    });

    testWidgets('falha no envio → "Não foi possível trocar a foto."', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      storage.nextResult = const PickedImage('/app/images/img_1.png');
      repository.uploadResults[0] = const Left(ServerFailure());
      await open(tester);

      await openSheet(tester);
      await tester.tap(find.text('Galeria'));
      await tester.pumpAndSettle();

      expect(find.text('Não foi possível trocar a foto.'), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('imagem recusada → aviso de JPG ou PNG', (tester) async {
      final semantics = tester.ensureSemantics();
      storage.nextResult = const PickedImage('/app/images/img_1.gif');
      repository.uploadResults[0] = const Left(AvatarTypeFailure());
      await open(tester);

      await openSheet(tester);
      await tester.tap(find.text('Galeria'));
      await tester.pumpAndSettle();

      expect(
        find.text('Esta imagem não é aceita. Use uma foto JPG ou PNG.'),
        findsOneWidget,
      );
      semantics.dispose();
    });
  });
}
