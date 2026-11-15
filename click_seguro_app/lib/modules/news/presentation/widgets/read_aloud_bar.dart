import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:click_seguro_app/core/theme/app_typography.dart';
import 'package:click_seguro_app/core/widgets/listen_button.dart';
import 'package:click_seguro_app/modules/common/services/text_to_speech_service.dart';
import 'package:click_seguro_app/modules/news/presentation/extensions/news_detail_presentation_extension.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Cartão "Ouvir notícia" do detalhe (RF-015, FR-005 a FR-007, FR-010;
/// redesign 2.0, Figma quadro 05): botão de tocar coral, a velocidade atual
/// e, à direita, a pílula "1x" que passa para a próxima velocidade
/// ([nextReadingSpeed]). Some sem voz no idioma do app, sem deixar espaço.
class ReadAloudBar extends StatelessWidget {
  const ReadAloudBar({
    super.key,
    required this.isAvailable,
    required this.isSpeaking,
    required this.speed,
    required this.onToggle,
    required this.onSpeedChanged,
  });

  static const Key listenKey = ValueKey('detail-listen');
  static const Key speedKey = ValueKey('detail-speed');

  final bool isAvailable;
  final bool isSpeaking;
  final ReadingSpeed speed;

  /// "Ouvir" ou "Parar", conforme [isSpeaking].
  final VoidCallback onToggle;
  final ValueChanged<ReadingSpeed> onSpeedChanged;

  @override
  Widget build(BuildContext context) {
    if (!isAvailable) return const SizedBox.shrink();
    final AppPalette colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s3),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: AppSpacing.radiusLg,
        // Alto contraste: sem fundo suave visível, a borda marca o bloco.
        border: colors.shadow.isEmpty ? Border.all(color: colors.border) : null,
      ),
      child: Row(
        children: [
          ListenButton(
            key: listenKey,
            round: true,
            isSpeaking: isSpeaking,
            onPressed: onToggle,
          ),
          const SizedBox(width: AppSpacing.s4),
          // O botão já diz "Ouvir"/"Parar" e a pílula diz a velocidade ao
          // leitor de tela.
          Expanded(
            child: ExcludeSemantics(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.newsDetailListenTitle.tr(),
                    style: AppTypography.label.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colors.textForeground,
                    ),
                  ),
                  Text(
                    speedSemanticLabel(speed),
                    style: AppTypography.caption.copyWith(
                      color: colors.textMutedForeground,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.s2),
          _SpeedPill(
            key: speedKey,
            speed: speed,
            onTap: () => onSpeedChanged(nextReadingSpeed(speed)),
          ),
        ],
      ),
    );
  }
}

/// Pílula branca com "0,5x", "1x" ou "2x"; tocar passa para a próxima
/// velocidade. Lida como "Velocidade: normal, 1x" com a dica "Toque para
/// mudar".
class _SpeedPill extends StatelessWidget {
  const _SpeedPill({super.key, required this.speed, required this.onTap});

  final ReadingSpeed speed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppPalette colors = context.colors;
    final String short = readingSpeedShort(speed);
    return Semantics(
      button: true,
      label: AppStrings.newsDetailSpeedChip.tr(
        args: [readingSpeedName(speed), short],
      ),
      hint: AppStrings.newsDetailSpeedChange.tr(),
      onTap: onTap,
      excludeSemantics: true,
      child: Material(
        type: MaterialType.transparency,
        child: Ink(
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: AppSpacing.radiusFull,
            border: colors.shadow.isEmpty
                ? Border.all(color: colors.border)
                : null,
          ),
          child: InkWell(
            borderRadius: AppSpacing.radiusFull,
            onTap: onTap,
            child: ConstrainedBox(
              // 48: alvo de toque mínimo (RNF-003).
              constraints: const BoxConstraints(minWidth: 64, minHeight: 48),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s3),
                child: Center(
                  widthFactor: 1,
                  heightFactor: 1,
                  child: Text(
                    short,
                    style: AppTypography.label.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colors.textForeground,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
