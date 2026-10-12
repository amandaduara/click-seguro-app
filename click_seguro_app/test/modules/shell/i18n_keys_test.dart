import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// FR-020/FR-021 de specs/005-shell-navegacao-base: blocos de textos dos
/// módulos da Fase 0 em pt-BR e en-US, e nenhuma chave da `/home` provisória.
void main() {
  final appStrings = File('lib/core/i18n/app_strings.dart').readAsStringSync();
  final keyPattern = RegExp(
    r"'((?:common|shell|news|notifications|activities|help|profile|settings)_[a-z0-9_]+)'",
  );
  final declared = keyPattern
      .allMatches(appStrings)
      .map((m) => m.group(1)!)
      .toSet();

  Map<String, dynamic> load(String locale) =>
      jsonDecode(File('assets/translations/$locale.json').readAsStringSync())
          as Map<String, dynamic>;

  const required = [
    'common_try_again',
    'common_loading',
    'common_empty',
    'common_offline_banner',
    'common_coming_soon',
    'common_back_home',
    'common_not_found_title',
    'common_account_required_title',
    'common_account_required_body',
    'common_account_required_action',
    'common_account_required_dismiss',
    'common_session_expired_action',
    'shell_tab_home',
    'shell_tab_activities',
    'shell_tab_news',
    'shell_tab_help',
    'shell_tab_profile',
    'shell_nav_label',
    'shell_greeting',
    'shell_welcome',
    'shell_notifications',
    'shell_settings',
    'news_title',
    'news_reels_title',
    'news_detail_title',
    'notifications_title',
    'notifications_group_today',
    'notifications_group_yesterday',
    'notifications_group_earlier',
    'notifications_badge_new',
    'notifications_summary_none',
    'notifications_summary_one',
    'notifications_summary_many',
    'notifications_mark_all',
    'notifications_empty',
    'notifications_empty_hint',
    'notifications_guest_body',
    'notifications_disabled_notice',
    'notifications_disabled_action',
    'notifications_bell_label',
    'notifications_bell_label_one',
    'notifications_semantic_new',
    'activities_title',
    'activities_module_title',
    'help_title',
    'help_contact_title',
    'profile_title',
    'profile_edit_title',
    'settings_title',
    'settings_account_title',
    'settings_security_title',
    'settings_accessibility_title',
  ];

  test('AppStrings declara as chaves do data-model', () {
    expect(declared, containsAll(required));
  });

  for (final locale in ['pt-BR', 'en-US']) {
    test('$locale tem todas as chaves com texto', () {
      final json = load(locale);

      for (final key in declared) {
        expect(json[key], isA<String>(), reason: '$locale sem $key');
        expect((json[key] as String).trim(), isNotEmpty, reason: key);
      }
      expect(json['shell_greeting'], contains('{}'));
      expect(json['notifications_summary_many'], contains('{}'));
      expect(json['notifications_bell_label'], contains('{}'));
      expect(json['notifications_semantic_new'], contains('{}'));
    });
  }

  test('textos pt-BR do data-model', () {
    final json = load('pt-BR');

    expect(json, containsPair('common_try_again', 'Tentar novamente'));
    expect(json, containsPair('common_empty', 'Nada por aqui ainda.'));
    expect(
      json,
      containsPair(
        'common_offline_banner',
        'Você está sem internet. Mostrando o conteúdo salvo.',
      ),
    );
    expect(
      json,
      containsPair('common_account_required_title', 'Entre na sua conta'),
    );
    expect(
      json,
      containsPair(
        'common_account_required_body',
        'Para usar esta função, entre ou crie uma conta. É rápido e gratuito.',
      ),
    );
    expect(
      json,
      containsPair('common_account_required_action', 'Entrar ou criar conta'),
    );
    expect(json, containsPair('common_account_required_dismiss', 'Agora não'));
  });

  test('sino e tela chamam tudo de "Alertas" (R11 de specs/011)', () {
    expect(load('pt-BR'), containsPair('shell_notifications', 'Alertas'));
    expect(load('pt-BR'), containsPair('notifications_title', 'Alertas'));
    expect(load('en-US'), containsPair('shell_notifications', 'Alerts'));
  });

  test('sem chaves da /home provisória (FR-021)', () {
    expect(appStrings, isNot(contains('home_placeholder_')));
    for (final locale in ['pt-BR', 'en-US']) {
      expect(
        load(locale).keys.where((k) => k.startsWith('home_placeholder_')),
        isEmpty,
        reason: locale,
      );
    }
  });
}
