import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Monta [child] (ou [router]) com o `EasyLocalization` real e as traduções
/// de `assets/translations`, em pt-BR.
Future<void> pumpLocalized(
  WidgetTester tester, {
  Widget? child,
  RouterConfig<Object>? router,
}) async {
  assert((child == null) != (router == null), 'Informe child ou router');
  SharedPreferences.setMockInitialValues({});
  EasyLocalization.logger.enableBuildModes = [];
  await EasyLocalization.ensureInitialized();

  Widget app(BuildContext context) => router != null
      ? MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          locale: context.locale,
        )
      : MaterialApp(
          home: child,
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          locale: context.locale,
        );

  // A carga das traduções é assíncrona de verdade (fora do relógio falso do
  // teste): sem o runAsync, a partir do 2º teste a árvore fica vazia.
  await tester.runAsync(() async {
    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('pt', 'BR'), Locale('en', 'US')],
        path: 'assets/translations',
        fallbackLocale: const Locale('pt', 'BR'),
        startLocale: const Locale('pt', 'BR'),
        child: Builder(builder: app),
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 50));
  });
  await tester.pumpAndSettle();
}
