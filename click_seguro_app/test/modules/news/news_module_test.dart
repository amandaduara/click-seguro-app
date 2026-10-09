import 'package:click_seguro_app/modules/common/services/local_cache_service.dart';
import 'package:click_seguro_app/modules/common/services/user_session_service.dart';
import 'package:click_seguro_app/modules/news/data/datasources/news_local_data_source_impl.dart';
import 'package:click_seguro_app/modules/news/news.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';

import '../../fakes/fake_local_cache_service.dart';
import '../../fakes/fake_secure_storage_service.dart';

void main() {
  late UserSessionService session;
  late FakeLocalCacheService cache;

  setUp(() async {
    session = UserSessionService(FakeSecureStorageService());
    cache = FakeLocalCacheService();
    GetIt.instance
      ..registerSingleton<UserSessionService>(session)
      ..registerSingleton<LocalCacheService>(cache);
    await NewsModule().registerServices(GetIt.instance);
  });

  tearDown(() async => GetIt.instance.reset());

  /// Grava as duas cópias da conta e a do feed, e monta os providers do
  /// módulo (é lá que a limpeza ouve a sessão).
  Future<void> pumpModule(WidgetTester tester) async {
    await session.saveSession(
      accessToken: 'tk',
      refreshToken: 'rf',
      email: 'ana@test.com',
    );
    cache.values
      ..[NewsLocalDataSourceImpl.detailCacheKey] = {
        'owner': 'ana@test.com',
        'items': <Object>[],
      }
      ..[NewsLocalDataSourceImpl.savedCacheKey] = {
        'owner': 'ana@test.com',
        'page': <String, Object>{},
      }
      ..[NewsLocalDataSourceImpl.feedCacheKey] = {'feed': <String, Object>{}};
    await tester.pumpWidget(
      MultiProvider(
        providers: NewsModule().providers(GetIt.instance),
        child: const SizedBox.shrink(),
      ),
    );
  }

  bool hasKey(String key) => cache.values.containsKey(key);

  group('cópias da conta ao sair', () {
    testWidgets('sair da conta apaga detalhes e salvas e preserva o feed', (
      tester,
    ) async {
      await pumpModule(tester);

      await session.logout();
      await tester.pump();

      expect(hasKey(NewsLocalDataSourceImpl.detailCacheKey), isFalse);
      expect(hasKey(NewsLocalDataSourceImpl.savedCacheKey), isFalse);
      expect(hasKey(NewsLocalDataSourceImpl.feedCacheKey), isTrue);
    });

    testWidgets('sessão expirada apaga igualmente', (tester) async {
      await pumpModule(tester);

      await session.expire();
      await tester.pump();

      expect(hasKey(NewsLocalDataSourceImpl.detailCacheKey), isFalse);
      expect(hasKey(NewsLocalDataSourceImpl.savedCacheKey), isFalse);
      expect(hasKey(NewsLocalDataSourceImpl.feedCacheKey), isTrue);
    });

    testWidgets('visitante e conectada não apagam', (tester) async {
      await pumpModule(tester);

      await session.startGuestSession();
      await tester.pump();
      await session.saveSession(
        accessToken: 'tk2',
        refreshToken: 'rf2',
        email: 'ana@test.com',
      );
      await tester.pump();

      expect(hasKey(NewsLocalDataSourceImpl.detailCacheKey), isTrue);
      expect(hasKey(NewsLocalDataSourceImpl.savedCacheKey), isTrue);
      expect(hasKey(NewsLocalDataSourceImpl.feedCacheKey), isTrue);
    });

    testWidgets('descartados os providers, a sessão deixa de apagar', (
      tester,
    ) async {
      await pumpModule(tester);
      await tester.pumpWidget(const SizedBox.shrink());

      await session.logout();
      await tester.pump();

      expect(hasKey(NewsLocalDataSourceImpl.detailCacheKey), isTrue);
    });
  });
}
