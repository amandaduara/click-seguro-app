import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:click_seguro_app/core/theme/app_motion.dart';
import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:click_seguro_app/core/theme/app_typography.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Como uma alternativa aparece: sem marcação, escolhida, ou, depois da
/// correção, a correta e a escolhida errada (R8 de specs/018).
enum LessonOptionState { idle, selected, correct, wrong }

/// Alternativa da pergunta no redesign 2.0 (FR-008; Figma, quadro 07):
/// cartão grande com o número num círculo. Selecionada: borda tinta; certa:
/// verde com check; errada: coral com X e um balanço suave duas vezes (sem
/// movimento com reduzir animações). O texto de status deixa a diferença
/// clara sem depender só da cor.
class LessonOptionCard extends StatefulWidget {
  const LessonOptionCard({
    super.key,
    required this.number,
    required this.text,
    this.state = LessonOptionState.idle,
    this.onTap,
  });

  final int number;
  final String text;
  final LessonOptionState state;

  /// `null` quando não pode escolher (enviando ou já corrigida).
  final VoidCallback? onTap;

  @override
  State<LessonOptionCard> createState() => _LessonOptionCardState();
}

class _LessonOptionCardState extends State<LessonOptionCard>
    with SingleTickerProviderStateMixin {
  static const double _shakeOffset = 6;

  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  );

  @override
  void didUpdateWidget(LessonOptionCard old) {
    super.didUpdateWidget(old);
    if (widget.state == LessonOptionState.wrong &&
        old.state != LessonOptionState.wrong &&
        !AppMotion.of(context).reduced) {
      _shake.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette colors = context.colors;
    final AppMotion motion = AppMotion.of(context);
    final LessonOptionState state = widget.state;
    final ({
      Color border,
      double width,
      Color background,
      Color circle,
      Color circleText,
      IconData? icon,
      String? status,
      Color statusColor,
    })
    look = switch (state) {
      LessonOptionState.idle => (
        border: colors.border,
        width: 2,
        background: colors.card,
        circle: colors.surfaceStrong,
        circleText: colors.textForeground,
        icon: null,
        status: null,
        statusColor: colors.textForeground,
      ),
      LessonOptionState.selected => (
        border: colors.textForeground,
        width: 2.5,
        background: colors.surface,
        circle: colors.textForeground,
        circleText: colors.textPrimaryForeground,
        icon: LucideIcons.circleDot,
        status: null,
        statusColor: colors.textForeground,
      ),
      LessonOptionState.correct => (
        border: colors.success,
        width: 2.5,
        background: colors.successSoft,
        circle: colors.success,
        circleText: colors.textPrimaryForeground,
        icon: LucideIcons.circleCheck,
        status: AppStrings.activitiesOptionCorrect.tr(),
        statusColor: colors.success,
      ),
      LessonOptionState.wrong => (
        border: colors.destructive,
        width: 2.5,
        background: colors.primarySoft,
        circle: colors.destructive,
        circleText: colors.textPrimaryForeground,
        icon: LucideIcons.circleX,
        status: AppStrings.activitiesOptionWrong.tr(),
        statusColor: colors.destructive,
      ),
    };
    const BorderRadius radius = BorderRadius.all(Radius.circular(18));
    // Borda e fundo trocam de cor com animação ao escolher e ao corrigir
    // (specs/022 R13).
    final Widget card = AnimatedContainer(
      duration: motion.medium,
      curve: AppMotion.standard,
      decoration: BoxDecoration(
        color: look.background,
        borderRadius: radius,
        border: Border.all(color: look.border, width: look.width),
      ),
      child: Material(
        type: MaterialType.transparency,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: widget.onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 76),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.s4,
                vertical: 14,
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: look.circle,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${widget.number}',
                      textScaler: TextScaler.noScaling,
                      style: AppTypography.label.copyWith(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: look.circleText,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.text,
                          style: AppTypography.body.copyWith(
                            height: 1.4,
                            fontWeight: FontWeight.w500,
                            color: colors.textForeground,
                          ),
                        ),
                        AnimatedSize(
                          duration: motion.medium,
                          curve: AppMotion.standard,
                          alignment: Alignment.topLeft,
                          child: look.status == null
                              ? const SizedBox(width: double.infinity)
                              : Padding(
                                  padding: const EdgeInsets.only(
                                    top: AppSpacing.s1,
                                  ),
                                  child: Text(
                                    look.status!,
                                    style: AppTypography.label.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: look.statusColor,
                                    ),
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                  // O ícone do estado entra crescendo (escolha, acerto, erro).
                  ExcludeSemantics(
                    child: AnimatedSwitcher(
                      duration: motion.medium,
                      switchInCurve: AppMotion.emphasis,
                      switchOutCurve: AppMotion.exit,
                      transitionBuilder: (child, animation) =>
                          ScaleTransition(scale: animation, child: child),
                      child: look.icon == null
                          ? const SizedBox.shrink()
                          : Padding(
                              key: ValueKey(look.icon),
                              padding: const EdgeInsets.only(
                                left: AppSpacing.s3,
                              ),
                              child: Icon(
                                look.icon,
                                size: 26,
                                color: look.statusColor,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    // A semântica fica por fora do balanço, para o leitor de tela achar o
    // nó da alternativa (selecionada, certa, errada).
    final Widget shaking = AnimatedBuilder(
      animation: _shake,
      child: card,
      builder: (context, child) {
        // Duas idas e voltas de 6 px ao longo da animação.
        final double t = _shake.value;
        final double dx = _shake.isAnimating
            ? _shakeOffset *
                  (t < .25
                      ? -t * 4
                      : t < .5
                      ? -1 + (t - .25) * 8
                      : t < .75
                      ? 1 - (t - .5) * 8
                      : -1 + (t - .75) * 4)
            : 0;
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
    );
    return MergeSemantics(
      child: Semantics(
        inMutuallyExclusiveGroup: true,
        checked: state == LessonOptionState.selected,
        enabled: widget.onTap != null,
        child: shaking,
      ),
    );
  }
}
