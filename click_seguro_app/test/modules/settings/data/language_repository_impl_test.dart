import 'package:click_seguro_app/modules/settings/data/datasources/language_local_data_source_impl.dart';
import 'package:click_seguro_app/modules/settings/data/repositories/language_repository_impl.dart';
import 'package:click_seguro_app/modules/settings/domain/entities/language_choice.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../fakes/fake_local_cache_service.dart';

void main() {
  late FakeLocalCacheService cache;
  late LanguageRepositoryImpl repository;

  setUp(() {
    cache = FakeLocalCacheService();
    repository = LanguageRepositoryImpl(LanguageLocalDataSourceImpl(cache));
  });

  test('sem registro → device', () async {
    expect(await repository.getLanguage(), LanguageChoice.device);
  });

  for (final choice in LanguageChoice.values) {
    test('grava e lê ${choice.name}', () async {
      await repository.saveLanguage(choice);

      expect(cache.values[LanguageLocalDataSourceImpl.storageKey], {
        'choice': choice.name,
      });
      expect(await repository.getLanguage(), choice);
    });
  }

  test('valor desconhecido → device', () async {
    cache.values[LanguageLocalDataSourceImpl.storageKey] = {
      'choice': 'klingon',
    };

    expect(await repository.getLanguage(), LanguageChoice.device);
  });

  test('leitura que lança → device', () async {
    cache.throwOnRead = true;

    expect(await repository.getLanguage(), LanguageChoice.device);
  });

  test('gravação que lança não sobe', () async {
    cache.throwOnWrite = true;

    await expectLater(
      repository.saveLanguage(LanguageChoice.english),
      completes,
    );
  });
}
