import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/theme/app_theme.dart';
import 'package:click_seguro_app/modules/common/services/user_session_service.dart';
import 'package:click_seguro_app/modules/notifications/presentation/controller/notifications_controller.dart';
import 'package:click_seguro_app/modules/notifications/presentation/widgets/notification_bell_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../../../../fakes/fake_secure_storage_service.dart';
import '../../../../helpers/localized_app.dart';
import '../../fakes/alerts_fixtures.dart';
import '../../fakes/fake_notifications_repository.dart';
import '../../fakes/notifications_controller_factory.dart';

void main() {
  late UserSessionService session;
  late FakeNotificationsRepository repository;
  late NotificationsController controller;
  var taps = 0;

  setUp(() async {
    taps = 0;
    session = UserSessionService(FakeSecureStorageService());
    await session.saveSession(
      accessToken: 'tk',
      refreshToken: 'rf',
      email: 'ana@test.com',
    );
    repository = FakeNotificationsRepository();
  });

  tearDown(() => controller.dispose());

  /// O controller nasce no corpo do teste: criado no `setUp`, a fila de
  /// gravações fica fora do relógio falso e `load()` não termina.
  Future<void> pumpBell(WidgetTester tester) async {
    controller = buildNotificationsController(repository, session);
    await controller.load();
    await pumpLocalized(
      tester,
      child: Scaffold(
        body: Center(child: NotificationBellButton(onPressed: () => taps++)),
      ),
      providers: [
        ChangeNotifierProvider<NotificationsController>.value(
          value: controller,
        ),
      ],
    );
  }

  final Finder badge = find.byKey(NotificationBellButton.badgeKey);

  testWidgets('sem não lidos: só o sino, rótulo "Alertas"', (tester) async {
    repository.stored = snapshot(alerts: [alert(isRead: true)]);

    await pumpBell(tester);

    expect(badge, findsNothing);
    expect(find.bySemanticsLabel('Alertas'), findsOneWidget);
  });

  testWidgets('3 não lidos: círculo com "3" e rótulo "Alertas, 3 novos"', (
    tester,
  ) async {
    repository.stored = snapshot(
      alerts: [
        alert(newsId: 'a'),
        alert(newsId: 'b'),
        alert(newsId: 'c'),
        alert(newsId: 'd', isRead: true),
      ],
    );

    await pumpBell(tester);

    expect(badge, findsOneWidget);
    final Size size = tester.getSize(badge);
    expect(size.width, greaterThanOrEqualTo(24));
    expect(size.height, greaterThanOrEqualTo(24));
    final Text number = tester.widget<Text>(
      find.descendant(of: badge, matching: find.text('3')),
    );
    expect(number.style?.fontWeight, FontWeight.bold);
    expect(number.style?.fontSize, greaterThan(10));
    expect(find.bySemanticsLabel('Alertas, 3 novos'), findsOneWidget);
  });

  testWidgets('1 não lido: "Alertas, 1 novo"', (tester) async {
    repository.stored = snapshot(alerts: [alert()]);

    await pumpBell(tester);

    expect(find.bySemanticsLabel('Alertas, 1 novo'), findsOneWidget);
  });

  testWidgets('o número acompanha o controller', (tester) async {
    repository.stored = snapshot(
      alerts: [
        alert(newsId: 'a'),
        alert(newsId: 'b'),
      ],
    );
    await pumpBell(tester);
    expect(
      find.descendant(of: badge, matching: find.text('2')),
      findsOneWidget,
    );

    await controller.markAsRead('a');
    await tester.pump();
    expect(
      find.descendant(of: badge, matching: find.text('1')),
      findsOneWidget,
    );

    await controller.markAsRead('b');
    await tester.pump();
    expect(badge, findsNothing);
  });

  testWidgets('tocar chama onPressed', (tester) async {
    await pumpBell(tester);

    await tester.tap(find.bySemanticsLabel('Alertas'));

    expect(taps, 1);
  });

  testWidgets('área de toque de pelo menos 48×48, com ou sem contador', (
    tester,
  ) async {
    repository.stored = snapshot(alerts: [alert()]);
    await pumpBell(tester);

    final Size size = tester.getSize(find.bySemanticsLabel('Alertas, 1 novo'));
    expect(size.width, greaterThanOrEqualTo(48));
    expect(size.height, greaterThanOrEqualTo(48));
  });

  group('acessibilidade (FR-020, SC-008)', () {
    testWidgets('fonte 2×: contador legível, sem estouro e dentro do sino', (
      tester,
    ) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2.0;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      repository.stored = snapshot(
        alerts: [for (var i = 0; i < 120; i++) alert(newsId: 'n$i')],
      );

      await pumpBell(tester);

      expect(tester.takeException(), isNull);
      expect(
        find.descendant(of: badge, matching: find.text('99+')),
        findsOneWidget,
      );
      final Rect bell = tester.getRect(
        find.bySemanticsLabel('Alertas, 120 novos'),
      );
      final Rect circle = tester.getRect(badge);
      expect(bell.width, greaterThanOrEqualTo(48));
      expect(bell.height, greaterThanOrEqualTo(48));
      expect(circle.height, greaterThanOrEqualTo(24));
      expect(circle.right, lessThanOrEqualTo(bell.right));
      expect(
        tester
            .widget<Stack>(
              find
                  .descendant(
                    of: find.byType(NotificationBellButton),
                    matching: find.byType(Stack),
                  )
                  .first,
            )
            .clipBehavior,
        Clip.none,
      );
    });

    testWidgets('alto contraste: contador com cor da paleta da feature 009', (
      tester,
    ) async {
      repository.stored = snapshot(alerts: [alert()]);

      controller = buildNotificationsController(repository, session);
      await controller.load();
      await pumpLocalized(
        tester,
        theme: AppTheme.highContrastTheme,
        child: Scaffold(
          body: Center(child: NotificationBellButton(onPressed: () {})),
        ),
        providers: [
          ChangeNotifierProvider<NotificationsController>.value(
            value: controller,
          ),
        ],
      );

      final AppPalette colors = tester
          .element(find.byType(NotificationBellButton))
          .colors;
      expect(colors, AppPalette.highContrast);
      final BoxDecoration decoration =
          tester.widget<Container>(badge).decoration! as BoxDecoration;
      expect(decoration.color, colors.primary);
      final Text number = tester.widget<Text>(
        find.descendant(of: badge, matching: find.text('1')),
      );
      expect(number.style?.color, colors.textPrimaryForeground);
      expect(tester.takeException(), isNull);
    });
  });
}
