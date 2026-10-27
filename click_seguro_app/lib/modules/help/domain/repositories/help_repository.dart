import 'package:click_seguro_app/core/errors/failure.dart';
import 'package:click_seguro_app/modules/help/domain/entities/contact_entity.dart';
import 'package:fpdart/fpdart.dart';

abstract class HelpRepository {
  Future<Either<Failure, List<ContactEntity>>> getOfficialContacts();
  Future<Either<Failure, List<ContactEntity>>> getPersonalContacts();
  Future<Either<Failure, ContactEntity>> savePersonalContact(
    ContactEntity contact,
  );
  Future<Either<Failure, Unit>> deletePersonalContact(String id);
}
