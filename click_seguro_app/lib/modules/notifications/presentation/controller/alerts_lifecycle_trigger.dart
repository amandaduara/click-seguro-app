import 'dart:async';

import 'package:click_seguro_app/modules/common/services/user_session_service.dart';
import 'package:click_seguro_app/modules/notifications/presentation/controller/notifications_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Pede a conferência de notícias novas quando o app abre com conta, quando a
/// sessão vira conectada e quando a pessoa volta ao app (R2 de
/// specs/011-alertas-locais). O intervalo mínimo é do controller.
class AlertsLifecycleTrigger with WidgetsBindingObserver {
  AlertsLifecycleTrigger({
    required NotificationsController controller,
    required ValueListenable<UserSessionStatus> sessionStatus,
  }) : _controller = controller,
       _sessionStatus = sessionStatus {
    WidgetsBinding.instance.addObserver(this);
    _sessionStatus.addListener(_onSessionChanged);
    _checkIfSignedIn();
  }

  final NotificationsController _controller;
  final ValueListenable<UserSessionStatus> _sessionStatus;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _checkIfSignedIn();
  }

  void _onSessionChanged() => _checkIfSignedIn();

  void _checkIfSignedIn() {
    if (_sessionStatus.value == UserSessionStatus.authenticated) {
      unawaited(_controller.checkNew());
    }
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sessionStatus.removeListener(_onSessionChanged);
  }
}
