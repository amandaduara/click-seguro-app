import 'package:click_seguro_app/core/errors/cache_failure.dart';
import 'package:click_seguro_app/modules/common/accessibility/accessibility_preferences.dart';
import 'package:click_seguro_app/modules/common/services/text_to_speech_service.dart';
import 'package:click_seguro_app/modules/settings/data/datasources/accessibility_local_data_source_impl.dart';
import 'package:click_seguro_app/modules/settings/data/repositories/accessibility_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../fakes/fake_local_cache_service.dart';

void main() {
  const key = AccessibilityLocalDataSourceImpl.storageKey;
  const custom = AccessibilityPreferences(
    fontScale: FontScaleLevel.largest,
    highContrast: true,
    autoReadAloud: false,
    readingSpeed: ReadingSpeed.fast,
  );

  late FakeLocalCacheService cache;
  late AccessibilityRepositoryImpl repository;

  setUp(() {
    cache = FakeLocalCacheService();
    repository = AccessibilityRepositoryImpl(
      AccessibilityLocalDataSourceImpl(cache),
    );
  });

  test('chave versionada do registro', () {
    expect(key, 'accessibility_preferences_v1');
  });

  test('sem registro → padrões (primeira abertura)', () async {
    expect(
      await repository.getPreferences(),
      const AccessibilityPreferences.defaults(),
    );
  });

  test('salva e lê de volta', () async {
    final result = await repository.savePreferences(custom);

    expect(result.isRight(), isTrue);
    expect(cache.values[key], {
      'fontScale': 'largest',
      'highContrast': true,
      'autoReadAloud': false,
      'readingSpeed': 'fast',
    });
    expect(await repository.getPreferences(), custom);
  });

  test('registro corrompido → padrões dos campos ilegíveis', () async {
    cache.values[key] = {'fontScale': 42, 'highContrast': true};

    final preferences = await repository.getPreferences();

    expect(preferences.fontScale, FontScaleLevel.standard);
    expect(preferences.highContrast, isTrue);
  });

  test('falha ao ler → padrões, sem exceção (FR-009)', () async {
    cache.throwOnRead = true;

    expect(
      await repository.getPreferences(),
      const AccessibilityPreferences.defaults(),
    );
  });

  test('falha ao gravar → CacheFailure, sem exceção (FR-009)', () async {
    cache.throwOnWrite = true;

    final result = await repository.savePreferences(custom);

    expect(result.getLeft().toNullable(), isA<CacheFailure>());
  });
}
