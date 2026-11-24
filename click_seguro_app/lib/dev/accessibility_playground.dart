// Só para desenvolvimento: flutter run -t lib/dev/accessibility_playground.dart
//
// O app real (mesmo setupApp() do main.dart) com os três botões dos alertas
// (feature 011) por cima. O painel de acessibilidade da feature 009 e o atalho
// "Notícias salvas" da 010 saíram: a tela de Acessibilidade (B9) e o Perfil
// (B7) já têm essas entradas (R8 de specs/014-acessibilidade). O nome do
// arquivo ficou, porque as specs anteriores o citam. Não é importada pelo app;
// os textos são fixos por não ser parte do produto, como no style guide.
import 'dart:async';

import 'package:click_seguro_app/main.dart';
import 'package:click_seguro_app/modules/common/accessibility/accessibility_preferences_notifier.dart';
import 'package:click_seguro_app/modules/notifications/data/datasources/alerts_local_data_source.dart';
import 'package:click_seguro_app/modules/notifications/data/models/alerts_snapshot_model.dart';
import 'package:click_seguro_app/modules/notifications/domain/usecases/clear_alerts_usecase.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  final (moduleManager, router) = await setupApp();

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('pt', 'BR'), Locale('en', 'US')],
      path: 'assets/translations',
      fallbackLocale: const Locale('pt', 'BR'),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Stack(
          children: [
            ClickSeguroApp(
              moduleManager: moduleManager,
              router: router,
              accessibility: GetIt.instance<AccessibilityPreferencesNotifier>(),
            ),
            _AlertsShortcuts(router: router),
          ],
        ),
      ),
    ),
  );
}

/// Entradas fixas dos alertas (R10 de specs/011-alertas-locais): a primeira
/// conferência não gera alertas e o serviço de desenvolvimento não publica
/// notícia a pedido. Valem na próxima abertura do app.
class _AlertsShortcuts extends StatelessWidget {
  const _AlertsShortcuts({required this.router});

  /// Os botões ficam acima do `ClickSeguroApp`, sem contexto do `go_router`.
  final GoRouter router;

  @override
  Widget build(BuildContext context) {
    return Localizations(
      locale: const Locale('en'),
      delegates: const [
        DefaultMaterialLocalizations.delegate,
        DefaultWidgetsLocalizations.delegate,
      ],
      // Stack próprio: o Localizations fica entre o Positioned e o Stack do
      // main. Sem filhos não posicionados, o toque fora passa para o app.
      child: Stack(
        children: [
          Positioned(
            right: 0,
            top: 48,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _shortcut(
                  'Alertas: voltar verificação 7 dias',
                  () => unawaited(_rewindAlertsCheck()),
                ),
                const SizedBox(height: 4),
                _shortcut(
                  'Alertas: apagar',
                  () => unawaited(GetIt.instance<ClearAlertsUseCase>()()),
                ),
                const SizedBox(height: 4),
                _shortcut(
                  'Abrir Alertas',
                  () => unawaited(router.push<void>('/notifications')),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _shortcut(String label, VoidCallback onTap) => Material(
    color: Colors.black54,
    borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
      ),
    ),
  );

  /// Grava `lastCheckAt = agora − 7 dias` no registro da conta atual,
  /// preservando os alertas (ou criando o registro).
  Future<void> _rewindAlertsCheck() async {
    final AlertsLocalDataSource local = GetIt.instance<AlertsLocalDataSource>();
    final AlertsSnapshotModel? current = await local.read();
    await local.write(
      AlertsSnapshotModel(
        lastCheckAt: DateTime.now().toUtc().subtract(const Duration(days: 7)),
        receiveAlerts: current?.receiveAlerts,
        alerts: current?.alerts ?? const [],
      ),
    );
  }
}
