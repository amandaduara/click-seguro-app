import 'package:click_seguro_app/core/theme/app_motion.dart';
import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:click_seguro_app/core/theme/app_typography.dart';
import 'package:flutter/material.dart';

/// Seletor em pílula "Entrar" / "Criar conta", com o mesmo visual do
/// `SafePillTabs` (redesign 2.0). Fica próprio só para dar a cada segmento a
/// Key que os testes usam ('auth-mode-login' / 'auth-mode-register').
///
/// Uma única pílula clara desliza até o segmento escolhido; os rótulos só
/// trocam de cor. Assim só o segmento tocado tem efeito visual.
class AuthModeSwitch extends StatelessWidget {
  const AuthModeSwitch({
    super.key,
    required this.loginLabel,
    required this.registerLabel,
    required this.isRegister,
    required this.onChanged,
  });

  final String loginLabel;
  final String registerLabel;
  final bool isRegister;

  /// Recebe `true` para "Criar conta".
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    // Mesmo visual do `SafePillTabs` (redesign 2.0); a pílula desliza, ou
    // troca direto com reduzir animações (FR-021).
    return Container(
      constraints: const BoxConstraints(minHeight: 56),
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: context.colors.surfaceStrong,
        borderRadius: AppSpacing.radiusFull,
        border: context.colors.shadow.isEmpty
            ? Border.all(color: context.colors.border)
            : null,
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: AnimatedAlign(
              duration: AppMotion.of(context).medium,
              curve: AppMotion.standard,
              alignment: isRegister
                  ? Alignment.centerRight
                  : Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: 0.5,
                heightFactor: 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: context.colors.card,
                    borderRadius: AppSpacing.radiusFull,
                    boxShadow: context.colors.shadow,
                    border: context.colors.shadow.isEmpty
                        ? Border.all(color: context.colors.border, width: 2)
                        : null,
                  ),
                ),
              ),
            ),
          ),
          Row(
            children: [
              _Segment(
                key: const ValueKey('auth-mode-login'),
                label: loginLabel,
                selected: !isRegister,
                onTap: () => onChanged(false),
              ),
              _Segment(
                key: const ValueKey('auth-mode-register'),
                label: registerLabel,
                selected: isRegister,
                onTap: () => onChanged(true),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final TextStyle style = AppTypography.label.copyWith(
      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
      color: selected
          ? context.colors.textForeground
          : context.colors.textMutedForeground,
    );
    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        child: GestureDetector(
          onTap: selected ? null : onTap,
          behavior: HitTestBehavior.opaque,
          child: Container(
            constraints: const BoxConstraints(minHeight: 46),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            // Como no `SafePillTabs`: numa linha só; com fonte muito grande
            // o rótulo encolhe em vez de quebrar no meio da palavra.
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: AnimatedDefaultTextStyle(
                duration: AppMotion.of(context).medium,
                curve: AppMotion.standard,
                style: style,
                child: Text(label, maxLines: 1, textAlign: TextAlign.center),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
