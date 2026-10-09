import 'dart:ui';

import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Coluna de botões redondos à direita do Reel (design system §7.10):
/// navegação, curtir, salvar e abrir a fonte.
class ReelActions extends StatelessWidget {
  const ReelActions({
    super.key,
    required this.onPrevious,
    required this.onNext,
    required this.isLiked,
    required this.likesText,
    required this.likeLabel,
    required this.onLike,
    required this.isSaved,
    required this.saveLabel,
    required this.onSave,
    required this.onOpenSource,
  });

  static const Key previousKey = ValueKey('reels-previous');
  static const Key nextKey = ValueKey('reels-next');
  static const Key likeKey = ValueKey('reels-like');
  static const Key saveKey = ValueKey('reels-save');
  static const Key sourceKey = ValueKey('reels-source');

  /// `null` desabilita (primeiro ou último Reel).
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  final bool isLiked;

  /// Contagem já formatada ("1,2 mil").
  final String likesText;
  final String likeLabel;
  final VoidCallback onLike;

  /// Estado já resolvido: o visitante vê sempre `false` (FR-016).
  final bool isSaved;
  final String saveLabel;
  final VoidCallback onSave;

  /// `null` esconde o botão: Reel sem endereço válido (FR-020).
  final VoidCallback? onOpenSource;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final VoidCallback? openSource = onOpenSource;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _RoundButton(
          key: previousKey,
          icon: LucideIcons.chevronUp,
          label: AppStrings.newsReelsPrevious.tr(),
          onTap: onPrevious,
        ),
        _RoundButton(
          key: nextKey,
          icon: LucideIcons.chevronDown,
          label: AppStrings.newsReelsNext.tr(),
          onTap: onNext,
        ),
        const SizedBox(height: AppSpacing.s3),
        _RoundButton(
          key: likeKey,
          icon: LucideIcons.heart,
          selectedIcon: Icons.favorite,
          label: likeLabel,
          onTap: onLike,
          selected: isLiked,
          selectedColor: context.colors.primary,
        ),
        ExcludeSemantics(
          child: Text(
            likesText,
            style: textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: context.colors.textPrimaryForeground,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.s2),
        _RoundButton(
          key: saveKey,
          icon: LucideIcons.bookmark,
          selectedIcon: LucideIcons.bookmarkCheck,
          label: saveLabel,
          onTap: onSave,
          selected: isSaved,
          selectedColor: context.colors.textPrimaryForeground,
        ),
        if (openSource != null)
          _RoundButton(
            key: sourceKey,
            icon: LucideIcons.externalLink,
            label: AppStrings.newsReelsOpenSource.tr(),
            onTap: openSource,
          ),
      ],
    );
  }
}

/// Círculo de 40 px (branco 20% com desfoque) numa área de toque de 48 dp
/// (FR-021). Selecionado, usa [selectedIcon] na cor [selectedColor].
class _RoundButton extends StatelessWidget {
  const _RoundButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.selectedIcon,
    this.selected = false,
    this.selectedColor,
  });

  static const double _visualSize = 40;
  static const double _touchSize = 48;

  final IconData icon;

  /// Ícone no estado selecionado; sem ele, o mesmo [icon].
  final IconData? selectedIcon;
  final String label;
  final VoidCallback? onTap;
  final bool selected;

  /// `null` usa a cor do ícone sem seleção.
  final Color? selectedColor;

  @override
  Widget build(BuildContext context) {
    final bool enabled = onTap != null;
    final Color onDark = context.colors.textPrimaryForeground;
    final Color color = selected ? selectedColor ?? onDark : onDark;
    return Semantics(
      button: true,
      enabled: enabled,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox.square(
          dimension: _touchSize,
          child: Center(
            child: Opacity(
              opacity: enabled ? 1 : 0.4,
              child: ClipOval(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(
                    width: _visualSize,
                    height: _visualSize,
                    color: const Color(0x33FFFFFF),
                    alignment: Alignment.center,
                    child: Icon(
                      selected ? selectedIcon ?? icon : icon,
                      size: 20,
                      color: color,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
