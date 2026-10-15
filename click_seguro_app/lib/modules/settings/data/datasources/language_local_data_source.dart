import 'package:click_seguro_app/modules/settings/domain/entities/language_choice.dart';

/// Escolha de idioma guardada no aparelho.
abstract class LanguageLocalDataSource {
  /// Ausente → `null`. Pode lançar.
  Future<LanguageChoice?> read();

  Future<void> write(LanguageChoice choice);
}
