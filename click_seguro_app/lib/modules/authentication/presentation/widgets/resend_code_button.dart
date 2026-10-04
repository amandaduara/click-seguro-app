import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:click_seguro_app/core/widgets/safe_button.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// "Reenviar código", bloqueado com contagem enquanto [secondsUntilResend] > 0.
class ResendCodeButton extends StatelessWidget {
  const ResendCodeButton({
    super.key,
    required this.secondsUntilResend,
    required this.onPressed,
  });

  final int secondsUntilResend;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final waiting = secondsUntilResend > 0;
    return SafeButton(
      label: waiting
          ? AppStrings.authResetResendIn.tr(args: ['$secondsUntilResend'])
          : AppStrings.authResetResend.tr(),
      size: SafeButtonSize.compact,
      tone: SafeButtonTone.ghost,
      disabled: waiting,
      onPressed: onPressed,
    );
  }
}
