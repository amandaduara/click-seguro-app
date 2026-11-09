import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:click_seguro_app/core/theme/app_motion.dart';
import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Balão "digitando" enquanto o assistente responde (specs/022 FR-026): três
/// pontos que sobem em sequência; parados com o movimento reduzido. O leitor
/// de tela ouve "O assistente está digitando".
class AssistantTypingBubble extends StatefulWidget {
  const AssistantTypingBubble({super.key});

  @override
  State<AssistantTypingBubble> createState() => _AssistantTypingBubbleState();
}

class _AssistantTypingBubbleState extends State<AssistantTypingBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _wave = AnimationController(vsync: this);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final AppMotion motion = AppMotion.of(context);
    if (motion.reduced) {
      _wave
        ..stop()
        ..value = 0;
    } else if (!_wave.isAnimating) {
      // Uma volta: os três pontos, cada um num terço.
      _wave
        ..duration = motion.long * 3
        ..repeat();
    }
  }

  @override
  void dispose() {
    _wave.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color dot = context.colors.textMutedForeground;
    return Align(
      alignment: Alignment.centerLeft,
      child: Semantics(
        liveRegion: true,
        label: AppStrings.assistantTyping.tr(),
        excludeSemantics: true,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s4,
            vertical: AppSpacing.s3,
          ),
          decoration: BoxDecoration(
            color: context.colors.card,
            border: Border.all(color: context.colors.border),
            borderRadius: AppSpacing.radius2xl,
          ),
          child: AnimatedBuilder(
            animation: _wave,
            builder: (context, _) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < 3; i++)
                  Padding(
                    padding: EdgeInsets.only(left: i == 0 ? 0 : AppSpacing.s1),
                    child: Transform.translate(
                      offset: Offset(0, -4 * _lift(i)),
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: dot.withValues(alpha: 0.5 + 0.5 * _lift(i)),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 0 a 1: quanto o ponto [index] está levantado agora.
  double _lift(int index) {
    final double phase = (_wave.value * 3 - index).clamp(0.0, 1.0);
    return Curves.easeInOut.transform(phase < 0.5 ? phase * 2 : 2 - phase * 2);
  }
}
