import 'package:click_seguro_app/core/widgets/safe_skeleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'component_test_app.dart';

/// Bloco com brilho do carregamento (FR-018), parado com reduzir animações
/// (FR-021).
void main() {
  testWidgets('bloco do tamanho pedido, fora da semântica', (tester) async {
    await pumpComponent(
      tester,
      const SafeSkeleton(width: 200, height: 20),
      disableAnimations: true,
    );

    expect(tester.getSize(find.byType(SafeSkeleton)), const Size(200, 20));
    expect(
      find.descendant(
        of: find.byType(SafeSkeleton),
        matching: find.byType(ExcludeSemantics),
      ),
      findsOneWidget,
    );
  });

  testWidgets('o brilho corre enquanto carrega', (tester) async {
    await pumpComponent(tester, const SafeSkeleton(width: 200, height: 20));

    expect(tester.hasRunningAnimations, isTrue);
  });

  testWidgets('com reduzir animações, fica parado (FR-021)', (tester) async {
    await pumpComponent(
      tester,
      const SafeSkeleton(width: 200, height: 20),
      disableAnimations: true,
    );

    expect(tester.hasRunningAnimations, isFalse);
  });
}
