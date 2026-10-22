import 'package:click_seguro_app/modules/activities/presentation/widgets/lesson_option_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../helpers/localized_app.dart';

void main() {
  late int taps;

  setUp(() => taps = 0);

  Future<void> pump(
    WidgetTester tester, {
    LessonOptionState state = LessonOptionState.idle,
    bool tappable = true,
    String text = 'Ignorar e denunciar',
  }) => pumpLocalized(
    tester,
    child: Scaffold(
      body: ListView(
        children: [
          LessonOptionCard(
            number: 1,
            text: text,
            state: state,
            onTap: tappable ? () => taps++ : null,
          ),
        ],
      ),
    ),
  );

  testWidgets('sem marcação: só o número e o texto', (tester) async {
    await pump(tester);

    expect(find.text('1'), findsOneWidget);
    expect(find.text('Ignorar e denunciar'), findsOneWidget);
    expect(find.byIcon(LucideIcons.circleDot), findsNothing);
    expect(
      tester.getSemantics(find.byType(LessonOptionCard)),
      isSemantics(
        isInMutuallyExclusiveGroup: true,
        hasCheckedState: true,
        isChecked: false,
        isEnabled: true,
      ),
    );
  });

  testWidgets('marcada: ícone de seleção e "selecionada" na semântica', (
    tester,
  ) async {
    await pump(tester, state: LessonOptionState.selected);

    expect(find.byIcon(LucideIcons.circleDot), findsOneWidget);
    expect(
      tester.getSemantics(find.byType(LessonOptionCard)),
      isSemantics(isInMutuallyExclusiveGroup: true, isChecked: true),
    );
  });

  testWidgets('correta e errada: ícone e texto, não só cor', (tester) async {
    await pump(tester, state: LessonOptionState.correct, tappable: false);
    expect(find.byIcon(LucideIcons.circleCheck), findsOneWidget);
    expect(find.text('correta'), findsOneWidget);

    await pump(tester, state: LessonOptionState.wrong, tappable: false);
    expect(find.byIcon(LucideIcons.circleX), findsOneWidget);
    expect(find.text('sua resposta, errada'), findsOneWidget);
    expect(
      tester.getSemantics(find.byType(LessonOptionCard)),
      isSemantics(label: '1\nIgnorar e denunciar\nsua resposta, errada'),
    );
  });

  testWidgets('toque escolhe; sem onTap não reage', (tester) async {
    await pump(tester);
    await tester.tap(find.text('Ignorar e denunciar'));
    expect(taps, 1);

    await pump(tester, tappable: false);
    await tester.tap(find.text('Ignorar e denunciar'));
    expect(taps, 1);
    expect(
      tester.getSemantics(find.byType(LessonOptionCard)),
      isSemantics(isEnabled: false),
    );
  });

  testWidgets('alvo de 48 ou mais', (tester) async {
    await pump(tester, text: 'Sim');

    expect(
      tester.getSize(find.byType(LessonOptionCard)).height,
      greaterThanOrEqualTo(48),
    );
  });

  testWidgets('texto longo com letra 2× quebra linha sem estouro', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await pump(tester, text: 'Uma alternativa bem comprida ' * 6);

    expect(tester.takeException(), isNull);
  });
}
