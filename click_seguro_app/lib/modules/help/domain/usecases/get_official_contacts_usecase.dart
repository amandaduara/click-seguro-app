import 'package:click_seguro_app/core/errors/failure.dart';
import 'package:click_seguro_app/modules/help/domain/entities/contact_entity.dart';
import 'package:click_seguro_app/modules/help/domain/repositories/help_repository.dart';
import 'package:fpdart/fpdart.dart';

class GetOfficialContactsUseCase {
  const GetOfficialContactsUseCase(this._repository);

  final HelpRepository _repository;

  Future<Either<Failure, List<ContactEntity>>> call() =>
      _repository.getOfficialContacts();
}
