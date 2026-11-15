import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:click_seguro_app/core/illustrations/app_illustration.dart';
import 'package:click_seguro_app/core/widgets/safe_button.dart';
import 'package:click_seguro_app/core/widgets/safe_state_layout.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Estado de erro (FR-015, FR-019): a mensagem (já traduzida, ex.:
/// `failure.message.tr()`) e "Tentar novamente". Redesign 2.0: a ilustração
/// da tomada desconectada, ou a da nuvem sem sinal quando a falha é de
/// conexão.
class SafeErrorState extends StatelessWidget {
  const SafeErrorState({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    // A falha de conexão chega como a mensagem padrão já traduzida
    // (`ConnectionFailure`): é ela que pede a ilustração de sem internet.
    final bool offline = message == AppStrings.errorConnection.tr();
    return SafeStateLayout(
      illustration: offline
          ? AppIllustration.stateOffline
          : AppIllustration.stateError,
      message: message,
      actions: [
        SafeButton(
          label: AppStrings.commonTryAgain.tr(),
          icon: const Icon(LucideIcons.rotateCcw),
          onPressed: onRetry,
        ),
      ],
    );
  }
}
