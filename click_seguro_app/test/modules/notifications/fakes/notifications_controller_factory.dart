import 'package:click_seguro_app/modules/common/services/user_session_service.dart';
import 'package:click_seguro_app/modules/notifications/domain/usecases/check_new_alerts_usecase.dart';
import 'package:click_seguro_app/modules/notifications/domain/usecases/clear_alerts_usecase.dart';
import 'package:click_seguro_app/modules/notifications/domain/usecases/get_alerts_usecase.dart';
import 'package:click_seguro_app/modules/notifications/domain/usecases/mark_all_as_read_usecase.dart';
import 'package:click_seguro_app/modules/notifications/domain/usecases/mark_as_read_usecase.dart';
import 'package:click_seguro_app/modules/notifications/presentation/controller/notifications_controller.dart';

import 'alerts_fixtures.dart';
import 'fake_notifications_repository.dart';

/// Controller com os usecases reais sobre o [FakeNotificationsRepository] e a
/// sessão real. O relógio é [now] (padrão: [testNow]).
NotificationsController buildNotificationsController(
  FakeNotificationsRepository repository,
  UserSessionService session, {
  DateTime Function()? now,
}) => NotificationsController(
  checkNewAlerts: CheckNewAlertsUseCase(repository),
  getAlerts: GetAlertsUseCase(repository),
  markAsRead: MarkAsReadUseCase(repository),
  markAllAsRead: MarkAllAsReadUseCase(repository),
  clearAlerts: ClearAlertsUseCase(repository),
  sessionStatus: session.sessionStatus,
  now: now ?? () => testNow,
);
