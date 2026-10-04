import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Toda chave `onboarding_*`/`splash_*` de `AppStrings` existe em pt-BR e
/// en-US com texto, e os textos pt-BR são os do wireframe
/// (`wireframe/src/components/screens/OnboardingScreen.tsx`, FR-012).
void main() {
  final keyPattern = RegExp(r"'((?:onboarding|splash)_[a-z0-9_]+)'");
  final declared = keyPattern
      .allMatches(File('lib/core/i18n/app_strings.dart').readAsStringSync())
      .map((m) => m.group(1)!)
      .toSet();

  Map<String, dynamic> load(String locale) =>
      jsonDecode(File('assets/translations/$locale.json').readAsStringSync())
          as Map<String, dynamic>;

  test('AppStrings declara as chaves dos módulos', () {
    expect(declared, contains('splash_tagline'));
    expect(declared, contains('onboarding_skip'));
  });

  for (final locale in ['pt-BR', 'en-US']) {
    test('$locale tem todas as chaves com texto', () {
      final json = load(locale);

      for (final key in declared) {
        expect(json[key], isA<String>(), reason: '$locale sem $key');
        expect((json[key] as String).trim(), isNotEmpty, reason: key);
      }
    });
  }

  test('textos pt-BR iguais ao wireframe', () {
    final json = load('pt-BR');

    expect(json, containsPair('app_title', 'SafeNews'));
    expect(
      json,
      containsPair('splash_tagline', 'Sua segurança em primeiro lugar'),
    );
    expect(
      json,
      containsPair('onboarding_page1_title', 'Proteja-se de golpes'),
    );
    expect(
      json,
      containsPair(
        'onboarding_page1_description',
        'Receba alertas sobre os golpes mais comuns e aprenda a se defender.',
      ),
    );
    expect(
      json,
      containsPair('onboarding_page2_title', 'Notícias verificadas'),
    );
    expect(
      json,
      containsPair(
        'onboarding_page2_description',
        'Acompanhe fake news desmentidas por fontes oficiais.',
      ),
    );
    expect(json, containsPair('onboarding_page3_title', 'Aprenda na prática'));
    expect(
      json,
      containsPair(
        'onboarding_page3_description',
        'Atividades curtas e quizzes para treinar sua segurança digital.',
      ),
    );
    expect(json, containsPair('onboarding_button_continue', 'Continuar'));
    expect(json, containsPair('onboarding_button_start', 'Começar'));
    expect(json, containsPair('onboarding_skip', 'Pular'));
  });
}
