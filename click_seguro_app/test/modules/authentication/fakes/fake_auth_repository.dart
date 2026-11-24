import 'dart:async';

import 'package:click_seguro_app/core/errors/failure.dart';
import 'package:click_seguro_app/modules/authentication/domain/entities/user_entity.dart';
import 'package:click_seguro_app/modules/authentication/domain/enums/user_role.dart';
import 'package:click_seguro_app/modules/authentication/domain/repositories/auth_repository.dart';
import 'package:fpdart/fpdart.dart';

const fakeUser = UserEntity(
  name: 'Maria Silva',
  email: 'maria@exemplo.com',
  role: UserRole.user,
);

/// Repository falso: resultados configuráveis, argumentos e contadores.
/// [gate] permite segurar as respostas para testar o estado "enviando".
class FakeAuthRepository implements AuthRepository {
  Either<Failure, UserEntity> loginResult = const Right(fakeUser);
  Either<Failure, UserEntity> registerResult = const Right(fakeUser);
  Either<Failure, Unit> guestResult = const Right(unit);
  Either<Failure, Unit> requestResetResult = const Right(unit);
  Either<Failure, Unit> verifyCodeResult = const Right(unit);
  Either<Failure, Unit> resetResult = const Right(unit);

  Completer<void>? gate;

  int loginCalls = 0;
  int registerCalls = 0;
  int guestCalls = 0;
  int requestResetCalls = 0;
  int verifyCodeCalls = 0;
  int resetCalls = 0;

  Map<String, String> lastArgs = {};

  Future<T> _answer<T>(T result) async {
    await gate?.future;
    return result;
  }

  @override
  Future<Either<Failure, UserEntity>> login({
    required String email,
    required String password,
  }) {
    loginCalls++;
    lastArgs = {'email': email, 'password': password};
    return _answer(loginResult);
  }

  @override
  Future<Either<Failure, UserEntity>> register({
    required String name,
    required String email,
    required String password,
  }) {
    registerCalls++;
    lastArgs = {'name': name, 'email': email, 'password': password};
    return _answer(registerResult);
  }

  @override
  Future<Either<Failure, Unit>> enterAsGuest() {
    guestCalls++;
    return _answer(guestResult);
  }

  @override
  Future<Either<Failure, Unit>> requestPasswordReset(String email) {
    requestResetCalls++;
    lastArgs = {'email': email};
    return _answer(requestResetResult);
  }

  @override
  Future<Either<Failure, Unit>> verifyResetCode({
    required String email,
    required String code,
  }) {
    verifyCodeCalls++;
    lastArgs = {'email': email, 'code': code};
    return _answer(verifyCodeResult);
  }

  @override
  Future<Either<Failure, Unit>> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) {
    resetCalls++;
    lastArgs = {'email': email, 'code': code, 'newPassword': newPassword};
    return _answer(resetResult);
  }
}
