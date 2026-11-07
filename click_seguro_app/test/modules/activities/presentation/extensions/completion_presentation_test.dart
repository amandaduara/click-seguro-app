import 'package:click_seguro_app/core/constants/app_identity.dart';
import 'package:click_seguro_app/modules/activities/domain/entities/module_score_entity.dart';
import 'package:click_seguro_app/modules/activities/presentation/extensions/completion_presentation.dart';
import 'package:click_seguro_app/modules/activities/presentation/pages/completion_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/localized_app.dart';

void main() {
  ModuleCompletion completion(int? score, [int total = 3]) => ModuleCompletion(
    title: 'Golpes Digitais',
    score: score == null ? null : ModuleScoreEntity(score: score, total: total),
  );

  test('faixa da mensagem pelo resultado (data-model)', () {
    expect(completion(3).tier, ModuleCompletionTier.perfect);
    expect(completion(2).tier, ModuleCompletionTier.good);
    expect(completion(2, 4).tier, ModuleCompletionTier.good);
    expect(completion(1).tier, ModuleCompletionTier.retry);
    expect(completion(0).tier, ModuleCompletionTier.retry);
    expect(completion(null).tier, ModuleCompletionTier.good);
  });

  testWidgets('texto falado: título, pontuação e mensagem', (tester) async {
    await pumpLocalized(tester, child: const SizedBox());

    expect(
      completion(2).spokenText,
      'Módulo concluído!\n'
      'Você acertou 2 de 3.\n'
      'Muito bem! Você já sabe se proteger desses golpes.',
    );
    expect(
      completion(null).spokenText,
      'Módulo concluído!\n'
      'Muito bem! Você já sabe se proteger desses golpes.',
    );
  });

  testWidgets('texto para compartilhar, com e sem pontuação', (tester) async {
    await pumpLocalized(tester, child: const SizedBox());

    expect(
      completion(3).shareText,
      'Concluí o módulo Golpes Digitais no ${AppIdentity.name} e acertei 3 de '
      '3 perguntas! Aprenda a se proteger de golpes também.',
    );
    expect(
      completion(null).shareText,
      'Concluí o módulo Golpes Digitais no ${AppIdentity.name}! Aprenda a se '
      'proteger de golpes também.',
    );
  });

  testWidgets('em inglês', (tester) async {
    await pumpLocalized(
      tester,
      child: const SizedBox(),
      locale: const Locale('en', 'US'),
    );

    expect(completion(1).spokenText, startsWith('Module completed!\n'));
    expect(
      completion(3).shareText,
      'I completed the Golpes Digitais module on ${AppIdentity.name} and got 3 '
      'of 3 questions right! Learn to protect yourself from scams too.',
    );
  });
}
