import 'package:click_seguro_app/core/theme/app_motion.dart';
import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:click_seguro_app/core/theme/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter/services.dart';

/// SafeTextField — campo com rótulo sempre visível acima, dica/erro e ícones
/// laterais (redesign 2.0, FR-007). Foco: borda tinta de 2,5; erro: borda e
/// mensagem na cor de erro, com ícone (não só a cor).
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
    this.keyboardType,
    this.textInputAction,
    this.onSubmitted,
    this.focusNode,
    this.autofillHints,
    this.semanticsLabel,
    this.inputFormatters,
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
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  /// Se informado, substitui o foco interno (e não é descartado aqui).
  final FocusNode? focusNode;
  final Iterable<String>? autofillHints;

  /// Nome do campo no leitor de tela; sem ele, vale o [label] visível.
  final String? semanticsLabel;

  /// Ex.: máscara do telefone.
  final List<TextInputFormatter>? inputFormatters;

  @override
  State<SafeTextField> createState() => _SafeTextFieldState();
}

class _SafeTextFieldState extends State<SafeTextField> {
  FocusNode? _ownFocusNode;
  FocusNode get _focusNode =>
      widget.focusNode ?? (_ownFocusNode ??= FocusNode());
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (mounted) setState(() => _focused = _focusNode.hasFocus);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _ownFocusNode?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.error != null && widget.error!.isNotEmpty;
    final borderColor = hasError
        ? context.colors.destructive
        : (_focused
              ? context.colors.textForeground
              : context.colors.inputBorder);
    final double borderWidth = _focused ? 2.5 : (hasError ? 2.0 : 1.5);

    return Opacity(
      opacity: widget.enabled ? 1 : 0.4,
      child: IgnorePointer(
        ignoring: !widget.enabled,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.label != null) ...[
              // O rótulo visível é o nome do campo no leitor de tela (abaixo):
              // fora daqui, para não ser lido duas vezes.
              ExcludeSemantics(
                child: Text(
                  widget.label!,
                  style: AppTypography.label.copyWith(
                    color: hasError
                        ? context.colors.destructive
                        : context.colors.textForeground,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.s2),
            ],
            AnimatedContainer(
              duration: AppMotion.of(context).short,
              curve: AppMotion.standard,
              constraints: const BoxConstraints(minHeight: 60),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
              decoration: BoxDecoration(
                color: context.colors.card,
                borderRadius: AppSpacing.radiusMd,
                border: Border.all(color: borderColor, width: borderWidth),
              ),
              child: Row(
                children: [
                  if (widget.leftIcon != null) ...[
                    IconTheme(
                      data: IconThemeData(
                        color: context.colors.textMutedForeground,
                        size: 22,
                      ),
                      child: widget.leftIcon!,
                    ),
                    const SizedBox(width: AppSpacing.s3),
                  ],
                  Expanded(
                    // MergeSemantics: rótulo e campo viram um só nó para o
                    // leitor de tela (sem anunciar o campo duas vezes).
                    child: MergeSemantics(
                      child: Semantics(
                        label: widget.semanticsLabel ?? widget.label,
                        textField: true,
                        child: TextField(
                          controller: widget.controller,
                          focusNode: _focusNode,
                          obscureText: widget.obscureText,
                          onChanged: widget.onChanged,
                          keyboardType: widget.keyboardType,
                          textInputAction: widget.textInputAction,
                          onSubmitted: widget.onSubmitted,
                          autofillHints: widget.autofillHints,
                          inputFormatters: widget.inputFormatters,
                          style: AppTypography.body.copyWith(
                            color: context.colors.textForeground,
                          ),
                          decoration: InputDecoration(
                            // O fundo é o do contêiner arredondado; o
                            // `filled` do tema desenhava um retângulo de
                            // outro tom dentro dele (specs/022 T060).
                            filled: false,
                            hintText: widget.placeholder,
                            hintStyle: AppTypography.body.copyWith(
                              color: context.colors.textMutedForeground,
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (widget.rightIcon != null) ...[
                    const SizedBox(width: AppSpacing.s2),
                    IconTheme(
                      data: IconThemeData(
                        color: context.colors.textForeground,
                        size: 24,
                      ),
                      child: widget.rightIcon!,
                    ),
                  ],
                ],
              ),
            ),
            if (widget.hint != null || hasError) ...[
              const SizedBox(height: AppSpacing.s2),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (hasError) ...[
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Icon(
                        LucideIcons.circleAlert,
                        size: 16,
                        color: context.colors.destructive,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s1 + 2),
                  ],
                  Flexible(
                    child: Text(
                      hasError ? widget.error! : widget.hint!,
                      style: AppTypography.caption.copyWith(
                        color: hasError
                            ? context.colors.destructive
                            : context.colors.textMutedForeground,
                        fontWeight: hasError ? FontWeight.w600 : null,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
