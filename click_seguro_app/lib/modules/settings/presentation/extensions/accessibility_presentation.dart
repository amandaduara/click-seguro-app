import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:click_seguro_app/modules/common/accessibility/accessibility_preferences.dart';
import 'package:click_seguro_app/modules/common/services/text_to_speech_service.dart';
import 'package:easy_localization/easy_localization.dart';

/// Nome e porcentagem de cada nível na tela de Acessibilidade (R2 de
/// specs/014-acessibilidade).
extension FontScaleLevelPresentation on FontScaleLevel {
  String get label => switch (this) {
    FontScaleLevel.standard => AppStrings.settingsAccessibilityFontStandard,
    FontScaleLevel.large => AppStrings.settingsAccessibilityFontLarge,
    FontScaleLevel.larger => AppStrings.settingsAccessibilityFontLarger,
    FontScaleLevel.largest => AppStrings.settingsAccessibilityFontLargest,
  }.tr();

  /// "100%", "115%"…: o mesmo nos dois idiomas.
  String get percentLabel => '${(factor * 100).round()}%';
}

/// Nome de cada velocidade (R5). As chaves da notícia são minúsculas, feitas
/// para "Velocidade: lenta"; aqui o nome aparece sozinho.
extension ReadingSpeedPresentation on ReadingSpeed {
  String get label => switch (this) {
    ReadingSpeed.slow => AppStrings.settingsAccessibilitySpeedSlow,
    ReadingSpeed.normal => AppStrings.settingsAccessibilitySpeedNormal,
    ReadingSpeed.fast => AppStrings.settingsAccessibilitySpeedFast,
  }.tr();
}
