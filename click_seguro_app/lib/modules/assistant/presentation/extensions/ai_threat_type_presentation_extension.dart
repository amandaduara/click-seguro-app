import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:click_seguro_app/modules/assistant/domain/entities/ai_analysis_entity.dart';

extension AiThreatTypePresentation on AiThreatType? {
  String get labelKey => switch (this) {
    AiThreatType.phishing => AppStrings.assistantThreatPhishing,
    AiThreatType.fakeNews => AppStrings.assistantThreatFakeNews,
    AiThreatType.financialScam => AppStrings.assistantThreatFinancialScam,
    AiThreatType.socialEngineering =>
      AppStrings.assistantThreatSocialEngineering,
    AiThreatType.spam => AppStrings.assistantThreatSpam,
    AiThreatType.safe => AppStrings.assistantThreatSafe,
    AiThreatType.uncertain => AppStrings.assistantThreatUncertain,
    AiThreatType.unknown => AppStrings.assistantUnknown,
    null => AppStrings.assistantUnavailable,
  };
}
