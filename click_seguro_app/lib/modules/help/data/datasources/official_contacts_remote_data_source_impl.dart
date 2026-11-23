import 'package:click_seguro_app/modules/common/api_client/api_client.dart';
import 'package:click_seguro_app/modules/help/data/datasources/official_contacts_remote_data_source.dart';
import 'package:click_seguro_app/modules/help/data/models/contact_model.dart';

class OfficialContactsRemoteDataSourceImpl
    implements OfficialContactsRemoteDataSource {
  OfficialContactsRemoteDataSourceImpl(this._apiClient);

  static const String path = '/app/official-contacts';

  final ApiClient _apiClient;

  @override
  Future<List<ContactModel>> fetch() async {
    final response = await _apiClient.get(path, requiresAuth: false);
    final Object? body = response.data;
    if (body is! List) {
      throw ApiException(
        type: ApiErrorType.invalidResponse,
        statusCode: response.statusCode,
        message: 'Official contacts response must be a list',
      );
    }
    return ContactModel.officialList(body);
  }
}
