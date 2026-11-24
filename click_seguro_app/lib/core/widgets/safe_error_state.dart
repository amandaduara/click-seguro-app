import 'package:click_seguro_app/core/errors/errors.dart';
import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:click_seguro_app/core/illustrations/app_illustration.dart';
import 'package:click_seguro_app/core/widgets/safe_button.dart';
import 'package:click_seguro_app/core/widgets/safe_state_layout.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Estado de erro de tela inteira (FR-015, FR-019) com "Tentar novamente".
///
/// Padrão de sem internet (specs/027): o tipo de [failure] decide. Sem
/// conexão, a nuvem sem sinal e a frase padrão, em qualquer tela; nas outras
/// falhas, a tomada com [message] (o texto da tela, já traduzido) ou, sem
/// ele, a mensagem da própria falha.
class SafeErrorState extends StatelessWidget {
  const SafeErrorState({
    super.key,
    required this.failure,
    this.message,
    required this.onRetry,
  });

  final Failure? failure;
  final String? message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final Failure? current = failure;
    final bool offline = current is ConnectionFailure;
    return SafeStateLayout(
      illustration: offline
          ? AppIllustration.stateOffline
          : AppIllustration.stateError,
      message: offline
          ? current.message.tr()
          : message ?? (current?.message ?? AppStrings.errorGeneric).tr(),
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
