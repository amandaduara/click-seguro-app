import 'package:click_seguro_app/core/errors/failure.dart';
import 'package:click_seguro_app/modules/authentication/domain/entities/user_entity.dart';
import 'package:fpdart/fpdart.dart';

abstract class AuthRepository {
  /// Entra e salva a sessão conectada (FR-007).
  Future<Either<Failure, UserEntity>> login({
    required String email,
    required String password,
  });

  /// Cadastra, entra com a conta nova e salva a sessão (FR-008).
  Future<Either<Failure, UserEntity>> register({
    required String name,
    required String email,
    required String password,
  });

  Future<Either<Failure, Unit>> enterAsGuest();

  Future<Either<Failure, Unit>> requestPasswordReset(String email);

  Future<Either<Failure, Unit>> verifyResetCode({
    required String email,
    required String code,
  });

  Future<Either<Failure, Unit>> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  });
}
