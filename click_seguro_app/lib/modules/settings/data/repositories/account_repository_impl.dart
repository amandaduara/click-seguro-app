import 'package:click_seguro_app/core/errors/errors.dart';
import 'package:click_seguro_app/modules/common/api_client/api_client.dart';
import 'package:click_seguro_app/modules/common/api_client/api_failure_mapper.dart';
import 'package:click_seguro_app/modules/common/services/user_session_service.dart';
import 'package:click_seguro_app/modules/settings/data/datasources/account_remote_data_source.dart';
import 'package:click_seguro_app/modules/settings/domain/entities/account_summary_entity.dart';
import 'package:click_seguro_app/modules/settings/domain/failures/settings_failures.dart';
import 'package:click_seguro_app/modules/settings/domain/repositories/account_repository.dart';
import 'package:fpdart/fpdart.dart';

class AccountRepositoryImpl implements AccountRepository {
  AccountRepositoryImpl(this._remote, this._session);

  static const String invalidCredentialsCode = 'INVALID_CREDENTIALS';
  static const String samePasswordCode = 'USER_NEW_PASSWORD_EQUALS_OLD';

  final AccountRemoteDataSource _remote;
  final UserSessionService _session;

  @override
  Future<Either<Failure, AccountSummaryEntity>> getAccount() =>
      _guard(() async => (await _remote.getAccount()).toEntity());

  @override
  Future<Either<Failure, Unit>> setReceiveAlerts(bool value) =>
      _guard(() async {
        await _remote.setReceiveAlerts(value);
        return unit;
      });

  @override
  Future<Either<Failure, Unit>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final changed = await _guard(
      () async {
        await _remote.changePassword(
          currentPassword: currentPassword,
          newPassword: newPassword,
        );
        return unit;
      },
      specific: {
        invalidCredentialsCode: const WrongCurrentPasswordFailure(),
        samePasswordCode: const SamePasswordFailure(),
      },
    );
    if (changed.isLeft()) return changed;
    return _relogin(newPassword);
  }

  /// O serviço recusa o `refreshToken` antigo depois da troca: entra de novo
  /// com a nova senha e guarda o par novo, mantendo e-mail e nome.
  Future<Either<Failure, Unit>> _relogin(String password) async {
    final String? email = _session.email;
    if (email == null) return const Left(PasswordChangedReloginFailure());
    try {
      final tokens = await _remote.login(email: email, password: password);
      await _session.saveSession(
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
        email: email,
        userName: _session.userName,
      );
      return const Right(unit);
    } catch (_) {
      return const Left(PasswordChangedReloginFailure());
    }
  }

  /// [specific]: falha por `errorCode`, antes do mapeamento padrão.
  Future<Either<Failure, T>> _guard<T>(
    Future<T> Function() action, {
    Map<String, Failure> specific = const {},
  }) async {
    try {
      return Right(await action());
    } on ApiException catch (e) {
      return Left(specific[e.errorCode] ?? e.toFailure());
    }
  }
}
