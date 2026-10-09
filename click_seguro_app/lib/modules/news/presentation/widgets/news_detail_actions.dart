import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:click_seguro_app/core/widgets/safe_button.dart';
import 'package:click_seguro_app/modules/news/presentation/extensions/reel_presentation_extension.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Ações da notícia aberta (RF-016, RF-017, RF-019): salvar, compartilhar e
/// abrir a fonte, todos com ícone e texto. "Abrir fonte" só aparece com
/// [onOpenSource].
class NewsDetailActions extends StatelessWidget {
  const NewsDetailActions({
    super.key,
    required this.isSaved,
    required this.onSave,
    required this.onShare,
    required this.onOpenSource,
  });

  static const Key saveKey = ValueKey('detail-save');
  static const Key shareKey = ValueKey('detail-share');
  static const Key sourceKey = ValueKey('detail-source');

  /// Estado já resolvido pela página: o visitante vê sempre `false`.
  final bool isSaved;
  final VoidCallback onSave;
  final VoidCallback onShare;

  /// `null` → sem endereço válido, sem botão.
  final VoidCallback? onOpenSource;

  @override
  Widget build(BuildContext context) {
    final String saveLabel = saveSemanticLabel(isSaved: isSaved);
    final VoidCallback? openSource = onOpenSource;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.s3),
      // Wrap: com fonte 2× os botões passam para a linha de baixo.
      child: Wrap(
        runSpacing: AppSpacing.s2,
        children: [
          _action(
            key: saveKey,
            label: saveLabel,
            selected: isSaved,
            tone: isSaved ? SafeButtonTone.secondary : SafeButtonTone.ghost,
            icon: isSaved ? LucideIcons.bookmarkCheck : LucideIcons.bookmark,
            onPressed: onSave,
          ),
          _action(
            key: shareKey,
            label: AppStrings.newsDetailShare.tr(),
            icon: LucideIcons.share2,
            onPressed: onShare,
          ),
          if (openSource != null)
            _action(
              key: sourceKey,
              label: AppStrings.newsReelsOpenSource.tr(),
              icon: LucideIcons.externalLink,
              onPressed: openSource,
            ),
        ],
      ),
    );
  }

  Widget _action({
    required Key key,
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    bool selected = false,
    SafeButtonTone tone = SafeButtonTone.ghost,
  }) => Semantics(
    button: true,
    selected: selected,
    label: label,
    excludeSemantics: true,
    child: SafeButton(
      key: key,
      label: label,
      tone: tone,
      icon: Icon(icon),
      onPressed: onPressed,
    ),
  );
}
