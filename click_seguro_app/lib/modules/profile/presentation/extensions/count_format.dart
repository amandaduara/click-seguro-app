import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:easy_localization/easy_localization.dart';

/// "999", "1 mil", "1,2 mil" (en-US: "1.2K"); a casa decimal é cortada.
///
/// Mesma regra do `formatLikesCount` do módulo `news`, copiada porque o
/// perfil não importa outro módulo (Princípio I).
String formatCount(int count) {
  if (count < 1000) return '$count';
  final int whole = count ~/ 1000;
  final int tenth = count % 1000 ~/ 100;
  final String value = tenth == 0
      ? '$whole'
      : '$whole${AppStrings.newsDecimalSeparator.tr()}$tenth';
  return AppStrings.newsReelsThousand.tr(args: [value]);
}
