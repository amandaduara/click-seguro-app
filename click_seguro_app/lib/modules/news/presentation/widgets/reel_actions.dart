import 'dart:ui';

import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:click_seguro_app/core/theme/app_motion.dart';
import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:click_seguro_app/core/widgets/safe_skeleton.dart';
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
    this.likePulse = 0,
  });

  static const Key previousKey = ValueKey('reels-previous');
  static const Key nextKey = ValueKey('reels-next');
  static const Key likeKey = ValueKey('reels-like');
  static const Key saveKey = ValueKey('reels-save');
  static const Key sourceKey = ValueKey('reels-source');
  static const Key likePulseKey = ValueKey('reels-like-pulse');

  /// `null` desabilita (primeiro ou último Reel).
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  final bool isLiked;

  /// Contagem já formatada ("1,2 mil").
  final String likesText;
  final String likeLabel;
  final VoidCallback onLike;

  /// Muda para pulsar o coração sem mudar a curtida (dois toques num Reel
  /// já curtido).
  final int likePulse;

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
        _LikePulse(
          liked: isLiked,
          pulse: likePulse,
          child: _RoundButton(
            key: likeKey,
            icon: LucideIcons.heart,
            selectedIcon: Icons.favorite,
            label: likeLabel,
            onTap: onLike,
            selected: isLiked,
            selectedColor: context.colors.primary,
          ),
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

/// Pulso do coração (1 → 1,3 → 1, `AppMotion.long`) ao curtir ou quando
/// [pulse] muda (specs/022 R13). Descurtir não pulsa.
class _LikePulse extends StatefulWidget {
  const _LikePulse({
    required this.liked,
    required this.pulse,
    required this.child,
  });

  final bool liked;
  final int pulse;
  final Widget child;

  @override
  State<_LikePulse> createState() => _LikePulseState();
}

class _LikePulseState extends State<_LikePulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this);
  late final Animation<double> _scale = _controller.drive(
    TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1,
          end: 1.3,
        ).chain(CurveTween(curve: AppMotion.enter)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.3,
          end: 1,
        ).chain(CurveTween(curve: AppMotion.emphasis)),
        weight: 60,
      ),
    ]),
  );

  @override
  void didUpdateWidget(_LikePulse oldWidget) {
    super.didUpdateWidget(oldWidget);
    final bool liked = widget.liked && !oldWidget.liked;
    if (liked || widget.pulse != oldWidget.pulse) {
      _controller.duration = AppMotion.of(context).long;
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ScaleTransition(
    key: ReelActions.likePulseKey,
    scale: _scale,
    child: widget.child,
  );
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
    // Desabilitado: cor com alfa, sem desfoque nem `Opacity`, que pesam por
    // cima da imagem (specs/022 T047). No esqueleto, o círculo vira uma barra
    // só.
    final Widget circle = SafeSkeleton.leaf(
      Container(
        width: _visualSize,
        height: _visualSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: enabled ? const Color(0x33FFFFFF) : const Color(0x14FFFFFF),
        ),
        alignment: Alignment.center,
        child: Icon(
          selected ? selectedIcon ?? icon : icon,
          size: 20,
          color: enabled ? color : color.withValues(alpha: 0.4),
        ),
      ),
    );
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
            child: enabled
                ? ClipOval(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                      child: circle,
                    ),
                  )
                : circle,
          ),
        ),
      ),
    );
  }
}
