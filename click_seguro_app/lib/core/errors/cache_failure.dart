import 'package:click_seguro_app/core/errors/failure.dart';
import 'package:click_seguro_app/core/i18n/app_strings.dart';

class CacheFailure extends Failure {
  const CacheFailure([super.message = AppStrings.errorCache]);
}
