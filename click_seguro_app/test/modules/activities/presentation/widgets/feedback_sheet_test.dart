import 'package:click_seguro_app/modules/activities/data/models/answer_result_model.dart';
import 'package:click_seguro_app/modules/activities/data/models/module_detail_model.dart';
import 'package:click_seguro_app/modules/activities/domain/entities/answer_result_entity.dart';
import 'package:click_seguro_app/modules/activities/domain/entities/lesson_entity.dart';
import 'package:click_seguro_app/modules/activities/domain/entities/module_score_entity.dart';
import 'package:click_seguro_app/modules/activities/presentation/widgets/feedback_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../helpers/localized_app.dart';
import '../../fakes/activities_fixtures.dart';

void main() {
  final LessonEntity lesson = ModuleDetailModel.fromJson(
    moduleDetailJson(),
  ).toEntity().lessons.first;

  AnswerResultEntity result({
    bool isCorrect = true,
    String correctOptionId = 'l1-o1',
    String? explanation = 'Promessas de dinheiro em dobro são golpe.',
  }) => AnswerResultModel.fromJson(
    answerJson(
      isCorrect: isCorrect,
      correctOptionId: correctOptionId,
      explanation: explanation,
    ),
  ).toEntity();

  late List<FeedbackAction?> actions;

  setUp(() => actions = []);

  /// Uma tela com um botão que abre o painel e guarda o que ele devolveu.
  Future<void> openSheet(
    WidgetTester tester, {
    AnswerResultEntity? answer,
    bool isLast = false,
    ModuleScoreEntity? score,
  }) async {
    await pumpLocalized(
      tester,
      child: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () async => actions.add(
                await showFeedbackSheet(
                  context,
                  lesson: lesson,
                  result: answer ?? result(),
                  isLast: isLast,
                  score: score,
                ),
              ),
              child: const Text('abrir'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
  }

  testWidgets('acerto: título com ícone, a correta e a explicação', (
    tester,
  ) async {
    await openSheet(tester);

    expect(find.text('Você acertou!'), findsOneWidget);
    expect(find.byIcon(LucideIcons.circleCheck), findsOneWidget);
    expect(find.text('Resposta correta: Ignorar e denunciar'), findsOneWidget);
    expect(find.text('Por quê?'), findsOneWidget);
    expect(
      find.text('Promessas de dinheiro em dobro são golpe.'),
      findsOneWidget,
    );
  });

  testWidgets('erro: "Não foi dessa vez" com ícone de erro', (tester) async {
    await openSheet(tester, answer: result(isCorrect: false));

    expect(find.text('Não foi dessa vez'), findsOneWidget);
    expect(find.byIcon(LucideIcons.circleX), findsOneWidget);
  });

  testWidgets('sem explicação: nem título nem texto', (tester) async {
    await openSheet(tester, answer: result(explanation: null));

    expect(find.text('Por quê?'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('correta fora das alternativas: sem a linha, sem erro', (
    tester,
  ) async {
    await openSheet(tester, answer: result(correctOptionId: 'zz'));

    expect(find.textContaining('Resposta correta'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tocar fora ou arrastar não fecha; voltar fecha com null', (
    tester,
  ) async {
    await openSheet(tester);

    await tester.tapAt(const Offset(20, 20));
    await tester.pumpAndSettle();
    expect(find.text('Você acertou!'), findsOneWidget);

    await tester.drag(find.text('Você acertou!'), const Offset(0, 500));
    await tester.pumpAndSettle();
    expect(find.text('Você acertou!'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Você acertou!'), findsNothing);
    expect(actions, [null]);
  });

  testWidgets('"Próxima pergunta" devolve next', (tester) async {
    await openSheet(tester);

    await tester.tap(find.text('Próxima pergunta'));
    await tester.pumpAndSettle();

    expect(actions, [FeedbackAction.next]);
  });

  testWidgets('na última: "Voltar às atividades" devolve finish', (
    tester,
  ) async {
    await openSheet(tester, isLast: true);

    expect(find.text('Próxima pergunta'), findsNothing);
    await tester.tap(find.text('Voltar às atividades'));
    await tester.pumpAndSettle();

    expect(actions, [FeedbackAction.finish]);
  });

  testWidgets('dois toques rápidos fecham só o painel (achado U1)', (
    tester,
  ) async {
    await openSheet(tester);

    await tester.tap(find.text('Próxima pergunta'));
    await tester.tap(find.text('Próxima pergunta'), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(actions, [FeedbackAction.next]);
    expect(find.text('abrir'), findsOneWidget);
  });

  testWidgets('o título é anunciado ao abrir', (tester) async {
    await openSheet(tester);

    expect(
      tester.getSemantics(find.text('Você acertou!')),
      isSemantics(isLiveRegion: true),
    );
  });

  testWidgets('explicação longa com letra 2×: rola sem estouro', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await openSheet(
      tester,
      answer: result(explanation: 'Uma explicação bem comprida. ' * 40),
    );

    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(
      find.text('Próxima pergunta'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Próxima pergunta'), findsOneWidget);
  });
}
