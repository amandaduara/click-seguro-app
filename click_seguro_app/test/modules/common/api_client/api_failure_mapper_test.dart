import 'package:click_seguro_app/core/errors/errors.dart';
import 'package:click_seguro_app/modules/common/api_client/api_client.dart';
import 'package:click_seguro_app/modules/common/api_client/api_failure_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Failure map(ApiErrorType type) =>
      ApiException(type: type, message: '').toFailure();

  test('connection e timeout viram ConnectionFailure', () {
    expect(map(ApiErrorType.connection), isA<ConnectionFailure>());
    expect(map(ApiErrorType.timeout), isA<ConnectionFailure>());
  });

  test('unauthorized vira UnauthorizedFailure', () {
    expect(map(ApiErrorType.unauthorized), isA<UnauthorizedFailure>());
  });

  test('demais tipos viram ServerFailure', () {
    for (final type in [
      ApiErrorType.client,
      ApiErrorType.server,
      ApiErrorType.invalidResponse,
      ApiErrorType.cancelled,
      ApiErrorType.unknown,
    ]) {
      expect(map(type), isA<ServerFailure>(), reason: type.name);
    }
  });
}
