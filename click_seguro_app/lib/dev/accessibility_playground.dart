// Só para desenvolvimento: flutter run -t lib/dev/accessibility_playground.dart
//
// O app real (mesmo setupApp() do main.dart) com um botão de acessibilidade
// por cima, para validar no aparelho a feature 009 enquanto a tela da B9 não
// existe. Não é importada pelo app; os textos são fixos por não ser parte do
// produto, como no style guide.
import 'package:click_seguro_app/main.dart';
import 'package:click_seguro_app/modules/common/accessibility/accessibility_preferences.dart';
import 'package:click_seguro_app/modules/common/accessibility/accessibility_preferences_notifier.dart';
import 'package:click_seguro_app/modules/common/services/text_to_speech_service.dart';
import 'package:click_seguro_app/modules/settings/settings.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  final (moduleManager, router) = await setupApp();

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('pt', 'BR'), Locale('en', 'US')],
      path: 'assets/translations',
      fallbackLocale: const Locale('pt', 'BR'),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Stack(
          children: [
            ClickSeguroApp(
              moduleManager: moduleManager,
              router: router,
              accessibility: GetIt.instance<AccessibilityPreferencesNotifier>(),
            ),
            const _AccessibilityPanel(),
          ],
        ),
      ),
    ),
  );
}

/// Botão pequeno na borda esquerda; aberto, troca as quatro preferências pelo
/// `AccessibilityController`, como a tela da B9 fará.
class _AccessibilityPanel extends StatefulWidget {
  const _AccessibilityPanel();

  @override
  State<_AccessibilityPanel> createState() => _AccessibilityPanelState();
}

class _AccessibilityPanelState extends State<_AccessibilityPanel> {
  final AccessibilityController _controller =
      GetIt.instance<AccessibilityController>();
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    return Localizations(
      locale: const Locale('en'),
      delegates: const [
        DefaultMaterialLocalizations.delegate,
        DefaultWidgetsLocalizations.delegate,
      ],
      child: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) => _open ? _panel() : _toggle(),
      ),
    );
  }

  Widget _toggle() => Positioned(
    left: 0,
    top: 0,
    bottom: 0,
    child: Center(
      child: Material(
        color: Colors.black54,
        borderRadius: const BorderRadius.horizontal(right: Radius.circular(12)),
        child: InkWell(
          onTap: () => setState(() => _open = true),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 14),
            child: Icon(Icons.accessibility_new, color: Colors.white, size: 18),
          ),
        ),
      ),
    ),
  );

  Widget _panel() {
    final AccessibilityPreferences preferences = _controller.preferences;
    return Positioned(
      left: 12,
      right: 12,
      bottom: 24,
      child: Material(
        elevation: 12,
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Acessibilidade (dev)',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    onPressed: () => setState(() => _open = false),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Text('Tamanho da letra'),
              Wrap(
                spacing: 6,
                children: [
                  for (final FontScaleLevel level in FontScaleLevel.values)
                    ChoiceChip(
                      label: Text('${(level.factor * 100).round()}%'),
                      selected: preferences.fontScale == level,
                      onSelected: (_) => _controller.setFontScale(level),
                    ),
                ],
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Alto contraste'),
                value: preferences.highContrast,
                onChanged: _controller.setHighContrast,
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Leitura automática'),
                value: preferences.autoReadAloud,
                onChanged: _controller.setAutoReadAloud,
              ),
              const Text('Velocidade da voz'),
              Wrap(
                spacing: 6,
                children: [
                  for (final ReadingSpeed speed in ReadingSpeed.values)
                    ChoiceChip(
                      label: Text(speed.name),
                      selected: preferences.readingSpeed == speed,
                      onSelected: (_) => _controller.setReadingSpeed(speed),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
