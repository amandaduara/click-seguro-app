import 'package:click_seguro_app/core/errors/failure.dart';
import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:click_seguro_app/modules/help/domain/validation/contact_validation.dart';

class ContactValidationFailure extends Failure {
  ContactValidationFailure(this.error)
    : super(
        error == ContactValidationError.name
            ? AppStrings.helpNameRequired
            : AppStrings.helpPhoneInvalid,
      );

  final ContactValidationError error;
}
