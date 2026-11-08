import 'package:click_seguro_app/core/widgets/listen_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../helpers/localized_app.dart';

void main() {
  late int taps;

  setUp(() => taps = 0);

  Future<void> pump(
    WidgetTester tester, {
    required bool isSpeaking,
    bool disableAnimations = false,
  }) => pumpLocalized(
    tester,
    // Lendo, o halo pulsa por 6 s: o teste do pulso confere antes disso.
    settle: !isSpeaking || disableAnimations,
    child: MediaQuery(
      data: MediaQueryData(disableAnimations: disableAnimations),
      child: Scaffold(
        body: ListenButton(isSpeaking: isSpeaking, onPressed: () => taps++),
      ),
    ),
  );

  testWidgets('parado: "Ouvir" com o ícone de som', (tester) async {
    await pump(tester, isSpeaking: false);

    expect(find.text('Ouvir'), findsOneWidget);
    expect(find.byIcon(LucideIcons.volume2), findsOneWidget);
  });

  testWidgets('lendo: "Parar" com o ícone de parar', (tester) async {
    await pump(tester, isSpeaking: true);

    expect(find.text('Parar'), findsOneWidget);
    expect(find.byIcon(LucideIcons.square), findsOneWidget);
  });

  testWidgets('toque chama onPressed; botão com rótulo e 48+', (tester) async {
    await pump(tester, isSpeaking: false);

    await tester.tap(find.text('Ouvir'));
    await tester.pump();

    expect(taps, 1);
    expect(find.bySemanticsLabel('Ouvir'), findsOneWidget);
    expect(
      tester.getSize(find.byType(ListenButton)).height,
      greaterThanOrEqualTo(48),
    );
  });

  testWidgets('pílula do tamanho do texto, mesmo numa coluna esticada', (
    tester,
  ) async {
    await pump(tester, isSpeaking: false);

    expect(tester.getSize(find.byType(ListenButton)).width, lessThan(200));
  });

  testWidgets('lendo: o halo pulsa 3 vezes e depois fica parado (FR-020)', (
    tester,
  ) async {
    await pump(tester, isSpeaking: true);

    expect(tester.hasRunningAnimations, isTrue);
    await tester.pump(const Duration(seconds: 6));
    await tester.pump();
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('lendo com reduzir animações: nada pulsa (FR-021)', (
    tester,
  ) async {
    await pump(tester, isSpeaking: true, disableAnimations: true);

    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('parado: nada pulsa', (tester) async {
    await pump(tester, isSpeaking: false);

    expect(tester.hasRunningAnimations, isFalse);
  });
}
