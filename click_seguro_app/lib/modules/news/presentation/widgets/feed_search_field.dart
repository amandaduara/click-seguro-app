import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
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

  void _clear() {
    _text.clear();
    setState(() {});
    widget.onCleared();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s5),
      child: TextField(
        controller: _text,
        onChanged: (value) {
          setState(() {});
          widget.onChanged(value);
        },
        textInputAction: TextInputAction.search,
        style: textTheme.bodyLarge?.copyWith(fontSize: 16),
        decoration: InputDecoration(
          hintText: AppStrings.newsSearchHint.tr(),
          hintStyle: textTheme.bodyLarge?.copyWith(
            fontSize: 16,
            color: context.colors.textMutedForeground,
          ),
          filled: true,
          fillColor: context.colors.input.withValues(alpha: 0.4),
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          prefixIcon: Icon(
            LucideIcons.search,
            size: 20,
            color: context.colors.textMutedForeground,
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
          border: OutlineInputBorder(
            borderRadius: AppSpacing.radiusFull,
            borderSide: BorderSide(color: context.colors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: AppSpacing.radiusFull,
            borderSide: BorderSide(color: context.colors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: AppSpacing.radiusFull,
            borderSide: BorderSide(color: context.colors.primary),
          ),
        ),
      ),
    );
  }
}
