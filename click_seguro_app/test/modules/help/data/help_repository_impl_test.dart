import 'package:click_seguro_app/core/errors/cache_failure.dart';
import 'package:click_seguro_app/core/errors/connection_failure.dart';
import 'package:click_seguro_app/modules/common/api_client/api_client.dart';
import 'package:click_seguro_app/modules/help/data/datasources/official_contacts_local_data_source.dart';
import 'package:click_seguro_app/modules/help/data/datasources/official_contacts_remote_data_source.dart';
import 'package:click_seguro_app/modules/help/data/datasources/personal_contacts_local_data_source.dart';
import 'package:click_seguro_app/modules/help/data/models/contact_model.dart';
import 'package:click_seguro_app/modules/help/data/repositories/help_repository_impl.dart';
import 'package:click_seguro_app/modules/help/domain/entities/contact_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late _FakeRemote remote;
  late _FakeOfficialLocal local;
  late HelpRepositoryImpl repository;

  setUp(() {
    remote = _FakeRemote();
    local = _FakeOfficialLocal();
    repository = HelpRepositoryImpl(remote, local, _FailingPersonalSource());
  });

  List<String> ids(List<ContactEntity> contacts) => [
    for (final contact in contacts) contact.id,
  ];

  group('getOfficialContacts (offline-first)', () {
    test('API respondeu: devolve na ordem dela e guarda a cópia', () async {
      remote.contacts = _models(['api1', 'api2']);
      local.copy = _models(['velho']);

      final result = await repository.getOfficialContacts();

      expect(ids(result.getRight().toNullable()!), ['api1', 'api2']);
      expect(result.getRight().toNullable()!.first.description, 'api1 desc');
      expect(local.saved!.map((contact) => contact.id), ['api1', 'api2']);
    });

    test('falha ao guardar a cópia não esconde a lista da API', () async {
      remote.contacts = _models(['api1']);
      local.saveError = StateError('disco cheio');

      final result = await repository.getOfficialContacts();

      expect(ids(result.getRight().toNullable()!), ['api1']);
    });

    test('sem internet: devolve a cópia guardada', () async {
      remote.error = ApiException(
        type: ApiErrorType.connection,
        message: 'sem rede',
      );
      local.copy = _models(['copia1', 'copia2']);

      final result = await repository.getOfficialContacts();

      expect(ids(result.getRight().toNullable()!), ['copia1', 'copia2']);
      expect(local.saved, isNull);
    });

    test('servidor dormindo (timeout): devolve a cópia guardada', () async {
      remote.error = ApiException(
        type: ApiErrorType.timeout,
        message: 'demorou',
      );
      local.copy = _models(['copia1']);

      final result = await repository.getOfficialContacts();

      expect(ids(result.getRight().toNullable()!), ['copia1']);
    });

    test('sem internet e sem cópia: usa o asset do app', () async {
      remote.error = ApiException(
        type: ApiErrorType.connection,
        message: 'sem rede',
      );
      local.asset = _models(['asset1']);

      final result = await repository.getOfficialContacts();

      expect(ids(result.getRight().toNullable()!), ['asset1']);
    });

    test('cópia ilegível: ainda cai no asset', () async {
      remote.error = ApiException(type: ApiErrorType.server, message: '503');
      local
        ..copyError = StateError('armazenamento indisponível')
        ..asset = _models(['asset1']);

      final result = await repository.getOfficialContacts();

      expect(ids(result.getRight().toNullable()!), ['asset1']);
    });

    test('API devolveu lista vazia: mantém a cópia guardada', () async {
      remote.contacts = [];
      local.copy = _models(['copia1']);

      final result = await repository.getOfficialContacts();

      expect(ids(result.getRight().toNullable()!), ['copia1']);
      expect(local.saved, isNull);
    });

    test('nada disponível: falha da API, sem lançar', () async {
      remote.error = ApiException(
        type: ApiErrorType.connection,
        message: 'sem rede',
      );
      local.assetError = const FormatException('asset quebrado');

      final result = await repository.getOfficialContacts();

      expect(result.getLeft().toNullable(), isA<ConnectionFailure>());
    });
  });

  test('falha local dos pessoais vira CacheFailure no Either', () async {
    final result = await repository.getPersonalContacts();

    expect(result.getLeft().toNullable(), isA<CacheFailure>());
  });
}

List<ContactModel> _models(List<String> ids) => [
  for (final id in ids)
    ContactModel(
      id: id,
      name: 'Contato $id',
      phone: '190',
      type: ContactType.official,
      description: '$id desc',
    ),
];

class _FakeRemote implements OfficialContactsRemoteDataSource {
  List<ContactModel> contacts = [];
  Object? error;

  @override
  Future<List<ContactModel>> fetch() async {
    if (error case final Object error) throw error;
    return contacts;
  }
}

class _FakeOfficialLocal implements OfficialContactsLocalDataSource {
  List<ContactModel> copy = [];
  List<ContactModel> asset = [];
  List<ContactModel>? saved;
  Object? copyError;
  Object? saveError;
  Object? assetError;

  @override
  Future<List<ContactModel>> readCopy() async {
    if (copyError case final Object error) throw error;
    return copy;
  }

  @override
  Future<void> saveCopy(List<ContactModel> contacts) async {
    if (saveError case final Object error) throw error;
    saved = contacts;
  }

  @override
  Future<List<ContactModel>> readAsset() async {
    if (assetError case final Object error) throw error;
    return asset;
  }
}

class _FailingPersonalSource implements PersonalContactsLocalDataSource {
  @override
  Future<List<ContactModel>> read() async => throw StateError('bad cache');
  @override
  Future<void> save(ContactModel contact) async => throw UnimplementedError();
  @override
  Future<void> delete(String id) async => throw UnimplementedError();
}
