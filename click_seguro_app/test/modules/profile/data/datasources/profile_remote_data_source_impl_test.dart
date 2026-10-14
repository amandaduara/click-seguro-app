import 'dart:io';

import 'package:click_seguro_app/modules/common/api_client/api_client.dart';
import 'package:click_seguro_app/modules/common/services/user_session_service.dart';
import 'package:click_seguro_app/modules/profile/data/datasources/profile_remote_data_source_impl.dart';
import 'package:click_seguro_app/modules/profile/domain/entities/profile_update.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

import '../../../../fakes/fake_secure_storage_service.dart';
import '../../../common/api_client/fake_http_client_adapter.dart';
import '../../fakes/profile_fixtures.dart';

void main() {
  late FakeHttpClientAdapter adapter;
  late ProfileRemoteDataSourceImpl dataSource;

  setUp(() {
    adapter = FakeHttpClientAdapter();
    GetIt.instance.registerSingleton<UserSessionService>(
      UserSessionService(FakeSecureStorageService()),
    );
    dataSource = ProfileRemoteDataSourceImpl(
      ApiClient(
        dio: Dio(BaseOptions(baseUrl: 'https://api.test'))
          ..httpClientAdapter = adapter,
      ),
    );
  });

  tearDown(() => GetIt.instance.reset());

  test('getProfile: GET /users/me', () async {
    adapter.body = profileJson(phone: '+5511912345678');

    final profile = await dataSource.getProfile();

    expect(adapter.lastRequest!.method, 'GET');
    expect(adapter.lastRequest!.path, ProfileRemoteDataSourceImpl.mePath);
    expect(profile.toEntity().phone, '+5511912345678');
  });

  test('getNewsCounts: três GET com limit 1 e os meta.total', () async {
    const totals = {'read': 12, 'saved': 5, 'liked': 9};
    adapter.responder = (options) {
      final String list = options.path.split('/').last;
      return FakeResponse(200, newsCountJson(totals[list]!));
    };

    final counts = await dataSource.getNewsCounts();

    expect(adapter.requests.map((r) => r.path), {
      ProfileRemoteDataSourceImpl.newsListPath('read'),
      ProfileRemoteDataSourceImpl.newsListPath('saved'),
      ProfileRemoteDataSourceImpl.newsListPath('liked'),
    });
    expect(adapter.requests.every((r) => r.method == 'GET'), isTrue);
    expect(
      adapter.requests.every((r) => r.queryParameters['limit'] == 1),
      isTrue,
    );
    expect((counts.read, counts.saved, counts.liked), (12, 5, 9));
  });

  test('getActivityProgress: GET /app/educational/modules', () async {
    adapter.body = modulesJson(
      modules: [moduleJson(id: 'm1', completedCount: 2)],
      totalLessonsCompleted: 2,
    );

    final progress = await dataSource.getActivityProgress();

    expect(adapter.lastRequest!.path, ProfileRemoteDataSourceImpl.modulesPath);
    expect(progress.toEntity().lessonsCompleted, 2);
  });

  group('updateProfile', () {
    test('PATCH /users/me só com os campos preenchidos', () async {
      adapter.statusCode = 204;

      await dataSource.updateProfile(const ProfileUpdate(name: 'Novo Nome'));

      final request = adapter.lastRequest!;
      expect(request.method, 'PATCH');
      expect(request.path, ProfileRemoteDataSourceImpl.mePath);
      expect(request.data, {'name': 'Novo Nome'});
    });

    test('e-mail e telefone juntos', () async {
      adapter.statusCode = 204;

      await dataSource.updateProfile(
        const ProfileUpdate(
          email: 'maria@exemplo.com',
          phone: '+5511912345678',
        ),
      );

      expect(adapter.lastRequest!.data, {
        'email': 'maria@exemplo.com',
        'phone': '+5511912345678',
      });
    });

    test('409 USER_EMAIL_ALREADY_EXISTS sobe como ApiException', () async {
      adapter
        ..statusCode = 409
        ..body = {'code': 'USER_EMAIL_ALREADY_EXISTS', 'message': 'Em uso'};

      await expectLater(
        dataSource.updateProfile(const ProfileUpdate(email: 'a@b.com')),
        throwsA(
          isA<ApiException>().having(
            (e) => e.errorCode,
            'errorCode',
            'USER_EMAIL_ALREADY_EXISTS',
          ),
        ),
      );
    });
  });

  group('uploadAvatar', () {
    late Directory folder;

    setUp(() => folder = Directory.systemTemp.createTempSync('perfil_'));
    tearDown(() => folder.deleteSync(recursive: true));

    String photo(String name) {
      final file = File('${folder.path}${Platform.pathSeparator}$name')
        ..writeAsBytesSync([1, 2, 3]);
      return file.path;
    }

    for (final (name, type) in [
      ('foto.png', 'image/png'),
      ('foto.jpg', 'image/jpeg'),
      ('foto.JPEG', 'image/jpeg'),
      ('foto.webp', 'image/webp'),
    ]) {
      test('$name → multipart avatar com $type', () async {
        adapter.body = {'avatarUrl': 'https://img.test/nova.png'};

        final url = await dataSource.uploadAvatar(photo(name));

        final request = adapter.lastRequest!;
        expect(request.method, 'POST');
        expect(request.path, ProfileRemoteDataSourceImpl.avatarPath);
        final file = (request.data as FormData).files.single;
        expect(file.key, 'avatar');
        expect(file.value.contentType.toString(), type);
        expect(url, 'https://img.test/nova.png');
      });
    }
  });

  test('removeAvatar: DELETE /users/me/avatar', () async {
    adapter.statusCode = 204;

    await dataSource.removeAvatar();

    expect(adapter.lastRequest!.method, 'DELETE');
    expect(adapter.lastRequest!.path, ProfileRemoteDataSourceImpl.avatarPath);
  });
}
