import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Monta [child] (ou [router]) com o `EasyLocalization` real e as traduções
/// de `assets/translations`, em pt-BR. [providers] ficam acima do app, como o
/// `MultiProvider` dos módulos no `main.dart`. Com [settle] falso, não espera
/// as animações terminarem (ex.: um indicador de carregando sem fim). O
/// idioma inicial é [locale] (padrão pt-BR). [theme] troca o tema do app (ex.:
/// o de alto contraste).
Future<void> pumpLocalized(
  WidgetTester tester, {
  Widget? child,
  RouterConfig<Object>? router,
  List<SingleChildWidget> providers = const [],
  bool settle = true,
  Locale locale = const Locale('pt', 'BR'),
  ThemeData? theme,
}) async {
  assert((child == null) != (router == null), 'Informe child ou router');
  SharedPreferences.setMockInitialValues({});
  EasyLocalization.logger.enableBuildModes = [];
  await EasyLocalization.ensureInitialized();

  Widget app(BuildContext context) => router != null
      ? MaterialApp.router(
          routerConfig: router,
          theme: theme,
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          locale: context.locale,
        )
      : MaterialApp(
          home: child,
          theme: theme,
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
        startLocale: locale,
        child: providers.isEmpty
            ? Builder(builder: app)
            : MultiProvider(
                providers: providers,
                child: Builder(builder: app),
              ),
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 50));
  });
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
}
