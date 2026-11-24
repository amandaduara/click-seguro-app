import 'package:click_seguro_app/core/errors/failure.dart';
import 'package:click_seguro_app/modules/settings/domain/entities/account_summary_entity.dart';
import 'package:click_seguro_app/modules/settings/domain/repositories/account_repository.dart';
import 'package:fpdart/fpdart.dart';

class GetAccountUseCase {
  GetAccountUseCase(this._repository);

  final AccountRepository _repository;

  Future<Either<Failure, AccountSummaryEntity>> call() =>
      _repository.getAccount();
}
