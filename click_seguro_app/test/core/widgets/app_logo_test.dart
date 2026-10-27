import 'package:click_seguro_app/core/constants/app_identity.dart';
import 'package:click_seguro_app/core/widgets/app_logo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('carrega a arte oficial preservando proporção', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Center(child: AppLogo(size: 96))),
    );
    // Asset loading and PNG decoding complete outside the fake test clock.
    for (
      var i = 0;
      i < 30 && tester.widget<RawImage>(find.byType(RawImage)).image == null;
      i++
    ) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump();
    }
    expect(tester.widget<RawImage>(find.byType(RawImage)).image, isNotNull);
    final image = tester.widget<Image>(find.byType(Image));
    expect((image.image as AssetImage).assetName, AppLogo.asset);
    expect(image.fit, BoxFit.contain);
    expect(tester.getSize(find.byType(AppLogo)), const Size(96, 96));
    expect(tester.takeException(), isNull);
  });

  testWidgets('logo decorativa não duplica o nome para leitor de tela', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      const MaterialApp(
        home: Column(children: [AppLogo(), Text(AppIdentity.name)]),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Click Seguro'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('logo isolada pode anunciar o nome oficial', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      const MaterialApp(home: AppLogo(excludeFromSemantics: false)),
    );
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Click Seguro'), findsOneWidget);
    semantics.dispose();
  });
}
