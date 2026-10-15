import 'dart:async';

import 'package:click_seguro_app/core/errors/errors.dart';
import 'package:click_seguro_app/modules/common/services/user_session_service.dart';
import 'package:click_seguro_app/modules/settings/presentation/controller/account_state.dart';
import 'package:click_seguro_app/modules/settings/presentation/controller/settings_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../../fakes/fake_secure_storage_service.dart';
import '../fakes/fake_account_repository.dart';
import '../fakes/settings_controller_factory.dart';

void main() {
  late FakeAccountRepository repository;
  late UserSessionService session;
  late SettingsController controller;

  setUp(() async {
    repository = FakeAccountRepository();
    session = UserSessionService(FakeSecureStorageService());
    await session.saveSession(
      accessToken: 'acesso-1',
      refreshToken: 'renovacao-1',
      email: 'maria@exemplo.com',
      userName: 'Maria da Silva',
    );
    controller = buildSettingsController(repository, session);
  });

  test('começa carregando', () {
    expect(controller.account, isA<AccountLoading>());
    expect(controller.appVersion, isNull);
  });

  test('load: conta e versão', () async {
    await controller.load();

    expect(controller.account, isA<AccountLoaded>());
    expect((controller.account as AccountLoaded).account, testAccount);
    expect(controller.appVersion, '1.0.0');
  });

  test('conta falha → failed com a falha', () async {
    repository.accountResults[0] = const Left(ConnectionFailure());

    await controller.load();

    expect(controller.account, isA<AccountFailed>());
    expect(
      (controller.account as AccountFailed).failure,
      isA<ConnectionFailure>(),
    );
    expect(controller.appVersion, '1.0.0');
  });

  test('retryAccount recarrega só a conta', () async {
    repository.accountResults
      ..[0] = const Left(ConnectionFailure())
      ..add(const Right(testAccount));
    await controller.load();

    await controller.retryAccount();

    expect(controller.account, isA<AccountLoaded>());
    expect(repository.accountCalls, 2);
  });

  test('logout encerra a sessão uma vez só', () async {
    await Future.wait([controller.logout(), controller.logout()]);

    expect(session.isAuthenticated, isFalse);
    expect(session.endReason, SessionEndReason.userLogout);
  });

  test('dispose durante a carga não lança', () async {
    repository.accountGate = Completer<void>();
    final loading = controller.load();

    controller.dispose();
    repository.accountGate!.complete();

    await expectLater(loading, completes);
  });

  group('alertas', () {
    bool? alertsOn() => switch (controller.account) {
      AccountLoaded(:final account) => account.receiveNotifications,
      _ => null,
    };

    test('muda na hora e fica salvando até a resposta', () async {
      await controller.load();
      repository.alertsGate = Completer<void>();

      final saving = controller.setReceiveAlerts(false);

      expect(alertsOn(), isFalse);
      expect(controller.isSavingAlerts, isTrue);
      repository.alertsGate!.complete();
      expect(await saving, isNull);
      expect(controller.isSavingAlerts, isFalse);
      expect(alertsOn(), isFalse);
      expect(repository.alertsCalls, [false]);
    });

    test('falha → volta ao valor anterior e devolve a falha', () async {
      await controller.load();
      repository.alertsResults[0] = const Left(ConnectionFailure());

      final failure = await controller.setReceiveAlerts(false);

      expect(failure, isA<ConnectionFailure>());
      expect(alertsOn(), isTrue);
    });

    test('toque durante o envio é ignorado', () async {
      await controller.load();
      repository.alertsGate = Completer<void>();

      final first = controller.setReceiveAlerts(false);
      await controller.setReceiveAlerts(true);
      repository.alertsGate!.complete();
      await first;

      expect(repository.alertsCalls, [false]);
      expect(alertsOn(), isFalse);
    });

    test('sem conta carregada não faz nada', () async {
      repository.accountResults[0] = const Left(ConnectionFailure());
      await controller.load();

      expect(await controller.setReceiveAlerts(false), isNull);
      expect(repository.alertsCalls, isEmpty);
    });
  });
}
