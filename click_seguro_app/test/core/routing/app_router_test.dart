import 'package:click_seguro_app/core/routing/app_router.dart';
import 'package:click_seguro_app/core/routing/not_found_page.dart';
import 'package:click_seguro_app/modules/activities/activities.dart';
import 'package:click_seguro_app/modules/authentication/authentication.dart';
import 'package:click_seguro_app/modules/common/services/user_session_service.dart';
import 'package:click_seguro_app/modules/help/help.dart';
import 'package:click_seguro_app/modules/news/news.dart';
import 'package:click_seguro_app/modules/notifications/notifications.dart';
import 'package:click_seguro_app/modules/profile/profile.dart';
import 'package:click_seguro_app/modules/settings/settings.dart';
import 'package:click_seguro_app/modules/shell/presentation/widgets/app_bottom_nav.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../fakes/fake_secure_storage_service.dart';
import '../../modules/authentication/fakes/controller_factory.dart';
import '../../modules/authentication/fakes/fake_auth_repository.dart';
import '../../modules/authentication/fakes/forgot_password_controller_factory.dart';
import '../../helpers/localized_app.dart';
import '../../helpers/splash_provider.dart';

void main() {
  late UserSessionService session;
  late GoRouter router;

  setUp(() async {
    session = UserSessionService(FakeSecureStorageService());
    GetIt.instance.registerSingleton<UserSessionService>(session);
    await session.startGuestSession();
    router = buildAppRouter(session);
  });

  tearDown(() => GetIt.instance.reset());

  Future<void> open(WidgetTester tester, String location) async {
    // O login e a recuperação de senha leem os controllers do Provider.
    final repository = FakeAuthRepository();
    await pumpLocalized(
      tester,
      router: router,
      providers: [
        ChangeNotifierProvider(
          create: (_) => buildAuthenticationController(repository),
        ),
        ChangeNotifierProvider(
          create: (_) => buildForgotPasswordController(repository),
        ),
        fakeSplashProvider(session.sessionStatus.value),
      ],
    );
    router.go(location);
    await tester.pumpAndSettle();
  }

  Finder visibleBottomNav() => find.byType(AppBottomNav).hitTestable();

  group('caminhos do plano do produto', () {
    const tabPaths = <String, Type>{
      '/home': NewsHomePage,
      '/activities': ActivitiesPage,
      '/reels': ReelsPage,
      '/reels?start=n1': ReelsPage,
      '/help': HelpPage,
      '/profile': ProfilePage,
    };
    const overlayPaths = <String, Type>{
      '/activities/m1': ActivityModulePage,
      '/help/contact/new': HelpContactPage,
      '/help/contact/c1': HelpContactPage,
      '/profile/edit': ProfileEditPage,
      '/news/n1': NewsDetailPage,
      '/notifications': NotificationsPage,
      '/settings': SettingsPage,
      '/settings/account': SettingsSectionPage,
      '/settings/security': SettingsSectionPage,
      '/settings/accessibility': SettingsSectionPage,
    };

    tabPaths.forEach((path, page) {
      testWidgets('$path abre na aba, com a barra inferior', (tester) async {
        await open(tester, path);

        expect(find.byType(page), findsOneWidget);
        expect(find.byType(NotFoundPage), findsNothing);
        expect(visibleBottomNav(), findsOneWidget);
      });
    });

    overlayPaths.forEach((path, page) {
      testWidgets('$path abre sobre as abas', (tester) async {
        await open(tester, path);

        expect(find.byType(page), findsOneWidget);
        expect(find.byType(NotFoundPage), findsNothing);
        expect(visibleBottomNav(), findsNothing);
      });
    });

    testWidgets('subtelas de configurações têm o próprio título', (
      tester,
    ) async {
      await open(tester, '/settings/account');

      expect(find.text('Dados pessoais'), findsWidgets);
    });

    testWidgets('/help/contact/new não é lido como identificador', (
      tester,
    ) async {
      await open(tester, '/help/contact/new');

      final page = tester.widget<HelpContactPage>(find.byType(HelpContactPage));
      expect(page.contactId, isNull);
    });
  });

  group('página não encontrada', () {
    testWidgets('caminho desconhecido mostra a página e volta ao Início', (
      tester,
    ) async {
      await open(tester, '/nao-existe');

      expect(find.text('Página não encontrada'), findsOneWidget);

      await tester.tap(find.text('Voltar ao Início'));
      await tester.pumpAndSettle();

      expect(find.byType(NewsHomePage), findsOneWidget);
    });
  });
}
