import 'package:click_seguro_app/modules/common/api_client/api_client.dart';
import 'package:click_seguro_app/modules/help/data/datasources/official_contacts_remote_data_source.dart';
import 'package:click_seguro_app/modules/help/data/models/contact_model.dart';

/// API dos contatos oficiais sem rede: devolve [contacts] ou, por padrão,
/// falha de conexão (o repository cai na cópia local ou no asset).
class FakeOfficialContactsRemoteDataSource
    implements OfficialContactsRemoteDataSource {
  List<ContactModel>? contacts;
  int calls = 0;

  @override
  Future<List<ContactModel>> fetch() async {
    calls++;
    final result = contacts;
    if (result != null) return result;
    throw ApiException(type: ApiErrorType.connection, message: 'sem rede');
  }
}
