import 'package:click_seguro_app/core/theme/app_colors.dart';
import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';

enum SafeButtonSize { large, compact, pill }

enum SafeButtonTone { primary, gradient, secondary, ghost }

/// SafeButton — botão de ação com hover, active:scale-95, loading e disabled.
class SafeButton extends StatefulWidget {
  const SafeButton({
    super.key,
    required this.label,
    this.onPressed,
    this.size = SafeButtonSize.large,
    this.tone = SafeButtonTone.primary,
    this.icon,
    this.iconRight,
    this.shadow = false,
    this.loading = false,
    this.disabled = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final SafeButtonSize size;
  final SafeButtonTone tone;
  final Widget? icon;
  final Widget? iconRight;
  final bool shadow;
  final bool loading;
  final bool disabled;

  @override
  State<SafeButton> createState() => _SafeButtonState();
}

class _SafeButtonState extends State<SafeButton> {
  bool _pressed = false;
  
  bool get _isDisabled => widget.disabled || widget.loading;

  EdgeInsets get _padding {
    switch (widget.size) {
      case SafeButtonSize.large:
        return const EdgeInsets.symmetric(vertical: 16);
      case SafeButtonSize.compact:
        return const EdgeInsets.symmetric(horizontal: 20, vertical: 10);
      case SafeButtonSize.pill:
        return const EdgeInsets.symmetric(horizontal: 14, vertical: 8);
    }
  }

  double get _fontSize {
    switch (widget.size) {
      case SafeButtonSize.large:
        return 16;
      case SafeButtonSize.compact:
        return 14;
      case SafeButtonSize.pill:
        return 12;
    }
  }

  ({Color? bg, Color fg, Gradient? gradient}) get _toneStyle {
    switch (widget.tone) {
      case SafeButtonTone.gradient:
        return (
          bg: null,
          fg: AppColors.textPrimaryForeground,
          gradient: AppColors.gradient,
        );
      case SafeButtonTone.secondary:
        return (
          bg: AppColors.secondary,
          fg: AppColors.textForeground,
          gradient: null,
        );
      case SafeButtonTone.ghost:
        return (
          bg: Colors.transparent,
          fg: AppColors.secondary,
          gradient: null,
        );
      case SafeButtonTone.primary:
        return (
          bg: AppColors.primary,
          fg: AppColors.textPrimaryForeground,
          gradient: null,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = _toneStyle;
    final opacity = _isDisabled
        ? 0.4
        : 1.0;

    final content = Row(
      mainAxisSize: widget.size == SafeButtonSize.large
          ? MainAxisSize.max
          : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.loading)
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(style.fg),
            ),
          )
        else if (widget.icon != null)
          IconTheme(
            data: IconThemeData(color: style.fg, size: 16),
            child: widget.icon!,
          ),
        if (widget.loading || widget.icon != null) const SizedBox(width: 8),
        Text(
          widget.label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontSize: _fontSize,
            fontWeight: FontWeight.w700,
            color: style.fg,
          ),
        ),
        if (widget.iconRight != null) ...[
          const SizedBox(width: 8),
          IconTheme(
            data: IconThemeData(color: style.fg, size: 16),
            child: widget.iconRight!,
          ),
        ],
      ],
    );

    return GestureDetector(
      onTapDown: _isDisabled ? null : (_) => setState(() => _pressed = true),
      onTapUp: _isDisabled ? null : (_) => setState(() => _pressed = false),
      onTapCancel: _isDisabled ? null : () => setState(() => _pressed = false),
      onTap: _isDisabled ? null : widget.onPressed,
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        child: AnimatedOpacity(
          opacity: opacity,
          duration: const Duration(milliseconds: 200),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            padding: _padding,
            width: widget.size == SafeButtonSize.large
                ? double.infinity
                : null,
            decoration: BoxDecoration(
              color: style.bg,
              gradient: style.gradient,
              borderRadius: AppSpacing.radiusFull,
              boxShadow: widget.shadow ? AppColors.shadowPrimary : null,
              border: widget.tone == SafeButtonTone.ghost
                  ? Border.all(color: AppColors.border, width: 1)
                  : null,
            ),
            child: content,
          ),
        ),
      ),
    );
  }
}
