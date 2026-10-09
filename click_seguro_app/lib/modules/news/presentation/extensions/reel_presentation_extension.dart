import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:click_seguro_app/modules/news/domain/entities/reel_entity.dart';
import 'package:click_seguro_app/modules/news/presentation/extensions/news_presentation_extension.dart';
import 'package:easy_localization/easy_localization.dart';

/// Textos da tela de Reels (data-model de specs/008-reels-curtir-salvar).
extension ReelPresentation on ReelEntity {
  /// "999", "1 mil", "1,2 mil" (en-US: "1.2K"); a casa decimal é cortada.
  String get formattedLikes {
    if (likesCount < 1000) return '$likesCount';
    final int whole = likesCount ~/ 1000;
    final int tenth = likesCount % 1000 ~/ 100;
    final String value = tenth == 0
        ? '$whole'
        : '$whole${AppStrings.newsDecimalSeparator.tr()}$tenth';
    return AppStrings.newsReelsThousand.tr(args: [value]);
  }

  /// O que o leitor de tela lê sobre o Reel: título, fonte, data e
  /// categorias, como no cartão do feed.
  String semanticLabel(DateTime now) => news.semanticLabel(now);

  /// "Curtir, 3 curtidas" / "Curtido, 4 curtidas" (FR-021).
  String get likeSemanticLabel =>
      (isLiked ? AppStrings.newsReelsLiked : AppStrings.newsReelsLike).tr(
        args: [formattedLikes],
      );
}

/// "Salvar" / "Salvo". Recebe o estado já resolvido: o visitante vê sempre
/// "Salvar" (FR-016).
String saveSemanticLabel({required bool isSaved}) =>
    (isSaved ? AppStrings.newsReelsSaved : AppStrings.newsReelsSave).tr();
