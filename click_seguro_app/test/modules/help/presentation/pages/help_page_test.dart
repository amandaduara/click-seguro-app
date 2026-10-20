import 'package:click_seguro_app/core/routing/navigator_keys.dart';
import 'package:click_seguro_app/core/theme/app_theme.dart';
import 'package:click_seguro_app/modules/common/services/user_session_service.dart';
import 'package:click_seguro_app/modules/help/domain/entities/contact_entity.dart';
import 'package:click_seguro_app/modules/help/presentation/pages/help_contact_page.dart';
import 'package:click_seguro_app/modules/help/presentation/routes/help_routes.dart';
import 'package:click_seguro_app/modules/shell/presentation/widgets/app_top_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../../fakes/fake_secure_storage_service.dart';
import '../../../../helpers/help_dependencies.dart';
import '../../../../helpers/localized_app.dart';
import '../../../../helpers/notifications_provider.dart';
import '../../fakes/fake_help_repository.dart';
import '../../fakes/help_fakes.dart';

void main() {
  late FakeHelpRepository repository;
  late FakeExternalLauncherService launcher;
  late GoRouter router;

  setUp(() async {
    final session = UserSessionService(FakeSecureStorageService());
    GetIt.instance.registerSingleton<UserSessionService>(session);
    await session.startGuestSession();
    repository = FakeHelpRepository();
    launcher = FakeExternalLauncherService();
    registerHelpDependencies(
      GetIt.instance,
      repository: repository,
      launcher: launcher,
    );
    router = GoRouter(
      navigatorKey: rootNavigatorKey,
      initialLocation: '/help',
      routes: [helpTabRoute],
    );
  });

  tearDown(() async {
    router.dispose();
    await GetIt.instance.reset();
  });

  Future<void> open(WidgetTester tester, {ThemeData? theme}) async {
    await pumpLocalized(
      tester,
      router: router,
      providers: [fakeNotificationsProvider()],
      theme: theme,
    );
  }

  testWidgets('abas oficiais/pessoais, cria, edita e confirma remoção', (
    tester,
  ) async {
    await open(tester);
    expect(find.byType(AppTopBar), findsOneWidget);
    expect(
      find.text('A lista de contatos oficiais ainda não está disponível.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Meus contatos'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Adicionar contato'));
    await tester.pumpAndSettle();
    expect(find.byType(ContactFormPage), findsOneWidget);

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'Ana');
    await tester.enterText(fields.at(1), '(11) 99999-1234');
    await tester.tap(find.text('Salvar contato'));
    await tester.pumpAndSettle();
    expect(repository.personal.single.name, 'Ana');
    expect(find.text('Ana'), findsOneWidget);

    await tester.tap(find.byTooltip('Editar contato'));
    await tester.pumpAndSettle();
    expect(find.text('Editar contato'), findsWidgets);
    Future<void> revealRemoveButton() => tester.scrollUntilVisible(
      find.text('Remover contato'),
      250,
      scrollable: find
          .descendant(
            of: find.byType(ContactFormPage),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await revealRemoveButton();
    await tester.tap(find.text('Remover contato'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(repository.personal, hasLength(1));

    await revealRemoveButton();
    await tester.tap(find.text('Remover contato'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remover').last);
    await tester.pumpAndSettle();
    expect(repository.personal, isEmpty);
  });

  testWidgets('discador indisponível mostra número e copia', (tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    repository.official = [
      const ContactEntity(
        id: '190',
        name: 'Polícia',
        phone: '190',
        type: ContactType.official,
        photoPath: '/missing/contact-photo.jpg',
      ),
    ];
    launcher.canCallResult = false;
    const clipboard = SystemChannels.platform;
    String? copied;
    await open(tester, theme: AppTheme.highContrastTheme);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(clipboard, (call) async {
          if (call.method == 'Clipboard.setData') {
            copied = (call.arguments as Map)['text'] as String?;
          }
          return null;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(clipboard, null),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pumpAndSettle();
    expect(find.text('P'), findsOneWidget);

    await tester.ensureVisible(find.byIcon(Icons.call));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.call));
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: find.byType(AlertDialog), matching: find.text('190')),
      findsOneWidget,
    );
    await tester.ensureVisible(find.text('Copiar número'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Copiar número'));
    await tester.pumpAndSettle();
    expect(copied, '190');
  });
}
