import 'package:click_seguro_app/core/errors/errors.dart';
import 'package:click_seguro_app/modules/common/api_client/api_client.dart';

/// Mapeamento padrão de [ApiException] para [Failure], usado pelos
/// repositories no `catch`. Trate antes os casos específicos da feature
/// (ex.: `statusCode == 409` → `ReportAlreadyExistsFailure`) e use
/// [toFailure] como fallback.
extension ApiFailureMapper on ApiException {
  Failure toFailure() {
    return switch (type) {
      ApiErrorType.connection || ApiErrorType.timeout => const ConnectionFailure(),
      ApiErrorType.unauthorized => const UnauthorizedFailure(),
      _ => const ServerFailure(),
    };
  }
}
