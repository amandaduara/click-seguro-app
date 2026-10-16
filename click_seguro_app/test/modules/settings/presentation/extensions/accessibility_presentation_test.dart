import 'package:click_seguro_app/modules/common/accessibility/accessibility_preferences.dart';
import 'package:click_seguro_app/modules/common/services/text_to_speech_service.dart';
import 'package:click_seguro_app/modules/settings/presentation/extensions/accessibility_presentation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/localized_app.dart';

void main() {
  test('porcentagem de cada nível', () {
    expect(
      [for (final level in FontScaleLevel.values) level.percentLabel],
      ['100%', '115%', '130%', '150%'],
    );
  });

  testWidgets('nome de cada nível de letra', (tester) async {
    await pumpLocalized(tester, child: const SizedBox());

    expect(
      [for (final level in FontScaleLevel.values) level.label],
      ['Padrão', 'Grande', 'Maior', 'Muito grande'],
    );
  });

  testWidgets('nome de cada velocidade', (tester) async {
    await pumpLocalized(tester, child: const SizedBox());

    expect(
      [for (final speed in ReadingSpeed.values) speed.label],
      ['Lenta', 'Normal', 'Rápida'],
    );
  });

  testWidgets('em inglês', (tester) async {
    await pumpLocalized(
      tester,
      child: const SizedBox(),
      locale: const Locale('en', 'US'),
    );

    expect(
      [for (final level in FontScaleLevel.values) level.label],
      ['Default', 'Large', 'Larger', 'Extra large'],
    );
    expect(
      [for (final speed in ReadingSpeed.values) speed.label],
      ['Slow', 'Normal', 'Fast'],
    );
  });
}
