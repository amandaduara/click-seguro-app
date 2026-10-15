import 'package:click_seguro_app/core/errors/failure.dart';
import 'package:click_seguro_app/modules/settings/domain/entities/account_summary_entity.dart';

/// Carga da conta nas Configurações (cartão e chave de alertas).
sealed class AccountState {
  const AccountState();
}

final class AccountLoading extends AccountState {
  const AccountLoading();
}

final class AccountLoaded extends AccountState {
  const AccountLoaded(this.account);

  final AccountSummaryEntity account;
}

final class AccountFailed extends AccountState {
  const AccountFailed(this.failure);

  final Failure failure;
}
