import 'package:click_seguro_app/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Seletor em pílula "Entrar" / "Criar conta" (wireframe, LoginScreen).
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
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: const BoxDecoration(
        color: AppColors.input,
        borderRadius: BorderRadius.all(Radius.circular(999)),
      ),
      child: Row(
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
    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            constraints: const BoxConstraints(minHeight: 48),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? AppColors.background : Colors.transparent,
              borderRadius: const BorderRadius.all(Radius.circular(999)),
              boxShadow: selected ? AppColors.shadowSm : null,
            ),
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: selected
                    ? AppColors.secondary
                    : AppColors.textMutedForeground,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
