import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:click_seguro_app/modules/common/services/text_to_speech_service.dart';
import 'package:click_seguro_app/modules/news/domain/entities/news_detail_entity.dart';
import 'package:easy_localization/easy_localization.dart';

/// Textos da tela de detalhe (data-model de specs/010-detalhe-noticia).
extension NewsDetailPresentation on NewsDetailEntity {
  /// Há texto além de espaços; senão a tela avisa que não está disponível.
  bool get hasContent => content.trim().isNotEmpty;

  /// Minutos de leitura do texto, a 200 palavras por minuto e pelo menos 1;
  /// `null` sem texto.
  int? get readingMinutes {
    if (!hasContent) return null;
    final int words = content.trim().split(RegExp(r'\s+')).length;
    return (words / 200).ceil();
  }

  /// O que a voz lê: título e texto; sem texto, só o título.
  String get spokenText =>
      hasContent ? '${news.title}.\n\n${content.trim()}' : news.title;

  /// O que o menu de compartilhar leva: título, fonte e endereço da fonte,
  /// em linhas; sem endereço válido, só título e fonte (FR-019).
  String get shareText => [
    news.title,
    news.source,
    if (hasSource) news.sourceUrl.trim(),
  ].where((line) => line.trim().isNotEmpty).join('\n');
}

/// "lenta", "normal" ou "rápida".
String readingSpeedName(ReadingSpeed speed) => switch (speed) {
  ReadingSpeed.slow => AppStrings.newsDetailSpeedSlow,
  ReadingSpeed.normal => AppStrings.newsDetailSpeedNormal,
  ReadingSpeed.fast => AppStrings.newsDetailSpeedFast,
}.tr();

/// "Velocidade: normal".
String speedSemanticLabel(ReadingSpeed speed) =>
    AppStrings.newsDetailSpeed.tr(args: [readingSpeedName(speed)]);

/// Rótulo curto da pílula: "0,5x" (lenta), "1x" (normal) ou "2x" (rápida).
/// Normal é a base (1x); as outras seguem a escala de dobro/metade, a mais
/// próxima do "1x / 2x" pedido para apenas três velocidades.
String readingSpeedShort(ReadingSpeed speed) => switch (speed) {
  ReadingSpeed.slow => AppStrings.newsDetailSpeedShortSlow,
  ReadingSpeed.normal => AppStrings.newsDetailSpeedShortNormal,
  ReadingSpeed.fast => AppStrings.newsDetailSpeedShortFast,
}.tr();

/// A próxima velocidade da pílula: 1x → 2x → 0,5x → 1x.
ReadingSpeed nextReadingSpeed(ReadingSpeed speed) => switch (speed) {
  ReadingSpeed.normal => ReadingSpeed.fast,
  ReadingSpeed.fast => ReadingSpeed.slow,
  ReadingSpeed.slow => ReadingSpeed.normal,
};
