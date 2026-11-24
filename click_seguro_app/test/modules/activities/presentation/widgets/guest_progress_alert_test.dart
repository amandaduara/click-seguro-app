import 'package:click_seguro_app/core/widgets/safe_button.dart';
import 'package:click_seguro_app/modules/activities/presentation/widgets/guest_progress_alert.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/localized_app.dart';

void main() {
  late List<GuestAlertAction?> actions;

  setUp(() => actions = []);

  Future<void> openAlert(
    WidgetTester tester, {
    Locale locale = const Locale('pt', 'BR'),
  }) async {
    await pumpLocalized(
      tester,
      locale: locale,
      child: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () async =>
                  actions.add(await showGuestProgressAlert(context)),
              child: const Text('abrir'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
  }

  testWidgets('título anunciado, texto e os dois botões', (tester) async {
    await openAlert(tester);

    expect(find.text('Guarde seu progresso'), findsOneWidget);
    expect(
      tester.getSemantics(find.text('Guarde seu progresso')),
      isSemantics(isHeader: true),
    );
    expect(find.textContaining('vale só até fechar o app'), findsOneWidget);
    for (final label in ['Criar conta', 'Continuar sem conta']) {
      expect(
        tester.getSize(find.widgetWithText(SafeButton, label)).height,
        greaterThanOrEqualTo(48),
      );
    }
  });

  testWidgets('"Criar conta" devolve createAccount', (tester) async {
    await openAlert(tester);

    await tester.tap(find.text('Criar conta'));
    await tester.pumpAndSettle();

    expect(actions, [GuestAlertAction.createAccount]);
  });

  testWidgets('"Continuar sem conta" devolve continueWithoutAccount', (
    tester,
  ) async {
    await openAlert(tester);

    await tester.tap(find.text('Continuar sem conta'));
    await tester.pumpAndSettle();

    expect(actions, [GuestAlertAction.continueWithoutAccount]);
  });

  testWidgets('voltar do aparelho fecha devolvendo null', (tester) async {
    await openAlert(tester);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(actions, [null]);
  });

  testWidgets('letra 2×: rola sem estouro', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await openAlert(tester);
    await tester.scrollUntilVisible(
      find.text('Continuar sem conta'),
      200,
      scrollable: find.byType(Scrollable).last,
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('em inglês', (tester) async {
    await openAlert(tester, locale: const Locale('en', 'US'));

    expect(find.text('Keep your progress'), findsOneWidget);
    expect(find.text('Continue without an account'), findsOneWidget);
  });
}
