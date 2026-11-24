import 'package:click_seguro_app/core/errors/failure.dart';
import 'package:click_seguro_app/modules/help/domain/entities/contact_entity.dart';
import 'package:click_seguro_app/modules/help/domain/failures/contact_validation_failure.dart';
import 'package:click_seguro_app/modules/help/domain/repositories/help_repository.dart';
import 'package:click_seguro_app/modules/help/domain/validation/contact_validation.dart';
import 'package:fpdart/fpdart.dart';

class SavePersonalContactUseCase {
  const SavePersonalContactUseCase(this._repository);

  final HelpRepository _repository;

  Future<Either<Failure, ContactEntity>> call(ContactEntity contact) async {
    final nameError = ContactValidation.validateName(contact.name);
    if (nameError != null) return Left(ContactValidationFailure(nameError));

    final phone = ContactValidation.normalizePhone(contact.phone);
    if (phone == null) {
      return Left(ContactValidationFailure(ContactValidationError.phone));
    }

    return _repository.savePersonalContact(
      ContactEntity(
        id: contact.id,
        name: contact.name.trim(),
        phone: phone,
        type: ContactType.personal,
        relationship: _trimOrNull(contact.relationship),
        photoPath: contact.photoPath,
      ),
    );
  }

  String? _trimOrNull(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}
