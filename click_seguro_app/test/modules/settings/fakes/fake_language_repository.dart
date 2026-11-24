import 'package:click_seguro_app/modules/settings/domain/entities/language_choice.dart';
import 'package:click_seguro_app/modules/settings/domain/repositories/language_repository.dart';

/// Escolha de idioma em memória.
class FakeLanguageRepository implements LanguageRepository {
  FakeLanguageRepository([this.choice = LanguageChoice.device]);

  LanguageChoice choice;
  final List<LanguageChoice> saved = [];

  @override
  Future<LanguageChoice> getLanguage() async => choice;

  @override
  Future<void> saveLanguage(LanguageChoice value) async {
    saved.add(value);
    choice = value;
  }
}
