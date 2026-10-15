import 'package:click_seguro_app/modules/common/services/local_cache_service.dart';
import 'package:click_seguro_app/modules/settings/data/datasources/language_local_data_source.dart';
import 'package:click_seguro_app/modules/settings/domain/entities/language_choice.dart';

class LanguageLocalDataSourceImpl implements LanguageLocalDataSource {
  LanguageLocalDataSourceImpl(this._cache);

  static const String storageKey = 'language_choice';
  static const String _field = 'choice';

  final LocalCacheService _cache;

  @override
  Future<LanguageChoice?> read() async {
    final json = await _cache.readJson(storageKey);
    final Object? name = json?[_field];
    return LanguageChoice.values.where((c) => c.name == name).firstOrNull;
  }

  @override
  Future<void> write(LanguageChoice choice) =>
      _cache.writeJson(storageKey, {_field: choice.name});
}
