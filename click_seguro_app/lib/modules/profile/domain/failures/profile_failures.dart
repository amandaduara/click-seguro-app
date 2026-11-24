import 'package:click_seguro_app/core/errors/failure.dart';
import 'package:click_seguro_app/core/i18n/app_strings.dart';

/// 409 `USER_EMAIL_ALREADY_EXISTS`: mostrado no campo de e-mail.
class EmailInUseFailure extends Failure {
  const EmailInUseFailure() : super(AppStrings.profileEditErrorEmailInUse);
}

/// 400 `INVALID_IMAGE_TYPE` ao enviar a foto.
class AvatarTypeFailure extends Failure {
  const AvatarTypeFailure() : super(AppStrings.profilePhotoInvalid);
}
