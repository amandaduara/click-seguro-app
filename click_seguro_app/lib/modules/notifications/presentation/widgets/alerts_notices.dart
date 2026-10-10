import 'package:click_seguro_app/core/widgets/safe_offline_banner.dart';
import 'package:flutter/material.dart';

/// Faixas fixas no alto da tela de alertas, no lugar de avisos que somem
/// sozinhos (R12 de specs/011-alertas-locais).
class AlertsNotices extends StatelessWidget {
  const AlertsNotices({super.key, required this.showOffline});

  /// A última conferência falhou por falta de conexão.
  final bool showOffline;

  @override
  Widget build(BuildContext context) {
    if (!showOffline) return const SizedBox.shrink();
    return const SafeOfflineBanner();
  }
}
