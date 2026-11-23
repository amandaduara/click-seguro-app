import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/modules/authentication/presentation/widgets/terms_acceptance.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/localized_app.dart';

const String _sentence =
    'Li e aceito os Termos de uso e a Política de privacidade.';

void main() {
  late List<bool> changes;
  late int openedTerms;
  late int openedPrivacy;

  setUp(() {
    changes = [];
    openedTerms = 0;
    openedPrivacy = 0;
  });

  Future<void> pump(
    WidgetTester tester, {
    bool accepted = false,
    Locale locale = const Locale('pt', 'BR'),
  }) => pumpLocalized(
    tester,
    locale: locale,
    child: Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: TermsAcceptance(
          accepted: accepted,
          onChanged: changes.add,
          onOpenTerms: () => openedTerms++,
          onOpenPrivacy: () => openedPrivacy++,
        ),
      ),
    ),
  );

  BoxDecoration cardDecoration(WidgetTester tester) =>
      tester
              .widget<DecoratedBox>(
                find
                    .descendant(
                      of: find.byType(TermsAcceptance),
                      matching: find.byType(DecoratedBox),
                    )
                    .first,
              )
              .decoration
          as BoxDecoration;

  testWidgets('desmarcada: só o contorno e o cartão claro', (tester) async {
    await pump(tester);

    expect(find.byIcon(LucideIcons.check), findsNothing);
    final BoxDecoration card = cardDecoration(tester);
    expect(card.color, AppPalette.light.card);
    expect((card.border! as Border).top.color, AppPalette.light.border);
  });

  testWidgets('marcada: visto e cartão coral claro com borda coral', (
    tester,
  ) async {
    await pump(tester, accepted: true);

    expect(find.byIcon(LucideIcons.check), findsOneWidget);
    final BoxDecoration card = cardDecoration(tester);
    expect(card.color, AppPalette.light.primarySoft);
    expect((card.border! as Border).top.color, AppPalette.light.primary);
  });

  testWidgets('tocar no quadrado marca e desmarca', (tester) async {
    await pump(tester);
    await tester.tap(find.byType(TermsCheckbox));
    expect(changes, [true]);

    await pump(tester, accepted: true);
    await tester.tap(find.byType(TermsCheckbox));
    expect(changes, [true, false]);
  });

  testWidgets('tocar em "Li e aceito os" marca a caixa', (tester) async {
    await pump(tester);

    await tester.tapOnText(find.textRange.ofSubstring('Li e aceito'));

    expect(changes, [true]);
    expect(openedTerms + openedPrivacy, 0);
  });

  testWidgets('os links abrem os documentos sem mexer na caixa', (
    tester,
  ) async {
    await pump(tester);

    await tester.tapOnText(find.textRange.ofSubstring('Termos de uso'));
    await tester.tapOnText(
      find.textRange.ofSubstring('Política de privacidade'),
    );

    expect(openedTerms, 1);
    expect(openedPrivacy, 1);
    expect(changes, isEmpty);
  });

  testWidgets('área de toque da caixa com pelo menos 48 × 48', (tester) async {
    await pump(tester);

    final Size box = tester.getSize(find.byType(TermsCheckbox));
    expect(box.width, greaterThanOrEqualTo(48));
    expect(box.height, greaterThanOrEqualTo(48));
  });

  testWidgets('leitor de tela: caixa de seleção com o texto e o estado; '
      'os nomes dos documentos são links', (tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await pump(tester, accepted: true);

    expect(
      tester.getSemantics(find.byType(TermsCheckbox)),
      isSemantics(
        label: _sentence,
        hasCheckedState: true,
        isChecked: true,
        hasTapAction: true,
        isFocusable: true,
        hasEnabledState: true,
        isEnabled: true,
      ),
    );
    for (final String label in ['Termos de uso', 'Política de privacidade']) {
      expect(
        find.semantics
            .byLabel(label)
            .evaluate()
            .single
            .getSemanticsData()
            .flagsCollection
            .isLink,
        isTrue,
        reason: label,
      );
    }
    handle.dispose();
  });

  testWidgets('fonte 2× numa tela de 360: quebra sem estouro e mantém 48', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(1080, 2340)
      ..devicePixelRatio = 3;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await pump(tester);

    expect(tester.takeException(), isNull);
    final Size box = tester.getSize(find.byType(TermsCheckbox));
    expect(box.height, greaterThanOrEqualTo(48));
    expect(
      tester.getSize(find.byType(RichText).last).height,
      greaterThan(tester.getSize(find.byType(TermsCheckbox)).height),
    );
  });

  testWidgets('em inglês', (tester) async {
    await pump(tester, locale: const Locale('en', 'US'));

    expect(
      find.textContaining(
        'I have read and accept the Terms of use and the Privacy policy.',
        findRichText: true,
      ),
      findsOneWidget,
    );
  });
}
