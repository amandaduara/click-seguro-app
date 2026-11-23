import 'package:click_seguro_app/modules/help/data/models/contact_model.dart';

abstract class OfficialContactsRemoteDataSource {
  /// Contatos oficiais de `GET /app/official-contacts` (público), na ordem
  /// da API. Item inválido ou sem telefone é ignorado; corpo que não é
  /// lista lança `ApiException` de resposta inválida.
  Future<List<ContactModel>> fetch();
}
