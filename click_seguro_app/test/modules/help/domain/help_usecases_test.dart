import 'package:click_seguro_app/core/errors/cache_failure.dart';
import 'package:click_seguro_app/core/errors/failure.dart';
import 'package:click_seguro_app/modules/help/domain/entities/contact_entity.dart';
import 'package:click_seguro_app/modules/help/domain/failures/contact_validation_failure.dart';
import 'package:click_seguro_app/modules/help/domain/repositories/help_repository.dart';
import 'package:click_seguro_app/modules/help/domain/usecases/delete_personal_contact_usecase.dart';
import 'package:click_seguro_app/modules/help/domain/usecases/get_official_contacts_usecase.dart';
import 'package:click_seguro_app/modules/help/domain/usecases/get_personal_contacts_usecase.dart';
import 'package:click_seguro_app/modules/help/domain/usecases/save_personal_contact_usecase.dart';
import 'package:fpdart/fpdart.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late _FakeHelpRepository repository;
  setUp(() => repository = _FakeHelpRepository());

  test('get usecases repassam listas e falhas', () async {
    repository.personal = [contact];
    expect((await GetPersonalContactsUseCase(repository)()).toNullable(), [
      contact,
    ]);
    repository.getError = const CacheFailure();
    expect(
      (await GetOfficialContactsUseCase(repository)()).getLeft().toNullable(),
      isA<CacheFailure>(),
    );
  });

  test('save valida e normaliza campos antes de persistir', () async {
    const input = ContactEntity(
      id: '1',
      name: ' Ana ',
      phone: '+55 (11) 99999-1234',
      type: ContactType.personal,
      relationship: '  Irmã ',
    );

    final result = await SavePersonalContactUseCase(repository)(input);

    expect(result.toNullable(), repository.saved);
    expect(repository.saved?.name, 'Ana');
    expect(repository.saved?.phone, '+5511999991234');
    expect(repository.saved?.relationship, 'Irmã');
    expect(repository.saved?.type, ContactType.personal);
  });

  test('save inválido não chama repository e retorna falha tipada', () async {
    final result = await SavePersonalContactUseCase(repository)(
      const ContactEntity(
        id: '1',
        name: '  ',
        phone: '11abc',
        type: ContactType.personal,
      ),
    );

    expect(result.getLeft().toNullable(), isA<ContactValidationFailure>());
    expect(repository.saved, isNull);
  });

  test('save repassa falha do cache', () async {
    repository.saveError = const CacheFailure();
    final result = await SavePersonalContactUseCase(repository)(contact);
    expect(result.getLeft().toNullable(), isA<CacheFailure>());
  });

  test('delete repassa id e falha', () async {
    await DeletePersonalContactUseCase(repository)('id-1');
    expect(repository.deletedId, 'id-1');
    repository.deleteError = const CacheFailure();
    expect(
      (await DeletePersonalContactUseCase(repository)(
        'id-2',
      )).getLeft().toNullable(),
      isA<CacheFailure>(),
    );
  });
}

const contact = ContactEntity(
  id: 'id-1',
  name: 'Ana',
  phone: '11999999999',
  type: ContactType.personal,
);

class _FakeHelpRepository implements HelpRepository {
  List<ContactEntity> personal = [];
  ContactEntity? saved;
  String? deletedId;
  Failure? getError;
  Failure? saveError;
  Failure? deleteError;

  @override
  Future<Either<Failure, List<ContactEntity>>> getOfficialContacts() async =>
      getError == null ? const Right([]) : Left(getError!);

  @override
  Future<Either<Failure, List<ContactEntity>>> getPersonalContacts() async =>
      getError == null ? Right(personal) : Left(getError!);

  @override
  Future<Either<Failure, ContactEntity>> savePersonalContact(
    ContactEntity contact,
  ) async {
    if (saveError != null) return Left(saveError!);
    saved = contact;
    return Right(contact);
  }

  @override
  Future<Either<Failure, Unit>> deletePersonalContact(String id) async {
    deletedId = id;
    return deleteError == null ? const Right(unit) : Left(deleteError!);
  }
}
