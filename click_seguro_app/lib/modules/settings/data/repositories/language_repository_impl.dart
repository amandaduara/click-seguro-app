import 'package:click_seguro_app/modules/settings/data/datasources/language_local_data_source.dart';
import 'package:click_seguro_app/modules/settings/domain/entities/language_choice.dart';
import 'package:click_seguro_app/modules/settings/domain/repositories/language_repository.dart';

class LanguageRepositoryImpl implements LanguageRepository {
  LanguageRepositoryImpl(this._local);

  final LanguageLocalDataSource _local;

  @override
  Future<LanguageChoice> getLanguage() async {
    try {
      return await _local.read() ?? LanguageChoice.device;
    } catch (_) {
      return LanguageChoice.device;
    }
  }

  @override
  Future<void> saveLanguage(LanguageChoice choice) async {
    try {
      await _local.write(choice);
    } catch (_) {
      // O idioma já foi aplicado; sem gravar, a próxima abertura segue o
      // que o easy_localization guardou.
    }
  }
}
