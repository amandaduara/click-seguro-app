import 'package:click_seguro_app/modules/settings/domain/entities/language_choice.dart';
import 'package:click_seguro_app/modules/settings/presentation/widgets/language_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../helpers/localized_app.dart';

void main() {
  Future<void> openSheet(WidgetTester tester, LanguageChoice current) async {
    await pumpLocalized(
      tester,
      child: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => showLanguageSheet(context, current: current),
            child: const Text('abrir'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
  }

  Finder tileOf(String label) =>
      find.ancestor(of: find.text(label), matching: find.byType(InkWell)).first;

  for (final (choice, label) in [
    (LanguageChoice.portuguese, 'Português'),
    (LanguageChoice.english, 'English'),
    (LanguageChoice.device, 'Idioma do celular'),
  ]) {
    testWidgets('o sinal de escolhido de "$label" fica no fim da linha', (
      tester,
    ) async {
      await openSheet(tester, choice);

      final Rect tile = tester.getRect(tileOf(label));
      final Rect check = tester.getRect(find.byIcon(LucideIcons.check));

      // Linha da largura toda da folha, com o sinal colado à direita (só o
      // recuo interno da linha) e na mesma altura do nome.
      expect(tile.width, greaterThan(300));
      expect(tile.right - check.right, lessThanOrEqualTo(24));
      expect(check.center.dy, moreOrLessEquals(tile.center.dy, epsilon: 1));
    });
  }
}
