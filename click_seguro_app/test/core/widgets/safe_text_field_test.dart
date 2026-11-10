import 'package:click_seguro_app/core/theme/app_theme.dart';
import 'package:click_seguro_app/core/widgets/safe_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('sem o retângulo do tema dentro do campo (specs/022 T060)', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const Scaffold(body: SafeTextField(placeholder: 'E-mail')),
      ),
    );

    final InputDecoration decoration = tester
        .widget<TextField>(find.byType(TextField))
        .decoration!;
    expect(decoration.filled, isFalse);
  });
}
