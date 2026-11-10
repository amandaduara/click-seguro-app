import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:click_seguro_app/core/theme/app_motion.dart';
import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:click_seguro_app/core/theme/app_typography.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// "Ouvir"/"Parar" da leitura em voz alta (RF-015, RF-024). Usado no detalhe
/// da notícia e nas perguntas das atividades (R5 de
/// specs/017-perguntas-atividades).
///
/// Redesign 2.0: pílula com borda e ícone coral. Ao começar a ler, um halo
/// pulsa 3 vezes (2 s cada) e fica como um anel parado até a leitura acabar
/// (FR-020); sem pulso com reduzir animações (FR-021). Um pulso sem fim
/// distrairia e nunca deixaria a tela "assentar".
class ListenButton extends StatefulWidget {
  const ListenButton({
    super.key,
    required this.isSpeaking,
    required this.onPressed,
  });

  final bool isSpeaking;
  final VoidCallback onPressed;

  @override
  State<ListenButton> createState() => _ListenButtonState();
}

class _ListenButtonState extends State<ListenButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  );

  static const int _pulses = 3;

  void _syncPulse() {
    if (widget.isSpeaking && !AppMotion.of(context).reduced) {
      if (!_pulse.isAnimating && _pulse.value == 0) {
        _pulse.repeat(count: _pulses);
      }
    } else {
      _pulse
        ..stop()
        ..value = 0;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncPulse();
  }

  @override
  void didUpdateWidget(ListenButton old) {
    super.didUpdateWidget(old);
    if (old.isSpeaking != widget.isSpeaking) _syncPulse();
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette colors = context.colors;
    final String label =
        (widget.isSpeaking ? AppStrings.commonStop : AppStrings.commonListen)
            .tr();
    return Align(
      alignment: AlignmentDirectional.centerStart,
      widthFactor: 1,
      child: Semantics(
        button: true,
        label: label,
        excludeSemantics: true,
        child: AnimatedBuilder(
          animation: _pulse,
          builder: (context, child) => DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: AppSpacing.radiusFull,
              boxShadow: [
                if (_pulse.isAnimating)
                  BoxShadow(
                    color: colors.primary.withValues(
                      alpha: 0.35 * (1 - _pulse.value),
                    ),
                    spreadRadius: 14 * _pulse.value,
                  )
                else if (widget.isSpeaking)
                  // Anel parado: continua lendo.
                  BoxShadow(
                    color: colors.primary.withValues(alpha: 0.25),
                    spreadRadius: 4,
                  ),
              ],
            ),
            child: child,
          ),
          child: Material(
            type: MaterialType.transparency,
            child: Ink(
              decoration: BoxDecoration(
                color: widget.isSpeaking ? colors.primarySoft : colors.card,
                borderRadius: AppSpacing.radiusFull,
                border: Border.all(color: colors.border, width: 1.5),
              ),
              child: InkWell(
                borderRadius: AppSpacing.radiusFull,
                onTap: widget.onPressed,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 48),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 8, 18, 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          widget.isSpeaking
                              ? LucideIcons.square
                              : LucideIcons.volume2,
                          size: 22,
                          color: colors.primary,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            label,
                            style: AppTypography.label.copyWith(
                              color: colors.textForeground,
                            ),
                          ),
                        ),
                      ],
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
