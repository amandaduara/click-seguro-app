import 'package:click_seguro_app/core/errors/errors.dart';
import 'package:click_seguro_app/modules/common/api_client/api_client.dart';
import 'package:click_seguro_app/modules/profile/data/repositories/profile_repository_impl.dart';
import 'package:click_seguro_app/modules/profile/domain/entities/profile_update.dart';
import 'package:click_seguro_app/modules/profile/domain/failures/profile_failures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../fakes/fake_profile_remote_data_source.dart';

void main() {
  late FakeProfileRemoteDataSource remote;
  late ProfileRepositoryImpl repository;

  setUp(() {
    remote = FakeProfileRemoteDataSource();
    repository = ProfileRepositoryImpl(remote);
  });

  ApiException apiError(
    ApiErrorType type, {
    int? statusCode,
    String? errorCode,
  }) => ApiException(
    type: type,
    statusCode: statusCode,
    errorCode: errorCode,
    message: 'teste',
  );

  Failure? failureOf<T>(Either<Failure, T> result) =>
      result.fold((failure) => failure, (_) => null);

  group('sucesso → Right', () {
    test('getProfile', () async {
      final result = await repository.getProfile();

      expect(result.getRight().toNullable()!.name, 'Maria da Silva');
    });

    test('getNewsCounts', () async {
      final result = await repository.getNewsCounts();

      expect(result.getRight().toNullable()!.read, remote.counts.read);
    });

    test('getActivityProgress', () async {
      final result = await repository.getActivityProgress();

      expect(result.isRight(), isTrue);
    });

    test('updateProfile repassa o pedido', () async {
      const update = ProfileUpdate(name: 'Novo Nome');

      final result = await repository.updateProfile(update);

      expect(result, const Right<Failure, Unit>(unit));
      expect(remote.updates, [update]);
    });

    test('uploadAvatar devolve a nova URL', () async {
      final result = await repository.uploadAvatar('/tmp/foto.png');

      expect(result.getRight().toNullable(), remote.avatarUrl);
      expect(remote.uploadedPaths, ['/tmp/foto.png']);
    });

    test('removeAvatar', () async {
      final result = await repository.removeAvatar();

      expect(result.isRight(), isTrue);
      expect(remote.removeCalls, 1);
    });
  });

  group('falhas', () {
    test('409 USER_EMAIL_ALREADY_EXISTS → EmailInUseFailure', () async {
      remote.error = apiError(
        ApiErrorType.client,
        statusCode: 409,
        errorCode: ProfileRepositoryImpl.emailInUseCode,
      );

      final result = await repository.updateProfile(
        const ProfileUpdate(email: 'ja@exemplo.com'),
      );

      expect(failureOf(result), isA<EmailInUseFailure>());
    });

    test('400 VALIDATION_ERROR → ServerFailure', () async {
      remote.error = apiError(
        ApiErrorType.client,
        statusCode: 400,
        errorCode: 'VALIDATION_ERROR',
      );

      final result = await repository.updateProfile(
        const ProfileUpdate(name: 'Ana'),
      );

      expect(failureOf(result), isA<ServerFailure>());
    });

    test(
      '400 INVALID_IMAGE_TYPE no envio da foto → AvatarTypeFailure',
      () async {
        remote.error = apiError(
          ApiErrorType.client,
          statusCode: 400,
          errorCode: ProfileRepositoryImpl.invalidImageCode,
        );

        final result = await repository.uploadAvatar('/tmp/foto.txt');

        expect(failureOf(result), isA<AvatarTypeFailure>());
      },
    );

    test('500 (bug do e-mail, R0) → ServerFailure', () async {
      remote.error = apiError(ApiErrorType.server, statusCode: 500);

      final result = await repository.updateProfile(
        const ProfileUpdate(email: 'novo@exemplo.com'),
      );

      expect(failureOf(result), isA<ServerFailure>());
    });

    test('sem conexão → ConnectionFailure', () async {
      remote.error = apiError(ApiErrorType.connection);

      expect(
        failureOf(await repository.getProfile()),
        isA<ConnectionFailure>(),
      );
      expect(
        failureOf(await repository.getNewsCounts()),
        isA<ConnectionFailure>(),
      );
    });

    test('não autorizado → UnauthorizedFailure', () async {
      remote.error = apiError(ApiErrorType.unauthorized, statusCode: 401);

      expect(
        failureOf(await repository.getActivityProgress()),
        isA<UnauthorizedFailure>(),
      );
    });

    test(
      'código de foto inválida fora do envio não vira AvatarTypeFailure',
      () async {
        remote.error = apiError(
          ApiErrorType.client,
          statusCode: 400,
          errorCode: ProfileRepositoryImpl.invalidImageCode,
        );

        expect(
          failureOf(await repository.removeAvatar()),
          isA<ServerFailure>(),
        );
      },
    );
  });
}
