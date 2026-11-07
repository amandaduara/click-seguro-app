import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:click_seguro_app/core/widgets/safe_button.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// "Ouvir"/"Parar" da leitura em voz alta (RF-015, RF-024). Usado no detalhe
/// da notícia e nas perguntas das atividades (R5 de
/// specs/017-perguntas-atividades).
class ListenButton extends StatelessWidget {
  const ListenButton({
    super.key,
    required this.isSpeaking,
    required this.onPressed,
  });

  final bool isSpeaking;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final String label =
        (isSpeaking ? AppStrings.commonStop : AppStrings.commonListen).tr();
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: SafeButton(
        label: label,
        tone: isSpeaking ? SafeButtonTone.secondary : SafeButtonTone.primary,
        icon: Icon(isSpeaking ? LucideIcons.square : LucideIcons.volume2),
        onPressed: onPressed,
      ),
    );
  }
}
