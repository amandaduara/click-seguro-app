import 'package:click_seguro_app/core/errors/errors.dart';
import 'package:click_seguro_app/modules/common/services/user_session_service.dart';
import 'package:click_seguro_app/modules/settings/domain/usecases/get_account_usecase.dart';
import 'package:click_seguro_app/modules/settings/domain/usecases/get_app_version_usecase.dart';
import 'package:click_seguro_app/modules/settings/domain/usecases/logout_usecase.dart';
import 'package:click_seguro_app/modules/settings/domain/usecases/set_receive_alerts_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../../fakes/fake_app_info_service.dart';
import '../../../fakes/fake_secure_storage_service.dart';
import '../fakes/fake_account_repository.dart';

void main() {
  late FakeAccountRepository repository;

  setUp(() => repository = FakeAccountRepository());

  test('GetAccountUseCase repassa a conta', () async {
    final result = await GetAccountUseCase(repository)();

    expect(result.getRight().toNullable(), testAccount);
    expect(repository.accountCalls, 1);
  });

  test('LogoutUseCase encerra a sessão pedida pela pessoa', () async {
    final session = UserSessionService(FakeSecureStorageService());
    await session.saveSession(
      accessToken: 'acesso-1',
      refreshToken: 'renovacao-1',
      email: 'maria@exemplo.com',
    );

    await LogoutUseCase(session)();

    expect(session.isAuthenticated, isFalse);
    expect(session.endReason, SessionEndReason.userLogout);
  });

  test('GetAppVersionUseCase devolve a versão instalada', () async {
    expect(await GetAppVersionUseCase(FakeAppInfoService('2.3.4'))(), '2.3.4');
  });

  test('SetReceiveAlertsUseCase repassa o valor e a falha', () async {
    repository.alertsResults[0] = const Left(ConnectionFailure());

    final result = await SetReceiveAlertsUseCase(repository)(false);

    expect(repository.alertsCalls, [false]);
    expect(result.getLeft().toNullable(), isA<ConnectionFailure>());
  });
}
