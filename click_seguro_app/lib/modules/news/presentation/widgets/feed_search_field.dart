import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:click_seguro_app/core/theme/app_typography.dart';
import 'package:click_seguro_app/modules/news/domain/entities/news_filter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Campo de busca do feed (design system §7.4): ícone de lupa, dica e um
/// "X" para limpar quando há texto.
class FeedSearchField extends StatefulWidget {
  const FeedSearchField({
    super.key,
    required this.onChanged,
    required this.onCleared,
    this.initialText = '',
  });

  final ValueChanged<String> onChanged;
  final VoidCallback onCleared;

  /// Texto ao reconstruir a página (a busca continua ao voltar à aba).
  final String initialText;

  @override
  State<FeedSearchField> createState() => _FeedSearchFieldState();
}

class _FeedSearchFieldState extends State<FeedSearchField> {
  late final TextEditingController _text = TextEditingController(
    text: widget.initialText,
  );

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  /// Espaço em branco não é busca (validação da usuária, specs/024): o
  /// começo do texto perde os espaços e um toast curto explica.
  late final TextInputFormatter _noLeadingSpace =
      TextInputFormatter.withFunction((oldValue, newValue) {
        final String trimmed = newValue.text.trimLeft();
        if (trimmed == newValue.text) return newValue;
        _warnInvalid();
        final int removed = newValue.text.length - trimmed.length;
        return TextEditingValue(
          text: trimmed,
          selection: TextSelection.collapsed(
            offset: (newValue.selection.baseOffset - removed).clamp(
              0,
              trimmed.length,
            ),
          ),
        );
      });

  /// Busca curta demais (ou vazia) ao tocar em "buscar" no teclado.
  void _onSubmitted(String text) {
    if (!NewsFilter(search: text).hasSearch) _warnInvalid();
  }

  void _warnInvalid() {
    if (!mounted) return;
    ScaffoldMessenger.maybeOf(context)
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 3),
          content: Text(
            AppStrings.newsSearchInvalid.tr(args: ['$minSearchLength']),
          ),
        ),
      );
  }

  void _clear() {
    _text.clear();
    setState(() {});
    widget.onCleared();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s5),
      child: TextField(
        controller: _text,
        inputFormatters: [_noLeadingSpace],
        onChanged: (value) {
          setState(() {});
          widget.onChanged(value);
        },
        onSubmitted: _onSubmitted,
        textInputAction: TextInputAction.search,
        style: AppTypography.body.copyWith(
          color: context.colors.textForeground,
        ),
        decoration: InputDecoration(
          hintText: AppStrings.newsSearchHint.tr(),
          hintStyle: AppTypography.body.copyWith(
            color: context.colors.textMutedForeground,
          ),
          filled: true,
          fillColor: context.colors.surface,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 16, right: 8),
            child: Icon(
              LucideIcons.search,
              size: 22,
              color: context.colors.textMutedForeground,
            ),
          ),
          suffixIcon: _text.text.isEmpty
              ? null
              : IconButton(
                  tooltip: AppStrings.newsSearchClear.tr(),
                  constraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                  icon: const Icon(LucideIcons.x, size: 18),
                  onPressed: _clear,
                ),
          border: const OutlineInputBorder(
            borderRadius: AppSpacing.radiusFull,
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: AppSpacing.radiusFull,
            borderSide: context.colors.shadow.isEmpty
                ? BorderSide(color: context.colors.border)
                : BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: AppSpacing.radiusFull,
            borderSide: BorderSide(
              color: context.colors.textForeground,
              width: 2.5,
            ),
          ),
        ),
      ),
    );
  }
}
