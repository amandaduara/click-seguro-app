import 'package:click_seguro_app/modules/common/api_client/api_client.dart';
import 'package:click_seguro_app/modules/common/services/user_session_service.dart';
import 'package:click_seguro_app/modules/help/data/datasources/official_contacts_remote_data_source_impl.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

import '../../../../fakes/fake_secure_storage_service.dart';
import '../../../common/api_client/fake_http_client_adapter.dart';

void main() {
  late FakeHttpClientAdapter adapter;
  late OfficialContactsRemoteDataSourceImpl dataSource;

  setUp(() {
    adapter = FakeHttpClientAdapter();
    GetIt.instance.registerSingleton<UserSessionService>(
      UserSessionService(FakeSecureStorageService()),
    );
    dataSource = OfficialContactsRemoteDataSourceImpl(
      ApiClient(
        dio: Dio(BaseOptions(baseUrl: 'https://api.test'))
          ..httpClientAdapter = adapter,
      ),
    );
  });

  tearDown(() => GetIt.instance.reset());

  Matcher apiError(ApiErrorType type) =>
      throwsA(isA<ApiException>().having((e) => e.type, 'type', type));

  test('GET /app/official-contacts, sem filtro e sem token', () async {
    adapter.body = <Object?>[];

    await dataSource.fetch();

    final request = adapter.lastRequest!;
    expect(request.method, 'GET');
    expect(request.path, OfficialContactsRemoteDataSourceImpl.path);
    expect(request.path, '/app/official-contacts');
    expect(request.queryParameters, isEmpty);
    expect(request.headers.containsKey('Authorization'), isFalse);
  });

  test('devolve os contatos válidos na ordem da API', () async {
    adapter.body = [
      {
        'id': 'cmwji7nwg0000c12bs899nhx1',
        'name': 'Polícia Militar',
        'description': 'Emergência: ligue 190 se estiver em perigo',
        'type': 'POLICIA',
        'phone': '190',
        'email': null,
        'website': null,
      },
      {
        'id': 'cmwapkd1t003sd01sqvpj1uqi',
        'name': 'SaferNet Brasil',
        'description': 'Denúncia de crimes na internet',
        'type': 'DELEGACIA_CIBERNETICA',
        'phone': null,
        'email': null,
        'website': 'https://new.safernet.org.br/denuncie/',
      },
      {
        'id': 'cmwapk5dg003pd01so5jcvy1a',
        'name': 'Anatel',
        'description': 'Reclamações de telefonia: 1331',
        'type': 'ANATEL',
        'phone': '1331',
        'email': null,
        'website': 'https://www.gov.br/anatel/pt-br',
      },
    ];

    final contacts = await dataSource.fetch();

    // Sem telefone não dá para ligar: o item é ignorado.
    expect(contacts.map((contact) => contact.name), [
      'Polícia Militar',
      'Anatel',
    ]);
    expect(
      contacts.first.description,
      'Emergência: ligue 190 se estiver em perigo',
    );
  });

  test('corpo que não é lista: resposta inválida', () async {
    adapter.body = {'data': <Object?>[]};

    await expectLater(
      dataSource.fetch(),
      apiError(ApiErrorType.invalidResponse),
    );
  });

  test('sem conexão: ApiException de conexão', () async {
    adapter.error = (options) => DioException.connectionError(
      requestOptions: options,
      reason: 'sem rede',
    );

    await expectLater(dataSource.fetch(), apiError(ApiErrorType.connection));
  });

  test('servidor fora do ar: ApiException de servidor', () async {
    adapter
      ..statusCode = 503
      ..body = {'message': 'indisponível'};

    await expectLater(dataSource.fetch(), apiError(ApiErrorType.server));
  });
}
