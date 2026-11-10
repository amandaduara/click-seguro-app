import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:click_seguro_app/core/widgets/listen_button.dart';
import 'package:click_seguro_app/modules/common/services/text_to_speech_service.dart';
import 'package:click_seguro_app/modules/news/presentation/extensions/news_detail_presentation_extension.dart';
import 'package:click_seguro_app/core/theme/app_typography.dart';
import 'package:click_seguro_app/core/widgets/safe_chip.dart';
import 'package:flutter/material.dart';

/// Botão "Ouvir"/"Parar" e seletor de velocidade (lenta, normal, rápida) do
/// detalhe (RF-015, FR-005 a FR-007, FR-010). Some sem voz no idioma do app,
/// sem deixar espaço.
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

  static Key speedKey(ReadingSpeed speed) =>
      ValueKey('detail-speed-${speed.name}');

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
    // Redesign 2.0: um bloco com o "Ouvir" e as velocidades.
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.s5),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.s4),
        // Branco com borda: os chips creme das velocidades aparecem nele.
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: AppSpacing.radiusLg,
          border: Border.all(color: colors.border, width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListenButton(
              key: listenKey,
              isSpeaking: isSpeaking,
              onPressed: onToggle,
            ),
            const SizedBox(height: AppSpacing.s3),
            Semantics(
              container: true,
              label: speedSemanticLabel(speed),
              child: ExcludeSemantics(
                child: Text(
                  speedSemanticLabel(speed),
                  style: AppTypography.caption.copyWith(
                    fontSize: 16,
                    color: colors.textMutedForeground,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.s2),
            Wrap(
              spacing: AppSpacing.s2,
              runSpacing: AppSpacing.s2,
              children: [
                for (final option in ReadingSpeed.values)
                  _SpeedOption(
                    key: speedKey(option),
                    speed: option,
                    selected: option == speed,
                    onTap: () => onSpeedChanged(option),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Opção de velocidade: botão de pelo menos 48×48 dp, preenchido quando
/// escolhido.
class _SpeedOption extends StatelessWidget {
  const _SpeedOption({
    super.key,
    required this.speed,
    required this.selected,
    required this.onTap,
  });

  final ReadingSpeed speed;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SafeChip(
    label: readingSpeedName(speed),
    selected: selected,
    onTap: onTap,
  );
}
