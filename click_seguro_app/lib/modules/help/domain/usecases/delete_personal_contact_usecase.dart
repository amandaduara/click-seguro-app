import 'package:click_seguro_app/core/errors/failure.dart';
import 'package:click_seguro_app/modules/help/domain/repositories/help_repository.dart';
import 'package:fpdart/fpdart.dart';

class DeletePersonalContactUseCase {
  const DeletePersonalContactUseCase(this._repository);

  final HelpRepository _repository;

  Future<Either<Failure, Unit>> call(String id) =>
      _repository.deletePersonalContact(id);
}
