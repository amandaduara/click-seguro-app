import 'package:click_seguro_app/core/routing/app_router.dart';
import 'package:click_seguro_app/main.dart';
import 'package:click_seguro_app/modules/activities/activities.dart';
import 'package:click_seguro_app/modules/common/common.dart';
import 'package:click_seguro_app/modules/common/services/secure_storage_service.dart';
import 'package:click_seguro_app/modules/common/services/user_session_service.dart';
import 'package:click_seguro_app/modules/help/help.dart';
import 'package:click_seguro_app/modules/news/domain/repositories/news_repository.dart';
import 'package:click_seguro_app/modules/news/news.dart';
import 'package:click_seguro_app/modules/profile/profile.dart';
import 'package:click_seguro_app/modules/shell/presentation/widgets/app_bottom_nav.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes/fake_secure_storage_service.dart';
import 'modules/news/fakes/fake_news_repository.dart';

/// Teste de fumaça (F0.11): sobe o app real, com os módulos do `main.dart`,
/// como visitante e sem plataforma, e passa pelas cinco abas.
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({'onboarding_seen': true});
    EasyLocalization.logger.enableBuildModes = [];
  });

  tearDown(() async {
    await GetIt.instance.reset();
    GetIt.instance.allowReassignment = false;
  });

  testWidgets('abre como visitante e navega pelas cinco abas', (tester) async {
    final ModuleManagerInterface moduleManager = ModuleManager();
    late UserSessionService session;

    await tester.runAsync(() async {
      await EasyLocalization.ensureInitialized();
      await moduleManager.registerModules(appModules());
      // Antes de qualquer resolução: os registros do CommonModule são lazy.
      GetIt.instance.allowReassignment = true;
      GetIt.instance.registerSingleton<SecureStorageService>(
        FakeSecureStorageService({
          UserSessionService.storageKey: '{"status":"guest"}',
        }),
      );
      // O Início carrega o feed: sem rede no teste (constituição, Seção III).
      GetIt.instance.registerSingleton<NewsRepository>(FakeNewsRepository());
      session = GetIt.instance<UserSessionService>();
      await session.restoreSession();
    });

    // Montado fora do runAsync, para que o tempo mínimo do splash use o
    // relógio falso; só a carga das traduções precisa de tempo real.
    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('pt', 'BR'), Locale('en', 'US')],
        path: 'assets/translations',
        fallbackLocale: const Locale('pt', 'BR'),
        startLocale: const Locale('pt', 'BR'),
        child: ClickSeguroApp(
          moduleManager: moduleManager,
          router: buildAppRouter(session),
        ),
      ),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();

    // Splash: tempo mínimo no relógio falso.
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(find.byType(NewsHomePage), findsOneWidget);
    expect(find.text('Bem-vindo!'), findsOneWidget);

    Future<void> tapTab(String label) async {
      await tester.tap(
        find.descendant(
          of: find.byType(AppBottomNav),
          matching: find.bySemanticsLabel(label),
        ),
      );
      await tester.pumpAndSettle();
    }

    await tapTab('Atividades');
    expect(find.byType(ActivitiesPage), findsOneWidget);

    await tapTab('Notícias');
    expect(find.byType(ReelsPage), findsOneWidget);

    await tapTab('Ajuda');
    expect(find.byType(HelpPage), findsOneWidget);

    await tapTab('Perfil');
    expect(find.byType(ProfilePage), findsOneWidget);

    await tapTab('Início');
    expect(find.byType(NewsHomePage), findsOneWidget);
  });
}
