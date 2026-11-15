import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/widgets/editable_avatar.dart';
import 'package:click_seguro_app/core/widgets/person_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'component_test_app.dart';

/// Foto editável (a da edição de perfil, também no contato): círculo com a
/// foto ou as iniciais e o selo coral com a câmera no canto.
void main() {
  testWidgets('círculo com o selo da câmera, botão com rótulo e toque', (
    tester,
  ) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    int taps = 0;
    await pumpComponent(
      tester,
      EditableAvatar(
        name: 'Ana Souza',
        semanticLabel: 'Trocar foto',
        onTap: () => taps++,
      ),
    );

    expect(find.byType(PersonAvatar), findsOneWidget);
    expect(find.byIcon(LucideIcons.camera), findsOneWidget);
    expect(tester.getSize(find.byType(EditableAvatar)), const Size(96, 96));
    expect(find.bySemanticsLabel('Trocar foto'), findsOneWidget);

    await tester.tap(find.byType(EditableAvatar));
    expect(taps, 1);
    handle.dispose();
  });

  testWidgets('enviando: carregamento por cima e sem toque', (tester) async {
    int taps = 0;
    await pumpComponent(
      tester,
      EditableAvatar(
        initials: 'AS',
        semanticLabel: 'Trocar foto',
        busy: true,
        onTap: () => taps++,
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.tap(find.byType(EditableAvatar));
    expect(taps, 0);
  });

  testWidgets('o selo usa a cor da marca', (tester) async {
    await pumpComponent(
      tester,
      const EditableAvatar(initials: 'AS', semanticLabel: 'Trocar foto'),
    );

    final Container badge = tester.widget<Container>(
      find
          .ancestor(
            of: find.byIcon(LucideIcons.camera),
            matching: find.byType(Container),
          )
          .first,
    );
    expect(
      (badge.decoration! as BoxDecoration).color,
      AppPalette.light.primary,
    );
  });
}
