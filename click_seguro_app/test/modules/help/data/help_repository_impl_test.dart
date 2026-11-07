import 'package:click_seguro_app/core/errors/cache_failure.dart';
import 'package:click_seguro_app/modules/help/data/datasources/official_contacts_local_data_source.dart';
import 'package:click_seguro_app/modules/help/data/datasources/personal_contacts_local_data_source.dart';
import 'package:click_seguro_app/modules/help/data/models/contact_model.dart';
import 'package:click_seguro_app/modules/help/data/repositories/help_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('falha local vira CacheFailure no Either', () async {
    final repository = HelpRepositoryImpl(
      _OfficialSource(),
      _FailingPersonalSource(),
    );

    final result = await repository.getPersonalContacts();

    expect(result.getLeft().toNullable(), isA<CacheFailure>());
  });
}

class _OfficialSource implements OfficialContactsLocalDataSource {
  @override
  Future<List<ContactModel>> read() async => [];
}

class _FailingPersonalSource implements PersonalContactsLocalDataSource {
  @override
  Future<List<ContactModel>> read() async => throw StateError('bad cache');
  @override
  Future<void> save(ContactModel contact) async => throw UnimplementedError();
  @override
  Future<void> delete(String id) async => throw UnimplementedError();
}
