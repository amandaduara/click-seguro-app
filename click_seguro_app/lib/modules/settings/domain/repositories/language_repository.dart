import 'package:click_seguro_app/modules/settings/domain/entities/language_choice.dart';

abstract class LanguageRepository {
  /// Ausente ou ilegível → [LanguageChoice.device]. Não lança.
  Future<LanguageChoice> getLanguage();

  /// Falha ao gravar é ignorada (a troca já valeu nesta abertura).
  Future<void> saveLanguage(LanguageChoice choice);
}
