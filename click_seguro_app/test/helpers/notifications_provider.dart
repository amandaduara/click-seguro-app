import 'package:click_seguro_app/modules/common/services/user_session_service.dart';
import 'package:click_seguro_app/modules/notifications/presentation/controller/notifications_controller.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../modules/notifications/fakes/fake_notifications_repository.dart';
import '../modules/notifications/fakes/notifications_controller_factory.dart';

/// Alertas sem rede, para testes que montam o app, a barra superior ou as
/// rotas reais (o `NotificationsController` vem do `NotificationsModule` no
/// app). Usa a sessão registrada no `GetIt`.
SingleChildWidget fakeNotificationsProvider([
  FakeNotificationsRepository? repository,
]) => ChangeNotifierProvider<NotificationsController>(
  create: (_) => buildNotificationsController(
    repository ?? FakeNotificationsRepository(),
    GetIt.instance<UserSessionService>(),
  )..load(),
);
