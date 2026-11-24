import 'package:click_seguro_app/core/theme/app_motion.dart';
import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:click_seguro_app/core/theme/app_typography.dart';
import 'package:click_seguro_app/core/widgets/press_scale.dart';
import 'package:flutter/material.dart';

/// Altura mínima: `large` 60, `compact` 48 (RNF-003, FR-006).
enum SafeButtonSize { large, compact }

/// Tons do redesign 2.0 (FR-006): `primary` coral (uma ação principal por
/// tela), `secondary` creme, `ghost` contorno tinta, `link` texto sublinhado.
enum SafeButtonTone { primary, secondary, ghost, link }

/// SafeButton — botão com estado pressionado (cor mais escura e escala 0,98),
/// carregando e desativado. Cresce em altura quando o rótulo quebra a linha
/// (fonte ampliada).
class SafeButton extends StatefulWidget {
  const SafeButton({
    super.key,
    required this.label,
    this.onPressed,
    this.size = SafeButtonSize.large,
    this.tone = SafeButtonTone.primary,
    this.icon,
    this.iconRight,
    this.loading = false,
    this.disabled = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final SafeButtonSize size;
  final SafeButtonTone tone;
  final Widget? icon;
  final Widget? iconRight;
  final bool loading;
  final bool disabled;

  @override
  State<SafeButton> createState() => _SafeButtonState();
}

class _SafeButtonState extends State<SafeButton> {
  /// Canto do botão compacto: entre o `radiusSm` (12) e o `radiusMd` (16).
  static const BorderRadius _compactRadius = BorderRadius.all(
    Radius.circular(14),
  );

  bool _pressed = false;

  bool get _isDisabled =>
      widget.disabled || widget.loading || widget.onPressed == null;
  bool get _large => widget.size == SafeButtonSize.large;

  ({Color bg, Color fg, BorderSide? border}) _style(AppPalette colors) {
    switch (widget.tone) {
      case SafeButtonTone.primary:
        return (
          bg: _pressed ? colors.primaryPressed : colors.primary,
          fg: colors.textPrimaryForeground,
          border: null,
        );
      case SafeButtonTone.secondary:
        return (
          bg: colors.surfaceStrong,
          fg: colors.textForeground,
          border: null,
        );
      case SafeButtonTone.ghost:
        return (
          bg: colors.card,
          fg: colors.textForeground,
          border: BorderSide(color: colors.textForeground, width: 1.5),
        );
      case SafeButtonTone.link:
        return (
          bg: Colors.transparent,
          fg: colors.textForeground,
          border: null,
        );
    }
  }

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette colors = context.colors;
    final style = _style(colors);
    final AppMotion motion = AppMotion.of(context);
    final TextStyle labelStyle =
        (_large ? AppTypography.button : AppTypography.label).copyWith(
          color: style.fg,
          fontWeight: FontWeight.w700,
          decoration: widget.tone == SafeButtonTone.link
              ? TextDecoration.underline
              : null,
          decorationColor: style.fg,
        );

    final Widget content = Row(
      mainAxisSize: _large ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.loading || widget.icon != null) ...[
          // O ícone dá lugar ao spinner com esmaecimento (specs/022 R13).
          AnimatedSwitcher(
            duration: motion.short,
            switchInCurve: AppMotion.enter,
            switchOutCurve: AppMotion.exit,
            child: widget.loading
                ? SizedBox(
                    key: const ValueKey('spinner'),
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(style.fg),
                    ),
                  )
                : IconTheme(
                    key: const ValueKey('icon'),
                    data: IconThemeData(color: style.fg, size: 22),
                    child: widget.icon!,
                  ),
          ),
          const SizedBox(width: 10),
        ],
        // Flexible: com fonte ampliada (RNF-003) o rótulo quebra a linha em
        // vez de estourar a largura do botão.
        Flexible(
          child: Text(
            widget.label,
            textAlign: TextAlign.center,
            style: labelStyle,
          ),
        ),
        if (widget.iconRight != null) ...[
          const SizedBox(width: 10),
          IconTheme(
            data: IconThemeData(color: style.fg, size: 22),
            child: widget.iconRight!,
          ),
        ],
      ],
    );

    // Leitor de tela: um botão com o rótulo, desabilitado quando carrega ou
    // está bloqueado (specs/022 FR-007). A escala vem do [PressScale]; o
    // [Listener] só escurece o coral enquanto o dedo está em cima.
    return Semantics(
      container: true,
      button: true,
      enabled: !_isDisabled,
      child: Listener(
        onPointerDown: _isDisabled ? null : (_) => _setPressed(true),
        onPointerUp: (_) => _setPressed(false),
        onPointerCancel: (_) => _setPressed(false),
        child: PressScale(
          enabled: !_isDisabled,
          pressedScale: 0.98,
          onTap: widget.onPressed,
          child: Opacity(
            opacity: _isDisabled && !widget.loading ? 0.45 : 1.0,
            child: Container(
              constraints: BoxConstraints(minHeight: _large ? 60 : 48),
              padding: EdgeInsets.symmetric(
                horizontal: _large ? AppSpacing.s6 : AppSpacing.s5,
                vertical: AppSpacing.s3,
              ),
              width: _large ? double.infinity : null,
              decoration: BoxDecoration(
                color: style.bg,
                borderRadius: _large ? AppSpacing.radiusMd : _compactRadius,
                border: style.border == null
                    ? null
                    : Border.fromBorderSide(style.border!),
              ),
              // Só o grande se estica; o compacto fica do tamanho do texto
              // (com `alignment`, o Container ocuparia a largura toda).
              alignment: _large ? Alignment.center : null,
              child: content,
            ),
          ),
        ),
      ),
    );
  }
}
