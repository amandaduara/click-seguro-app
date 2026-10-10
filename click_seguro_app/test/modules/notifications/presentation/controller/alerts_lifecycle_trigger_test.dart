import 'package:click_seguro_app/modules/common/services/user_session_service.dart';
import 'package:click_seguro_app/modules/notifications/domain/usecases/check_new_alerts_usecase.dart';
import 'package:click_seguro_app/modules/notifications/domain/usecases/clear_alerts_usecase.dart';
import 'package:click_seguro_app/modules/notifications/domain/usecases/get_alerts_usecase.dart';
import 'package:click_seguro_app/modules/notifications/domain/usecases/mark_as_read_usecase.dart';
import 'package:click_seguro_app/modules/notifications/presentation/controller/alerts_lifecycle_trigger.dart';
import 'package:click_seguro_app/modules/notifications/presentation/controller/notifications_controller.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../fakes/fake_secure_storage_service.dart';
import '../../fakes/fake_notifications_repository.dart';

/// Só conta as conferências pedidas pelo gatilho.
class _SpyController extends NotificationsController {
  _SpyController(FakeNotificationsRepository repository, UserSessionService s)
    : super(
        checkNewAlerts: CheckNewAlertsUseCase(repository),
        getAlerts: GetAlertsUseCase(repository),
        markAsRead: MarkAsReadUseCase(repository),
        clearAlerts: ClearAlertsUseCase(repository),
        sessionStatus: s.sessionStatus,
      );

  final List<bool> checks = [];

  @override
  Future<void> checkNew({bool force = false}) async => checks.add(force);
}

void main() {
  late UserSessionService session;
  late _SpyController controller;
  AlertsLifecycleTrigger? trigger;

  setUp(() {
    session = UserSessionService(FakeSecureStorageService());
    controller = _SpyController(FakeNotificationsRepository(), session);
  });

  tearDown(() {
    trigger?.dispose();
    trigger = null;
    controller.dispose();
  });

  Future<void> signIn() => session.saveSession(
    accessToken: 'tk',
    refreshToken: 'rf',
    email: 'ana@test.com',
  );

  AlertsLifecycleTrigger build() => trigger = AlertsLifecycleTrigger(
    controller: controller,
    sessionStatus: session.sessionStatus,
  );

  testWidgets('criado com a sessão conectada: confere uma vez', (tester) async {
    await signIn();

    build();

    expect(controller.checks, [false]);
  });

  testWidgets('criado como visitante ou desconectado: não confere', (
    tester,
  ) async {
    await session.startGuestSession();
    build();
    expect(controller.checks, isEmpty);

    await session.logout();
    expect(controller.checks, isEmpty);
  });

  testWidgets('a sessão vira conectada depois: confere', (tester) async {
    build();
    expect(controller.checks, isEmpty);

    await signIn();

    expect(controller.checks, [false]);
  });

  testWidgets('volta ao app (resumed) confere; paused não', (tester) async {
    await signIn();
    build();
    controller.checks.clear();

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    expect(controller.checks, isEmpty);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    expect(controller.checks, [false]);
  });

  testWidgets('visitante ao voltar ao app: não confere', (tester) async {
    await session.startGuestSession();
    build();

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);

    expect(controller.checks, isEmpty);
  });

  testWidgets('dispose remove o observador e o ouvinte da sessão', (
    tester,
  ) async {
    await signIn();
    build();
    controller.checks.clear();

    trigger!.dispose();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await session.logout();
    await signIn();

    expect(controller.checks, isEmpty);
    trigger = null;
  });
}
