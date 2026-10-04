import 'package:click_seguro_app/core/errors/errors.dart';
import 'package:click_seguro_app/modules/authentication/data/models/user_model.dart';
import 'package:click_seguro_app/modules/authentication/data/repositories/auth_repository_impl.dart';
import 'package:click_seguro_app/modules/authentication/domain/enums/user_role.dart';
import 'package:click_seguro_app/modules/authentication/domain/failures/auth_failures.dart';
import 'package:click_seguro_app/modules/common/api_client/api_client.dart';
import 'package:click_seguro_app/modules/common/services/user_session_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../fakes/fake_secure_storage_service.dart';
import '../../fakes/fake_auth_remote_data_source.dart';

void main() {
  late FakeAuthRemoteDataSource remote;
  late UserSessionService session;
  late AuthRepositoryImpl repository;

  setUp(() {
    remote = FakeAuthRemoteDataSource();
    session = UserSessionService(FakeSecureStorageService());
    repository = AuthRepositoryImpl(remote, session);
  });

  Future<Object?> loginFailure() async => (await repository.login(
    email: 'maria@exemplo.com',
    password: 'Senha@123',
  )).getLeft().toNullable();

  group('login', () {
    test('sucesso salva a sessão com os dados do /users/me', () async {
      final result = await repository.login(
        email: 'maria@exemplo.com',
        password: 'Senha@123',
      );

      expect(result.getRight().toNullable()?.name, 'Maria Silva');
      expect(remote.calls, ['login', 'getMe']);
      expect(remote.lastMeToken, 'acesso-1');
      expect(session.isAuthenticated, isTrue);
      expect(session.accessToken, 'acesso-1');
      expect(session.refreshToken, 'renovacao-1');
      expect(session.email, 'maria@exemplo.com');
      expect(session.userName, 'Maria Silva');
    });

    test('senha errada vira InvalidCredentialsFailure', () async {
      remote.loginError = apiError(
        ApiErrorType.unauthorized,
        statusCode: 401,
        errorCode: 'INVALID_CREDENTIALS',
      );

      expect(await loginFailure(), isA<InvalidCredentialsFailure>());
      expect(session.isAuthenticated, isFalse);
    });

    for (final role in [UserRole.admin, UserRole.unknown]) {
      test('papel $role não conecta', () async {
        remote.me = UserModel(
          name: 'Admin',
          email: 'admin@exemplo.com',
          role: role,
        );

        expect(await loginFailure(), isA<InvalidCredentialsFailure>());
        expect(session.isAuthenticated, isFalse);
      });
    }

    test('sem conexão vira ConnectionFailure', () async {
      remote.loginError = apiError(ApiErrorType.connection);

      expect(await loginFailure(), isA<ConnectionFailure>());
    });

    test('500 vira ServerFailure', () async {
      remote.loginError = apiError(ApiErrorType.server, statusCode: 500);

      expect(await loginFailure(), isA<ServerFailure>());
    });

    test('falha no /users/me não salva nada', () async {
      remote.getMeError = apiError(ApiErrorType.timeout);

      expect(await loginFailure(), isA<ConnectionFailure>());
      expect(session.isAuthenticated, isFalse);
    });
  });

  group('register', () {
    Future<Object?> registerFailure() async => (await repository.register(
      name: 'Maria Silva',
      email: 'maria@exemplo.com',
      password: 'Senha@123',
    )).getLeft().toNullable();

    test('cadastra, entra e salva a sessão', () async {
      final result = await repository.register(
        name: 'Maria Silva',
        email: 'maria@exemplo.com',
        password: 'Senha@123',
      );

      expect(result.isRight(), isTrue);
      expect(remote.calls, ['register', 'login', 'getMe']);
      expect(session.isAuthenticated, isTrue);
      expect(session.userName, 'Maria Silva');
    });

    test('e-mail duplicado não tenta entrar', () async {
      remote.registerError = apiError(
        ApiErrorType.client,
        statusCode: 409,
        errorCode: 'USER_EMAIL_ALREADY_EXISTS',
      );

      expect(await registerFailure(), isA<EmailAlreadyExistsFailure>());
      expect(remote.calls, ['register']);
    });

    test(
      'conta criada mas login sem rede vira AccountCreatedFailure',
      () async {
        remote.loginError = apiError(ApiErrorType.connection);

        expect(await registerFailure(), isA<AccountCreatedFailure>());
        expect(session.isAuthenticated, isFalse);
      },
    );

    test(
      'conta criada mas papel inválido vira AccountCreatedFailure',
      () async {
        remote.me = const UserModel(
          name: 'Maria Silva',
          email: 'maria@exemplo.com',
          role: UserRole.unknown,
        );

        expect(await registerFailure(), isA<AccountCreatedFailure>());
      },
    );

    test('cadastro sem conexão vira ConnectionFailure', () async {
      remote.registerError = apiError(ApiErrorType.connection);

      expect(await registerFailure(), isA<ConnectionFailure>());
    });
  });

  group('guest', () {
    test('entra como visitante sem chamar o serviço', () async {
      final result = await repository.enterAsGuest();

      expect(result.isRight(), isTrue);
      expect(session.sessionStatus.value, UserSessionStatus.guest);
      expect(remote.calls, isEmpty);
    });
  });

  group('recuperação', () {
    test('os três passos com sucesso', () async {
      expect(
        (await repository.requestPasswordReset('maria@exemplo.com')).isRight(),
        isTrue,
      );
      expect(
        (await repository.verifyResetCode(
          email: 'maria@exemplo.com',
          code: '123456',
        )).isRight(),
        isTrue,
      );
      expect(
        (await repository.resetPassword(
          email: 'maria@exemplo.com',
          code: '123456',
          newPassword: 'Nova@1234',
        )).isRight(),
        isTrue,
      );
      expect(remote.calls, ['forgotPassword', 'verifyCode', 'resetPassword']);
      expect(session.isAuthenticated, isFalse);
    });

    test('código inválido vira InvalidRecoveryCodeFailure', () async {
      remote.verifyError = apiError(
        ApiErrorType.unauthorized,
        statusCode: 401,
        errorCode: 'INVALID_RECOVERY_CODE',
      );

      final result = await repository.verifyResetCode(
        email: 'maria@exemplo.com',
        code: '000000',
      );

      expect(result.getLeft().toNullable(), isA<InvalidRecoveryCodeFailure>());
    });

    test('sem conexão vira ConnectionFailure', () async {
      remote.forgotError = apiError(ApiErrorType.connection);

      final result = await repository.requestPasswordReset('maria@exemplo.com');

      expect(result.getLeft().toNullable(), isA<ConnectionFailure>());
    });
  });
}
