import 'package:click_seguro_app/core/theme/app_theme.dart';
import 'package:click_seguro_app/modules/authentication/authentication.dart';
import 'package:click_seguro_app/modules/common/common.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  final moduleManager = await _setup();

  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale('pt', 'BR'),
        Locale('en', 'US'),
      ],
      path: 'assets/translations',
      fallbackLocale: const Locale('pt', 'BR'),
      child: ClickSeguroApp(moduleManager: moduleManager),
    ),
  );
}

Future<ModuleManagerInterface> _setup() async {
  final ModuleManagerInterface moduleManager = ModuleManager();
  await moduleManager.registerModules([
    CommonModule(),
    AuthenticationModule(),
  ]);
  return moduleManager;
}

class ClickSeguroApp extends StatelessWidget {
  const ClickSeguroApp({super.key, required this.moduleManager});

  final ModuleManagerInterface moduleManager;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: moduleManager.providers,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        localizationsDelegates: context.localizationDelegates,
        supportedLocales: context.supportedLocales,
        locale: context.locale,
        theme: AppTheme.lightTheme
      ),
    );
  }
}
