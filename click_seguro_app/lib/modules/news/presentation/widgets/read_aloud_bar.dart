import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:click_seguro_app/core/widgets/safe_button.dart';
import 'package:click_seguro_app/modules/common/services/text_to_speech_service.dart';
import 'package:click_seguro_app/modules/news/presentation/extensions/news_detail_presentation_extension.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

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
    final String label =
        (isSpeaking ? AppStrings.newsDetailStop : AppStrings.newsDetailListen)
            .tr();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.s5),
        Semantics(
          button: true,
          label: label,
          excludeSemantics: true,
          child: SafeButton(
            key: listenKey,
            label: label,
            tone: isSpeaking
                ? SafeButtonTone.secondary
                : SafeButtonTone.primary,
            icon: Icon(isSpeaking ? LucideIcons.square : LucideIcons.volume2),
            onPressed: onToggle,
          ),
        ),
        const SizedBox(height: AppSpacing.s3),
        Semantics(
          container: true,
          label: speedSemanticLabel(speed),
          child: ExcludeSemantics(
            child: Text(
              speedSemanticLabel(speed),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 16,
                color: context.colors.textMutedForeground,
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
  Widget build(BuildContext context) {
    final String name = readingSpeedName(speed);
    final ButtonStyle style = ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
      shape: const WidgetStatePropertyAll(StadiumBorder()),
      textStyle: WidgetStatePropertyAll(
        Theme.of(context).textTheme.labelLarge?.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
    return Semantics(
      button: true,
      selected: selected,
      label: name,
      excludeSemantics: true,
      child: selected
          ? FilledButton(
              onPressed: onTap,
              style: style.copyWith(
                backgroundColor: WidgetStatePropertyAll(
                  context.colors.secondary,
                ),
                foregroundColor: WidgetStatePropertyAll(
                  context.colors.textPrimaryForeground,
                ),
              ),
              child: Text(name),
            )
          : OutlinedButton(
              onPressed: onTap,
              style: style.copyWith(
                foregroundColor: WidgetStatePropertyAll(
                  context.colors.secondary,
                ),
              ),
              child: Text(name),
            ),
    );
  }
}
