import 'package:click_seguro_app/core/errors/errors.dart';
import 'package:click_seguro_app/modules/common/api_client/api_client.dart';
import 'package:click_seguro_app/modules/common/services/user_session_service.dart';
import 'package:click_seguro_app/modules/settings/data/repositories/account_repository_impl.dart';
import 'package:click_seguro_app/modules/settings/domain/failures/settings_failures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../../fakes/fake_secure_storage_service.dart';
import '../fakes/fake_account_remote_data_source.dart';

void main() {
  late FakeAccountRemoteDataSource remote;
  late UserSessionService session;
  late AccountRepositoryImpl repository;

  setUp(() async {
    remote = FakeAccountRemoteDataSource();
    session = UserSessionService(FakeSecureStorageService());
    await session.saveSession(
      accessToken: 'acesso-1',
      refreshToken: 'renovacao-1',
      email: 'maria@exemplo.com',
      userName: 'Maria da Silva',
    );
    repository = AccountRepositoryImpl(remote, session);
  });

  ApiException apiError(
    ApiErrorType type, {
    int? statusCode,
    String? errorCode,
  }) => ApiException(
    type: type,
    statusCode: statusCode,
    errorCode: errorCode,
    message: 'teste',
  );

  Failure? failureOf<T>(Either<Failure, T> result) =>
      result.fold((failure) => failure, (_) => null);

  Future<Either<Failure, Unit>> change() => repository.changePassword(
    currentPassword: 'Senha@123',
    newPassword: 'NovaSenha@456',
  );

  test('getAccount → Right', () async {
    final result = await repository.getAccount();

    expect(result.getRight().toNullable()!.name, 'Maria da Silva');
  });

  test('setReceiveAlerts repassa o valor', () async {
    final result = await repository.setReceiveAlerts(false);

    expect(result.isRight(), isTrue);
    expect(remote.alertsCalls, [false]);
  });

  group('changePassword', () {
    test('ok → entra de novo com a nova senha e guarda o par novo', () async {
      final result = await change();

      expect(result, const Right<Failure, Unit>(unit));
      expect(remote.loginCalls, [
        (email: 'maria@exemplo.com', password: 'NovaSenha@456'),
      ]);
      expect(session.accessToken, 'acesso-novo');
      expect(session.refreshToken, 'renovacao-nova');
      expect(session.email, 'maria@exemplo.com');
      expect(session.userName, 'Maria da Silva');
      expect(session.isAuthenticated, isTrue);
    });

    test(
      'login depois da troca falha → PasswordChangedReloginFailure',
      () async {
        remote.loginError = apiError(ApiErrorType.connection);

        expect(failureOf(await change()), isA<PasswordChangedReloginFailure>());
      },
    );

    test(
      '401 INVALID_CREDENTIALS → WrongCurrentPasswordFailure, sem login',
      () async {
        remote.changeError = apiError(
          ApiErrorType.unauthorized,
          statusCode: 401,
          errorCode: AccountRepositoryImpl.invalidCredentialsCode,
        );

        expect(failureOf(await change()), isA<WrongCurrentPasswordFailure>());
        expect(remote.loginCalls, isEmpty);
        expect(session.isAuthenticated, isTrue);
        expect(session.accessToken, 'acesso-1');
      },
    );

    test('409 → SamePasswordFailure', () async {
      remote.changeError = apiError(
        ApiErrorType.client,
        statusCode: 409,
        errorCode: AccountRepositoryImpl.samePasswordCode,
      );

      expect(failureOf(await change()), isA<SamePasswordFailure>());
    });

    test('400 VALIDATION_ERROR → ServerFailure', () async {
      remote.changeError = apiError(
        ApiErrorType.client,
        statusCode: 400,
        errorCode: 'VALIDATION_ERROR',
      );

      expect(failureOf(await change()), isA<ServerFailure>());
    });

    test('sem conexão → ConnectionFailure', () async {
      remote.changeError = apiError(ApiErrorType.connection);

      expect(failureOf(await change()), isA<ConnectionFailure>());
    });
  });

  test('getAccount sem conexão → ConnectionFailure', () async {
    remote.accountError = apiError(ApiErrorType.connection);

    expect(failureOf(await repository.getAccount()), isA<ConnectionFailure>());
  });
}
