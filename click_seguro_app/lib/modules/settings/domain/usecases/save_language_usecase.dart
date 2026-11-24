import 'package:click_seguro_app/modules/settings/domain/entities/language_choice.dart';
import 'package:click_seguro_app/modules/settings/domain/repositories/language_repository.dart';

class SaveLanguageUseCase {
  SaveLanguageUseCase(this._repository);

  final LanguageRepository _repository;

  Future<void> call(LanguageChoice choice) => _repository.saveLanguage(choice);
}
