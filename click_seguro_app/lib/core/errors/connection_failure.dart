import 'package:click_seguro_app/core/errors/failure.dart';
import 'package:click_seguro_app/core/i18n/app_strings.dart';

/// Sem internet ou tempo de resposta esgotado.
class ConnectionFailure extends Failure {
  const ConnectionFailure([super.message = AppStrings.errorConnection]);
}
