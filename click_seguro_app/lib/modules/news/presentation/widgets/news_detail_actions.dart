import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:click_seguro_app/core/widgets/safe_button.dart';
import 'package:click_seguro_app/modules/news/presentation/extensions/reel_presentation_extension.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Ações da notícia aberta (RF-019): por ora o botão de salvar, com ícone e
/// texto ("Salvar"/"Salvo"); compartilhar e abrir a fonte entram aqui.
class NewsDetailActions extends StatelessWidget {
  const NewsDetailActions({
    super.key,
    required this.isSaved,
    required this.onSave,
  });

  static const Key saveKey = ValueKey('detail-save');

  /// Estado já resolvido pela página: o visitante vê sempre `false`.
  final bool isSaved;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final String label = saveSemanticLabel(isSaved: isSaved);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.s3),
        Semantics(
          button: true,
          selected: isSaved,
          label: label,
          excludeSemantics: true,
          child: SafeButton(
            key: saveKey,
            label: label,
            tone: isSaved ? SafeButtonTone.secondary : SafeButtonTone.ghost,
            icon: Icon(
              isSaved ? LucideIcons.bookmarkCheck : LucideIcons.bookmark,
            ),
            onPressed: onSave,
          ),
        ),
      ],
    );
  }
}
