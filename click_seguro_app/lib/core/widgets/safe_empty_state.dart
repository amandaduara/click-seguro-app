import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:click_seguro_app/core/illustrations/app_illustration.dart';
import 'package:click_seguro_app/core/widgets/safe_button.dart';
import 'package:click_seguro_app/core/widgets/safe_state_layout.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Estado vazio (FR-015, FR-019): ilustração da caixa aberta, mensagem
/// (padrão "Nada por aqui ainda.") e uma ação opcional. Textos já
/// traduzidos.
class SafeEmptyState extends StatelessWidget {
  const SafeEmptyState({
    super.key,
    this.message,
    this.actionLabel,
    this.onAction,
  });

  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final String? label = actionLabel;
    final VoidCallback? action = onAction;
    return SafeStateLayout(
      illustration: AppIllustration.stateEmpty,
      message: message ?? AppStrings.commonEmpty.tr(),
      actions: [
        if (label != null && action != null)
          SafeButton(
            label: label,
            tone: SafeButtonTone.secondary,
            onPressed: action,
          ),
      ],
    );
  }
}
