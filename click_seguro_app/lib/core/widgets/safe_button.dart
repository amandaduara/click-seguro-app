import 'package:click_seguro_app/core/theme/app_motion.dart';
import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:click_seguro_app/core/widgets/press_scale.dart';
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
          fg: context.colors.textPrimaryForeground,
          gradient: context.colors.gradient,
        );
      case SafeButtonTone.secondary:
        // Texto claro sobre o azul-escuro, como no wireframe
        // (text-secondary-foreground); o escuro sumia no fundo.
        return (
          bg: context.colors.secondary,
          fg: context.colors.textPrimaryForeground,
          gradient: null,
        );
      case SafeButtonTone.ghost:
        return (
          bg: Colors.transparent,
          fg: context.colors.secondary,
          gradient: null,
        );
      case SafeButtonTone.primary:
        return (
          bg: context.colors.primary,
          fg: context.colors.textPrimaryForeground,
          gradient: null,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = _toneStyle;
    final AppMotion motion = AppMotion.of(context);
    final opacity = _isDisabled ? 0.4 : 1.0;

    final Widget? leading = widget.loading
        ? SizedBox(
            key: const ValueKey('spinner'),
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(style.fg),
            ),
          )
        : widget.icon == null
        ? null
        : IconTheme(
            key: const ValueKey('icon'),
            data: IconThemeData(color: style.fg, size: 16),
            child: widget.icon!,
          );

    final content = Row(
      mainAxisSize: widget.size == SafeButtonSize.large
          ? MainAxisSize.max
          : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (leading != null) ...[
          // O ícone dá lugar ao spinner com esmaecimento (specs/022 R13).
          AnimatedSwitcher(
            duration: motion.short,
            switchInCurve: AppMotion.enter,
            switchOutCurve: AppMotion.exit,
            child: leading,
          ),
          const SizedBox(width: 8),
        ],
        // Flexible: com fonte ampliada (RNF-003) o rótulo quebra a linha em
        // vez de estourar a largura do botão.
        Flexible(
          child: Text(
            widget.label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontSize: _fontSize,
              fontWeight: FontWeight.w700,
              color: style.fg,
            ),
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

    // Leitor de tela: um botão com o rótulo, desabilitado quando carrega ou
    // está bloqueado (specs/022 FR-007).
    return Semantics(
      container: true,
      button: true,
      enabled: !_isDisabled && widget.onPressed != null,
      child: PressScale(
        enabled: !_isDisabled,
        pressedScale: 0.95,
        onTap: widget.onPressed,
        child: AnimatedOpacity(
          opacity: opacity,
          duration: motion.short,
          curve: AppMotion.standard,
          child: AnimatedContainer(
            duration: motion.short,
            curve: AppMotion.standard,
            padding: _padding,
            width: widget.size == SafeButtonSize.large ? double.infinity : null,
            decoration: BoxDecoration(
              color: style.bg,
              gradient: style.gradient,
              borderRadius: AppSpacing.radiusFull,
              boxShadow: widget.shadow ? context.colors.shadowPrimary : null,
              border: widget.tone == SafeButtonTone.ghost
                  ? Border.all(color: context.colors.border, width: 1)
                  : null,
            ),
            child: content,
          ),
        ),
      ),
    );
  }
}
