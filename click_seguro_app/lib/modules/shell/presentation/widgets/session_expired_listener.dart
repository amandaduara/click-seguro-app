import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:click_seguro_app/core/routing/navigator_keys.dart';
import 'package:click_seguro_app/modules/common/services/user_session_service.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

/// Avisa, sem mudar de tela, quando o serviço recusa a sessão durante o uso
/// (CB-003; FR-012a da feature 001; R4 de specs/005-shell-navegacao-base).
///
/// O aviso depende da transição conectada → desconectada com motivo
/// "expirada", então várias recusas seguidas geram um aviso só.
class SessionExpiredListener extends StatefulWidget {
  const SessionExpiredListener({super.key, required this.child});

  final Widget child;

  @override
  State<SessionExpiredListener> createState() => _SessionExpiredListenerState();
}

class _SessionExpiredListenerState extends State<SessionExpiredListener> {
  final UserSessionService _session = GetIt.instance<UserSessionService>();
  late UserSessionStatus _lastStatus;

  @override
  void initState() {
    super.initState();
    _lastStatus = _session.sessionStatus.value;
    _session.sessionStatus.addListener(_onStatusChanged);
  }

  @override
  void dispose() {
    _session.sessionStatus.removeListener(_onStatusChanged);
    super.dispose();
  }

  void _onStatusChanged() {
    final UserSessionStatus status = _session.sessionStatus.value;
    final bool expired =
        _lastStatus == UserSessionStatus.authenticated &&
        status == UserSessionStatus.unauthenticated &&
        _session.endReason == SessionEndReason.expired;
    _lastStatus = status;
    if (!expired) return;

    rootScaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(AppStrings.errorSessionExpired.tr()),
        action: SnackBarAction(
          label: AppStrings.commonSessionExpiredAction.tr(),
          onPressed: () => rootNavigatorKey.currentContext?.go('/login'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
