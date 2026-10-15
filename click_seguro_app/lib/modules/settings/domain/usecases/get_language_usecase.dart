import 'package:click_seguro_app/modules/settings/domain/entities/language_choice.dart';
import 'package:click_seguro_app/modules/settings/domain/repositories/language_repository.dart';

class GetLanguageUseCase {
  GetLanguageUseCase(this._repository);

  final LanguageRepository _repository;

  Future<LanguageChoice> call() => _repository.getLanguage();
}
