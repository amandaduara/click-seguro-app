import 'dart:async';

import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:click_seguro_app/core/widgets/listen_button.dart';
import 'package:click_seguro_app/modules/common/accessibility/accessibility_preferences_notifier.dart';
import 'package:click_seguro_app/modules/common/presentation/controller/read_aloud_controller.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

/// "Ouvir" das telas de texto das Configurações (Privacidade, Sobre): vai
/// logo abaixo do título, antes do texto, e lê [text]. Com a leitura
/// automática ligada, lê uma vez quando a voz fica pronta; sem voz no
/// idioma, some. Um [ReadAloudController] por tela, descartado ao sair.
class SettingsListenButton extends StatefulWidget {
  const SettingsListenButton({super.key, required this.text});

  final String text;

  @override
  State<SettingsListenButton> createState() => _SettingsListenButtonState();
}

class _SettingsListenButtonState extends State<SettingsListenButton> {
  final ReadAloudController _readAloud = GetIt.instance<ReadAloudController>();
  Locale? _locale;

  /// A leitura automática acontece uma vez, quando a voz fica pronta.
  bool _autoReadDone = false;

  @override
  void initState() {
    super.initState();
    _readAloud.addListener(_maybeAutoRead);
  }

  /// O idioma da voz é o do app: prepara de novo se ele mudar.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final Locale locale = context.locale;
    if (locale == _locale) return;
    _locale = locale;
    unawaited(_readAloud.prepare(locale));
  }

  @override
  void dispose() {
    _readAloud.removeListener(_maybeAutoRead);
    _readAloud.dispose();
    super.dispose();
  }

  void _maybeAutoRead() {
    if (!mounted ||
        _autoReadDone ||
        !_readAloud.isAvailable ||
        !GetIt.instance<AccessibilityPreferencesNotifier>()
            .value
            .autoReadAloud) {
      return;
    }
    _autoReadDone = true;
    unawaited(_readAloud.speak(widget.text));
  }

  void _toggle() => unawaited(
    _readAloud.isSpeaking ? _readAloud.stop() : _readAloud.speak(widget.text),
  );

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _readAloud,
    builder: (context, _) => _readAloud.isAvailable
        ? Padding(
            padding: const EdgeInsets.only(top: AppSpacing.s2),
            child: ListenButton(
              isSpeaking: _readAloud.isSpeaking,
              onPressed: _toggle,
            ),
          )
        : const SizedBox.shrink(),
  );
}
