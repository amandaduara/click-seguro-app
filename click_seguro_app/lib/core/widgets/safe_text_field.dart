import 'package:click_seguro_app/core/theme/app_colors.dart';
import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';

/// SafeTextField — campo de entrada com label superior, hint/erro e ícones
/// laterais. A borda anima para `primary` no foco (focus-within:border-primary)
/// e para `destructive` quando há erro.
class SafeTextField extends StatefulWidget {
  const SafeTextField({
    super.key,
    this.label,
    this.hint,
    this.error,
    this.leftIcon,
    this.rightIcon,
    this.placeholder,
    this.controller,
    this.obscureText = false,
    this.enabled = true,
    this.onChanged,
  });

  final String? label;
  final String? hint;
  final String? error;
  final Widget? leftIcon;
  final Widget? rightIcon;
  final String? placeholder;
  final TextEditingController? controller;
  final bool obscureText;
  final bool enabled;
  final ValueChanged<String>? onChanged;

  @override
  State<SafeTextField> createState() => _SafeTextFieldState();
}

class _SafeTextFieldState extends State<SafeTextField> {
  final FocusNode _focusNode = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (mounted) setState(() => _focused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.error != null && widget.error!.isNotEmpty;
    final borderColor = hasError
        ? AppColors.destructive
        : (_focused ? AppColors.primary : AppColors.input);
    final borderWidth = hasError || _focused ? 2.0 : 2.0;

    return Opacity(
      opacity: widget.enabled ? 1 : 0.4,
      child: IgnorePointer(
        ignoring: !widget.enabled,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.label != null) ...[
              Text(
                widget.label!,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: hasError ? AppColors.destructive : AppColors.secondary,
                  fontWeight: FontWeight.w600
                ),
              ),
              const SizedBox(height: AppSpacing.s1),
            ],
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor, width: borderWidth),
              ),
              child: Row(
                children: [
                  if (widget.leftIcon != null) ...[
                    IconTheme(
                      data: const IconThemeData(color: AppColors.textMutedForeground, size: 18),
                      child: widget.leftIcon!,
                    ),
                    const SizedBox(width: AppSpacing.s1),
                  ],
                  Expanded(
                    child: TextField(
                      controller: widget.controller,
                      focusNode: _focusNode,
                      obscureText: widget.obscureText,
                      onChanged: widget.onChanged,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textForeground),
                      decoration: InputDecoration(
                        hintText: widget.placeholder,
                        hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textMutedForeground),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  if (widget.rightIcon != null) ...[
                    const SizedBox(width: AppSpacing.s2),
                    IconTheme(
                      data: const IconThemeData(color: AppColors.textMutedForeground, size: 18),
                      child: widget.rightIcon!,
                    ),
                  ],
                ],
              ),
            ),
            if (widget.hint != null || hasError) ...[
              const SizedBox(height: AppSpacing.s1),
              Text(
                hasError ? widget.error! : widget.hint!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: hasError ? AppColors.destructive : AppColors.textMutedForeground,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
