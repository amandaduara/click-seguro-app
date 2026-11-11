import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:click_seguro_app/modules/assistant/domain/entities/ai_analysis_entity.dart';
import 'package:click_seguro_app/modules/assistant/presentation/extensions/ai_analysis_presentation_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/localized_app.dart';

AiAnalysisEntity _analysis({
  AiThreatType? threat = AiThreatType.phishing,
  AiAnalysisStatus status = AiAnalysisStatus.success,
  String? explanation = 'É golpe.',
  List<String> tips = const ['Não clique.', 'Apague.'],
}) => AiAnalysisEntity(
  id: 'a1',
  feature: AiAnalysisFeature.analyze,
  threatType: threat,
  riskScore: 90,
  confidence: 80,
  explanation: explanation,
  tips: tips,
  status: status,
  createdAt: DateTime(2026, 11, 10),
);

void main() {
  group('riskLevel', () {
    test(
      'ameaça conhecida: alto; seguro: baixo; incerto ou sem tipo: médio',
      () {
        expect(_analysis().riskLevel, AssistantRiskLevel.high);
        expect(
          _analysis(threat: AiThreatType.safe).riskLevel,
          AssistantRiskLevel.low,
        );
        for (final threat in [
          AiThreatType.uncertain,
          AiThreatType.unknown,
          null,
        ]) {
          expect(
            _analysis(threat: threat).riskLevel,
            AssistantRiskLevel.medium,
          );
        }
      },
    );

    test('a chave do selo de cada nível', () {
      expect(AssistantRiskLevel.high.labelKey, AppStrings.assistantRiskHigh);
      expect(
        AssistantRiskLevel.medium.labelKey,
        AppStrings.assistantRiskMedium,
      );
      expect(AssistantRiskLevel.low.labelKey, AppStrings.assistantRiskLow);
    });
  });

  // Leitura automática do resultado (validação da usuária, specs/023).
  group('spokenText', () {
    testWidgets('sucesso: selo, explicação e cuidados, nessa ordem', (
      tester,
    ) async {
      await pumpLocalized(tester, child: const SizedBox());

      expect(
        _analysis().spokenText,
        'Alto risco de golpe.\nÉ golpe.\nNão clique.\nApague.',
      );
    });

    testWidgets('sem explicação nem cuidados, só o selo', (tester) async {
      await pumpLocalized(tester, child: const SizedBox());

      expect(
        _analysis(explanation: '  ', tips: []).spokenText,
        'Alto risco de golpe.',
      );
    });

    testWidgets('falha: só a mensagem do status', (tester) async {
      await pumpLocalized(tester, child: const SizedBox());

      expect(
        _analysis(status: AiAnalysisStatus.rateLimited).spokenText,
        'Muitas solicitações. Aguarde um pouco e tente de novo.',
      );
    });
  });
}
