import 'package:click_seguro_app/core/routing/navigator_keys.dart';
import 'package:click_seguro_app/core/errors/cache_failure.dart';
import 'package:click_seguro_app/core/theme/app_theme.dart';
import 'package:click_seguro_app/modules/common/services/user_session_service.dart';
import 'package:click_seguro_app/modules/common/services/image_storage_service.dart';
import 'package:click_seguro_app/modules/help/domain/entities/contact_entity.dart';
import 'package:click_seguro_app/modules/help/presentation/pages/contact_form_page.dart';
import 'package:click_seguro_app/modules/help/presentation/routes/help_routes.dart';
import 'package:click_seguro_app/modules/shell/presentation/widgets/app_top_bar.dart';
import 'package:click_seguro_app/core/widgets/safe_card.dart';
import 'package:click_seguro_app/core/widgets/safe_empty_state.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../../fakes/fake_secure_storage_service.dart';
import '../../../../helpers/help_dependencies.dart';
import '../../../../helpers/localized_app.dart';
import '../../../../helpers/notifications_provider.dart';
import '../../fakes/fake_help_repository.dart';
import '../../../../fakes/fake_external_launcher_service.dart';
import '../../../../fakes/fake_image_storage_service.dart';

void main() {
  late FakeHelpRepository repository;
  late FakeExternalLauncherService launcher;
  late FakeImageStorageService images;
  late GoRouter router;

  setUp(() async {
    final session = UserSessionService(FakeSecureStorageService());
    GetIt.instance.registerSingleton<UserSessionService>(session);
    await session.startGuestSession();
    repository = FakeHelpRepository();
    launcher = FakeExternalLauncherService();
    images = FakeImageStorageService();
    registerHelpDependencies(
      GetIt.instance,
      repository: repository,
      launcher: launcher,
      images: images,
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
    // Tela de celular (como os quadros do Figma), a não ser que o teste já
    // tenha escolhido outra: com o cartão de emergência no topo, a tela
    // padrão de 800×600 deixa as listas abaixo da dobra.
    if (tester.view.physicalSize == const Size(2400, 1800)) {
      tester.view.physicalSize = const Size(1170, 2532);
      addTearDown(tester.view.resetPhysicalSize);
    }
    await pumpLocalized(
      tester,
      router: router,
      providers: [fakeNotificationsProvider()],
      theme: theme,
    );
  }

  // Validação da usuária (specs/023): a rolagem termina no fim da lista,
  // sem uma área vazia enorme embaixo quando há poucos contatos.
  testWidgets('a rolagem para no fim da lista, sem tela vazia', (tester) async {
    repository.official = [
      for (int i = 0; i < 6; i++)
        ContactEntity(
          id: 'o$i',
          name: 'Contato $i',
          phone: '19$i',
          type: ContactType.official,
        ),
    ];
    await open(tester);
    // A lista carrega fora do relógio de teste, como no teste do discador.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Contato 0'), findsOneWidget);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -5000));
    await tester.pumpAndSettle();

    final ScrollPosition position = tester
        .state<ScrollableState>(find.byType(Scrollable).first)
        .position;
    final RenderBox lastCard = tester.renderObject(find.byType(SafeCard).last);
    final double lastBottom =
        lastCard.localToGlobal(Offset.zero).dy + lastCard.size.height;
    final double viewportBottom = tester
        .getBottomLeft(find.byType(CustomScrollView))
        .dy;
    // Ou a lista cabe e nem rola, ou o último cartão fica no pé da tela
    // (mais a margem), não lá em cima com vazio embaixo.
    expect(
      position.maxScrollExtent == 0 || viewportBottom - lastBottom < 80,
      isTrue,
      reason: 'sobra ${viewportBottom - lastBottom} abaixo do último cartão',
    );
  });

  // As duas abas rolam do mesmo jeito: "Meus contatos" vazio não ganha uma
  // rolagem própria nem espaço da tela inteira (validação da usuária).
  testWidgets('"Meus contatos" vazio: aviso curto, sem rolar demais', (
    tester,
  ) async {
    await open(tester);
    await tester.tap(find.text('Meus contatos'));
    await tester.pumpAndSettle();

    // Texto do tamanho do corpo da tela, sem a ilustração grande.
    expect(find.byType(SafeEmptyState), findsNothing);
    final Text note = tester.widget<Text>(
      find.text(
        'Cadastre contatos de confiança para encontrá-los rapidamente.',
      ),
    );
    expect(note.style?.fontSize, 16);
    // O fim da rolagem é o fim do conteúdo, sem uma tela extra embaixo.
    final ScrollPosition outer = tester
        .state<ScrollableState>(find.byType(Scrollable).first)
        .position;
    expect(outer.maxScrollExtent, lessThan(200));
  });

  testWidgets('"Adicionar contato" no canto de baixo à esquerda, só nos '
      'pessoais', (tester) async {
    await open(tester);
    expect(find.byKey(const ValueKey('help_add_contact')), findsNothing);

    await tester.tap(find.text('Meus contatos'));
    await tester.pumpAndSettle();

    final Finder button = find.byKey(const ValueKey('help_add_contact'));
    expect(button, findsOneWidget);
    final Size screen = tester.getSize(find.byType(Scaffold).first);
    final Rect rect = tester.getRect(button);
    expect(rect.center.dx, lessThan(screen.width / 2));
    expect(rect.bottom, greaterThan(screen.height * 0.8));
    expect(rect.height, greaterThanOrEqualTo(48));
  });

  // Máscara e validação em tempo real (validação da usuária, specs/023).
  testWidgets('formulário: máscara no telefone e erro que acompanha', (
    tester,
  ) async {
    await open(tester);
    await tester.tap(find.text('Meus contatos'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('help_add_contact')));
    await tester.pumpAndSettle();
    final Finder phone = find.byType(TextField).at(1);

    await tester.enterText(phone, '11912345678');
    await tester.pump();
    expect(find.text('(11) 91234-5678'), findsOneWidget);

    await tester.enterText(phone, '11');
    await tester.pump();
    expect(find.textContaining('Informe um telefone válido'), findsNothing);
    // Sai do campo: o erro aparece e acompanha a digitação.
    await tester.tap(find.byType(TextField).at(2));
    await tester.pump();
    expect(find.textContaining('Informe um telefone válido'), findsOneWidget);
    await tester.enterText(phone, '190');
    await tester.pump();
    expect(find.textContaining('Informe um telefone válido'), findsNothing);

    // O nome não aceita espaço no começo.
    await tester.enterText(find.byType(TextField).at(0), '  Ana');
    await tester.pump();
    expect(find.text('Ana'), findsOneWidget);
  });

  group('cartão "Caiu em um golpe?" (FR-016 de specs/023)', () {
    testWidgets('fica no topo, com título, texto e botão', (tester) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      await open(tester);

      expect(find.text('Caiu em um golpe?'), findsOneWidget);
      expect(
        find.text('Ligue agora para a polícia e para o seu banco.'),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel('Ligar para 190'), findsOneWidget);
      final double card = tester.getTopLeft(find.text('Caiu em um golpe?')).dy;
      final double tabs = tester.getTopLeft(find.text('Oficiais')).dy;
      expect(card, lessThan(tabs));
      semantics.dispose();
    });

    testWidgets('"Ligar para 190" abre o discador com 190', (tester) async {
      await open(tester);

      await tester.tap(find.text('Ligar para 190'));
      await tester.pumpAndSettle();

      expect(launcher.calledNumbers, ['190']);
    });

    testWidgets('sem discador, mostra o número para copiar', (tester) async {
      launcher.canCallResult = false;
      await open(tester);

      await tester.tap(find.text('Ligar para 190'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('190'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('em inglês, o texto traduzido e o mesmo 190', (tester) async {
      await pumpLocalized(
        tester,
        router: router,
        providers: [fakeNotificationsProvider()],
        locale: const Locale('en', 'US'),
      );

      expect(find.text('Fell for a scam?'), findsOneWidget);
      expect(find.text('Call 190'), findsOneWidget);
    });
  });

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
    // Com o cartão de emergência no topo, o botão pode ficar abaixo da dobra.
    await tester.ensureVisible(find.text('Adicionar contato').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Adicionar contato').last);
    await tester.pumpAndSettle();
    expect(find.byType(ContactFormPage), findsOneWidget);

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'Ana');
    await tester.enterText(fields.at(1), '(11) 99999-1234');
    // O formulário ficou mais alto (campos de 60): rola até o botão.
    await tester.ensureVisible(find.text('Salvar contato'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salvar contato'));
    await tester.pumpAndSettle();
    expect(repository.personal.single.name, 'Ana');
    expect(find.text('Ana'), findsOneWidget);

    await tester.tap(find.byTooltip('Editar contato'));
    await tester.pumpAndSettle();
    expect(find.text('Editar contato'), findsWidgets);
    expect(
      tester.widget<TextField>(find.byType(TextField).first).controller?.text,
      'Ana',
    );
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
    // Letra em 200%: o topo (com o cartão de emergência) é alto; rola até
    // o contato.
    await tester.dragUntilVisible(
      find.text('P'),
      find.byType(CustomScrollView),
      const Offset(0, -200),
    );
    await tester.pumpAndSettle();
    expect(find.text('P'), findsOneWidget);

    // O último telefone é o do contato (o primeiro é o do cartão de
    // emergência, na mesma rolagem).
    await tester.ensureVisible(find.byIcon(LucideIcons.phone).last);
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(LucideIcons.phone).last);
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

  testWidgets('erro na lista pode ser repetido e recuperar', (tester) async {
    repository.readFailure = const CacheFailure();
    await open(tester);
    expect(
      find.text('Falha ao acessar o armazenamento local.'),
      findsOneWidget,
    );

    repository
      ..readFailure = null
      ..official = [];
    // O erro tem a altura natural, abaixo do topo: rola até o botão.
    await tester.ensureVisible(find.text('Tentar novamente'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tentar novamente'));
    await tester.pumpAndSettle();
    expect(
      find.text('A lista de contatos oficiais ainda não está disponível.'),
      findsOneWidget,
    );
  });

  testWidgets('formulário mostra erro de validação e permissão negada', (
    tester,
  ) async {
    await open(tester);
    await tester.tap(find.text('Meus contatos'));
    await tester.pumpAndSettle();
    // Com o cartão de emergência no topo, o botão pode ficar abaixo da dobra.
    await tester.ensureVisible(find.text('Adicionar contato').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Adicionar contato').last);
    await tester.pumpAndSettle();
    // O formulário ficou mais alto (campos de 60): rola até o botão.
    await tester.ensureVisible(find.text('Salvar contato'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salvar contato'));
    await tester.pumpAndSettle();
    expect(find.text('Informe o nome do contato.'), findsOneWidget);

    await tester.enterText(find.byType(TextField).at(0), 'Ana');
    await tester.enterText(find.byType(TextField).at(1), '12');
    // O formulário ficou mais alto (campos de 60): rola até o botão.
    await tester.ensureVisible(find.text('Salvar contato'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salvar contato'));
    await tester.pumpAndSettle();
    expect(
      find.text('Informe um telefone válido, como (11) 91234-5678 ou 190.'),
      findsOneWidget,
    );

    images.nextResult = const PickImagePermissionDenied();
    await tester.tap(find.text('Escolher foto'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Galeria'));
    await tester.pumpAndSettle();
    expect(find.text('Sem acesso às fotos'), findsOneWidget);
  });

  testWidgets('edição trata falha de carga e contato ausente', (tester) async {
    repository.readFailure = const CacheFailure();
    await open(tester);
    router.go('/help/contact/p1');
    await tester.pumpAndSettle();
    expect(
      find.text('Falha ao acessar o armazenamento local.'),
      findsOneWidget,
    );

    repository.readFailure = null;
    await tester.tap(find.text('Tentar novamente'));
    await tester.pumpAndSettle();
    expect(find.text('Este contato não está mais disponível.'), findsOneWidget);
  });
}
