import 'package:click_seguro_app/core/theme/app_motion.dart';
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

  group('balanço da errada', () {
    /// Começa escolhida e passa a errada, como depois da correção: o balanço
    /// só acontece na troca para errada.
    Future<ValueNotifier<LessonOptionState>> pumpSwitchable(
      WidgetTester tester, {
      bool reduceMotion = false,
    }) async {
      final state = ValueNotifier(LessonOptionState.selected);
      addTearDown(state.dispose);
      await pumpLocalized(
        tester,
        child: AppMotionScope(
          appReduceMotion: reduceMotion,
          child: Scaffold(
            body: ListView(
              children: [
                ValueListenableBuilder<LessonOptionState>(
                  valueListenable: state,
                  builder: (_, value, _) => LessonOptionCard(
                    number: 1,
                    text: 'Ignorar e denunciar',
                    state: value,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      return state;
    }

    double textLeft(WidgetTester tester) =>
        tester.getTopLeft(find.text('Ignorar e denunciar')).dx;

    testWidgets('errada balança para os lados e volta ao lugar', (
      tester,
    ) async {
      final state = await pumpSwitchable(tester);
      final double rest = textLeft(tester);

      state.value = LessonOptionState.wrong;
      await tester.pump();
      // 1/4 da animação de 500 ms: no ponto mais à esquerda (−6 px).
      await tester.pump(const Duration(milliseconds: 125));
      // A borda engrossa 0,5 px junto; o balanço passa bem disso.
      expect(textLeft(tester), lessThan(rest - 4));
      // Na metade: no ponto mais à direita (+6 px); em 3/4, à esquerda de
      // novo (duas idas e voltas).
      await tester.pump(const Duration(milliseconds: 125));
      expect(textLeft(tester), greaterThan(rest + 4));
      await tester.pump(const Duration(milliseconds: 125));
      expect(textLeft(tester), lessThan(rest - 4));

      await tester.pumpAndSettle();
      expect(textLeft(tester), closeTo(rest, 1));
    });

    testWidgets('certa não balança', (tester) async {
      final state = await pumpSwitchable(tester);
      final double rest = textLeft(tester);

      state.value = LessonOptionState.correct;
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 125));

      expect(textLeft(tester), closeTo(rest, 1));
      await tester.pumpAndSettle();
    });

    testWidgets('com "Reduzir animações" do app, não balança', (tester) async {
      final state = await pumpSwitchable(tester, reduceMotion: true);
      final double rest = textLeft(tester);

      state.value = LessonOptionState.wrong;
      for (final ms in [0, 125, 250, 125]) {
        await tester.pump(Duration(milliseconds: ms));
        expect(textLeft(tester), closeTo(rest, 1));
      }
      expect(find.text('sua resposta, errada'), findsOneWidget);
      // Sem animação, o status entra sem quebrar o layout.
      expect(tester.takeException(), isNull);
    });

    testWidgets('com "remover animações" do aparelho, não balança', (
      tester,
    ) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      final state = await pumpSwitchable(tester);
      final double rest = textLeft(tester);

      state.value = LessonOptionState.wrong;
      for (final ms in [0, 125, 250, 125]) {
        await tester.pump(Duration(milliseconds: ms));
        expect(textLeft(tester), closeTo(rest, 1));
      }
    });
  });
}
