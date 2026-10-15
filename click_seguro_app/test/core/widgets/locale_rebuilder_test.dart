import 'package:click_seguro_app/core/widgets/locale_rebuilder.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tela `const` que não depende do idioma: sem o rebuilder, continuaria com
/// o texto antigo.
class _ConstTitle extends StatelessWidget {
  const _ConstTitle();

  @override
  Widget build(BuildContext context) => Text('settings_title'.tr());
}

void main() {
  testWidgets('trocar o idioma reconstrói até telas const', (tester) async {
    SharedPreferences.setMockInitialValues({});
    EasyLocalization.logger.enableBuildModes = [];
    await EasyLocalization.ensureInitialized();
    late BuildContext appContext;

    await tester.runAsync(() async {
      await tester.pumpWidget(
        EasyLocalization(
          supportedLocales: const [Locale('pt', 'BR'), Locale('en', 'US')],
          path: 'assets/translations',
          fallbackLocale: const Locale('pt', 'BR'),
          startLocale: const Locale('pt', 'BR'),
          child: Builder(
            builder: (context) {
              appContext = context;
              return MaterialApp(
                localizationsDelegates: context.localizationDelegates,
                supportedLocales: context.supportedLocales,
                locale: context.locale,
                builder: (_, child) => LocaleRebuilder(child: child!),
                home: const _ConstTitle(),
              );
            },
          ),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pumpAndSettle();
    expect(find.text('Configurações'), findsOneWidget);

    await tester.runAsync(() async {
      await appContext.setLocale(const Locale('en', 'US'));
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsOneWidget);
  });
}
