import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:flutter/material.dart';

/// Seletor em pílula "Entrar" / "Criar conta" (wireframe, LoginScreen).
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

  static const Duration _duration = Duration(milliseconds: 200);

  final String loginLabel;
  final String registerLabel;
  final bool isRegister;

  /// Recebe `true` para "Criar conta".
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: context.colors.input,
        borderRadius: const BorderRadius.all(Radius.circular(999)),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: AnimatedAlign(
              duration: _duration,
              curve: Curves.easeOut,
              alignment: isRegister
                  ? Alignment.centerRight
                  : Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: 0.5,
                heightFactor: 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: context.colors.background,
                    borderRadius: const BorderRadius.all(Radius.circular(999)),
                    boxShadow: context.colors.shadowSm,
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
    final style = Theme.of(context).textTheme.labelLarge?.copyWith(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: selected
          ? context.colors.secondary
          : context.colors.textMutedForeground,
    );
    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        child: GestureDetector(
          onTap: selected ? null : onTap,
          behavior: HitTestBehavior.opaque,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Center(
              child: AnimatedDefaultTextStyle(
                duration: AuthModeSwitch._duration,
                style: style ?? const TextStyle(),
                child: Text(label, textAlign: TextAlign.center),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
