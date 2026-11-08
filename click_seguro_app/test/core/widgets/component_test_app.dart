import 'package:click_seguro_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Monta um componente do `core` com o tema do app e as opções de mídia que
/// os testes do redesign variam (specs/022-redesign-visual).
Future<void> pumpComponent(
  WidgetTester tester,
  Widget child, {
  ThemeData? theme,
  bool disableAnimations = false,
  double textScale = 1,
}) => tester.pumpWidget(
  MaterialApp(
    theme: theme ?? AppTheme.lightTheme,
    home: MediaQuery(
      data: MediaQueryData(
        disableAnimations: disableAnimations,
        textScaler: TextScaler.linear(textScale),
      ),
      child: Scaffold(
        body: Center(
          child: Padding(padding: const EdgeInsets.all(16), child: child),
        ),
      ),
    ),
  ),
);
