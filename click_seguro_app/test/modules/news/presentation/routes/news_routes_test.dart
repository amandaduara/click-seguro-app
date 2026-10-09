import 'package:click_seguro_app/core/routing/navigator_keys.dart';
import 'package:click_seguro_app/modules/common/services/user_session_service.dart';
import 'package:click_seguro_app/modules/news/presentation/pages/news_detail_page.dart';
import 'package:click_seguro_app/modules/news/presentation/pages/saved_news_page.dart';
import 'package:click_seguro_app/modules/news/presentation/routes/news_routes.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../../fakes/fake_secure_storage_service.dart';
import '../../../../helpers/localized_app.dart';
import '../../../../helpers/news_detail_dependencies.dart';

void main() {
  late UserSessionService session;

  setUp(() async {
    session = UserSessionService(FakeSecureStorageService());
    GetIt.instance.registerSingleton<UserSessionService>(session);
    registerNewsDetailDependencies(GetIt.instance);
    await session.startGuestSession();
  });

  tearDown(() async => GetIt.instance.reset());

  Future<void> open(WidgetTester tester, String location) async {
    final router = GoRouter(
      navigatorKey: rootNavigatorKey,
      initialLocation: location,
      routes: newsRoutes,
    );
    await pumpLocalized(tester, router: router);
  }

  testWidgets('/news/saved abre as salvas e não o detalhe (R1)', (
    tester,
  ) async {
    await open(tester, '/news/saved');

    expect(find.byType(SavedNewsPage), findsOneWidget);
    expect(find.byType(NewsDetailPage), findsNothing);
  });

  testWidgets('/news/abc abre o detalhe de abc', (tester) async {
    await open(tester, '/news/abc');

    final page = tester.widget<NewsDetailPage>(find.byType(NewsDetailPage));
    expect(page.newsId, 'abc');
    expect(find.byType(SavedNewsPage), findsNothing);
  });
}
