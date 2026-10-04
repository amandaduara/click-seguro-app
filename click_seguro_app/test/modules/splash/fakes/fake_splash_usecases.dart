import 'dart:async';

import 'package:click_seguro_app/core/errors/failure.dart';
import 'package:click_seguro_app/modules/common/services/user_session_service.dart';
import 'package:click_seguro_app/modules/onboarding/onboarding.dart';
import 'package:click_seguro_app/modules/splash/domain/usecases/validate_stored_session_usecase.dart';
import 'package:fpdart/fpdart.dart';

class FakeCheckOnboardingSeenUseCase implements CheckOnboardingSeenUseCase {
  FakeCheckOnboardingSeenUseCase({this.result = const Right(true)});

  Either<Failure, bool> result;

  /// Quando informado, segura a resposta até ser completado.
  Completer<Either<Failure, bool>>? completer;

  int calls = 0;

  @override
  Future<Either<Failure, bool>> call() async {
    calls++;
    final pending = completer;
    return pending != null ? pending.future : result;
  }
}

class FakeValidateStoredSessionUseCase implements ValidateStoredSessionUseCase {
  FakeValidateStoredSessionUseCase({
    this.status = UserSessionStatus.authenticated,
  });

  UserSessionStatus status;

  /// Quando informado, segura a resposta até ser completado.
  Completer<UserSessionStatus>? completer;

  int calls = 0;

  @override
  Future<UserSessionStatus> call() async {
    calls++;
    final pending = completer;
    return pending != null ? pending.future : status;
  }
}
