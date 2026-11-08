import 'package:click_seguro_app/core/theme/app_motion.dart';
import 'package:click_seguro_app/core/theme/app_theme.dart';
import 'package:click_seguro_app/core/widgets/safe_skeleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/localized_app.dart';

/// Esqueleto no formato do conteúdo (specs/022 R8, FR-011 a FR-014).
void main() {
  Widget content() => const Padding(
    padding: EdgeInsets.all(16),
    child: Column(
      children: [
        Text('Título de exemplo'),
        Text('Resumo de exemplo da notícia'),
      ],
    ),
  );

  Future<void> pumpSkeleton(
    WidgetTester tester, {
    required bool enabled,
    bool reduce = false,
    ThemeData? theme,
  }) => pumpLocalized(
    tester,
    settle: false,
    theme: theme,
    child: AppMotionScope(
      appReduceMotion: reduce,
      child: Scaffold(
        body: SafeSkeleton(enabled: enabled, child: content()),
      ),
    ),
  );

  testWidgets('ligado: lido como "Carregando", sem o texto de exemplo', (
    tester,
  ) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    await pumpSkeleton(tester, enabled: true);

    expect(find.bySemanticsLabel('Carregando'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('exemplo')), findsNothing);
    expect(find.bySemanticsLabel('Resumo de exemplo da notícia'), findsNothing);
    semantics.dispose();
  });

  testWidgets('ligado: o brilho se move', (tester) async {
    await pumpSkeleton(tester, enabled: true);
    await tester.pump(const Duration(milliseconds: 100));

    expect(tester.hasRunningAnimations, isTrue);
  });

  testWidgets('com movimento reduzido: esqueleto estático', (tester) async {
    await pumpSkeleton(tester, enabled: true, reduce: true);
    await tester.pump(const Duration(milliseconds: 100));

    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('desligado: conteúdo normal e lido', (tester) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    await pumpSkeleton(tester, enabled: false);
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('Carregando'), findsNothing);
    expect(find.bySemanticsLabel(RegExp('Título de exemplo')), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('no alto contraste também monta, sem erro', (tester) async {
    await pumpSkeleton(
      tester,
      enabled: true,
      theme: AppTheme.highContrastTheme,
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(SafeSkeleton), findsOneWidget);
  });
}
