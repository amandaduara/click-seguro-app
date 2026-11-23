import 'package:click_seguro_app/modules/common/presentation/controller/read_aloud_controller.dart';
import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:click_seguro_app/modules/assistant/domain/entities/ai_analysis_entity.dart';
import 'package:easy_localization/easy_localization.dart';

/// Nível de risco do selo do resultado (quadro "10 Assistente").
enum AssistantRiskLevel {
  high(AppStrings.assistantRiskHigh),
  medium(AppStrings.assistantRiskMedium),
  low(AppStrings.assistantRiskLow);

  const AssistantRiskLevel(this.labelKey);

  /// Chave do texto do selo ("Alto risco de golpe"…).
  final String labelKey;
}

/// O resultado da verificação na tela e na voz.
extension AiAnalysisPresentation on AiAnalysisEntity {
  /// Ameaça conhecida: alto; seguro: baixo; incerto ou sem tipo: médio.
  AssistantRiskLevel get riskLevel => switch (threatType) {
    AiThreatType.safe => AssistantRiskLevel.low,
    AiThreatType.unknown ||
    AiThreatType.uncertain ||
    null => AssistantRiskLevel.medium,
    _ => AssistantRiskLevel.high,
  };

  /// Chave da mensagem de uma análise que não deu certo.
  String get statusMessageKey => switch (status) {
    AiAnalysisStatus.error => AppStrings.assistantStatusError,
    AiAnalysisStatus.rateLimited => AppStrings.assistantStatusRateLimited,
    _ => AppStrings.assistantUnknown,
  };

  /// O que a leitura fala: o selo, a explicação e os cuidados,
  /// na ordem do cartão; numa falha, só a mensagem (validação da usuária,
  /// specs/024).
  List<SpeechPart> get spokenParts {
    if (status != AiAnalysisStatus.success) {
      return [SpeechPart(statusMessageKey.tr())];
    }
    final String? text = explanation?.trim();
    // O selo é texto do app; a explicação e os cuidados vêm da IA, em
    // português, e saem na voz em português (specs/025).
    return [
      SpeechPart('${riskLevel.labelKey.tr()}.'),
      if (text != null && text.isNotEmpty) SpeechPart(text, content: true),
      for (final String tip in tips)
        if (tip.trim().isNotEmpty) SpeechPart(tip.trim(), content: true),
    ];
  }
}
