import 'dart:ui' show Locale;

import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:click_seguro_app/modules/settings/domain/entities/language_choice.dart';
import 'package:easy_localization/easy_localization.dart';

/// Rótulo e idioma de cada escolha (R5 de specs/013-configuracoes).
extension LanguageChoicePresentation on LanguageChoice {
  static const Locale portugueseLocale = Locale('pt', 'BR');
  static const Locale englishLocale = Locale('en', 'US');

  /// "Português" e "English" aparecem sempre no próprio idioma.
  String get label => switch (this) {
    LanguageChoice.device => AppStrings.settingsLanguageDevice.tr(),
    LanguageChoice.portuguese => AppStrings.settingsLanguagePortuguese.tr(),
    LanguageChoice.english => AppStrings.settingsLanguageEnglish.tr(),
  };

  /// Idioma do app para esta escolha; [device] segue o aparelho (inglês se
  /// o aparelho estiver em inglês; qualquer outro, português).
  Locale localeFor(Locale deviceLocale) => switch (this) {
    LanguageChoice.portuguese => portugueseLocale,
    LanguageChoice.english => englishLocale,
    LanguageChoice.device =>
      deviceLocale.languageCode == englishLocale.languageCode
          ? englishLocale
          : portugueseLocale,
  };
}
