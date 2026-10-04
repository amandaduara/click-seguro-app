import 'package:click_seguro_app/core/errors/errors.dart';
import 'package:click_seguro_app/modules/authentication/data/datasources/auth_remote_data_source.dart';
import 'package:click_seguro_app/modules/authentication/domain/entities/user_entity.dart';
import 'package:click_seguro_app/modules/authentication/domain/enums/user_role.dart';
import 'package:click_seguro_app/modules/authentication/domain/failures/auth_failures.dart';
import 'package:click_seguro_app/modules/authentication/domain/repositories/auth_repository.dart';
import 'package:click_seguro_app/modules/common/api_client/api_client.dart';
import 'package:click_seguro_app/modules/common/api_client/api_error_codes.dart';
import 'package:click_seguro_app/modules/common/api_client/api_failure_mapper.dart';
import 'package:click_seguro_app/modules/common/services/user_session_service.dart';
import 'package:fpdart/fpdart.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._remote, this._session);

  final AuthRemoteDataSource _remote;
  final UserSessionService _session;

  @override
  Future<Either<Failure, UserEntity>> login({
    required String email,
    required String password,
  }) async {
    try {
      return await _signIn(email: email, password: password);
    } on ApiException catch (e) {
      return Left(_mapSignInError(e));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> register({
    required String name,
    required String email,
    required String password,
  }) async => const Left(ServerFailure());

  @override
  Future<Either<Failure, Unit>> enterAsGuest() async =>
      const Left(ServerFailure());

  @override
  Future<Either<Failure, Unit>> requestPasswordReset(String email) async =>
      const Left(ServerFailure());

  @override
  Future<Either<Failure, Unit>> verifyResetCode({
    required String email,
    required String code,
  }) async => const Left(ServerFailure());

  @override
  Future<Either<Failure, Unit>> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async => const Left(ServerFailure());

  /// login → `/users/me` com o token novo → papel de usuário do app? →
  /// salva a sessão. Lança [ApiException].
  Future<Either<Failure, UserEntity>> _signIn({
    required String email,
    required String password,
  }) async {
    final tokens = await _remote.login(email: email, password: password);
    final user = (await _remote.getMe(tokens.accessToken)).toEntity();
    if (user.role != UserRole.user) {
      return const Left(InvalidCredentialsFailure());
    }

    await _session.saveSession(
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
      email: user.email,
      userName: user.name,
    );
    return Right(user);
  }

  Failure _mapSignInError(ApiException e) =>
      e.errorCode == ApiErrorCodes.invalidCredentials
      ? const InvalidCredentialsFailure()
      : e.toFailure();
}
