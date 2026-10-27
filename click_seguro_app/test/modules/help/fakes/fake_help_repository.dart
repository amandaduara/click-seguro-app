import 'package:click_seguro_app/core/errors/failure.dart';

import 'dart:async';

import 'package:click_seguro_app/modules/help/domain/entities/contact_entity.dart';
import 'package:click_seguro_app/modules/help/domain/repositories/help_repository.dart';
import 'package:fpdart/fpdart.dart';

class FakeHelpRepository implements HelpRepository {
  List<ContactEntity> official = [];
  List<ContactEntity> personal = [];
  Failure? readFailure;
  Failure? writeFailure;
  ContactEntity? saved;
  Completer<Either<Failure, ContactEntity>>? saveCompleter;
  String? deletedId;

  @override
  Future<Either<Failure, List<ContactEntity>>> getOfficialContacts() async =>
      readFailure == null ? Right(official) : Left(readFailure!);

  @override
  Future<Either<Failure, List<ContactEntity>>> getPersonalContacts() async =>
      readFailure == null ? Right(personal) : Left(readFailure!);

  @override
  Future<Either<Failure, ContactEntity>> savePersonalContact(
    ContactEntity contact,
  ) async {
    final pending = saveCompleter;
    if (pending != null) return pending.future;
    if (writeFailure != null) return Left(writeFailure!);
    saved = contact;
    personal = [
      for (final current in personal)
        if (current.id != contact.id) current,
      contact,
    ];
    return Right(contact);
  }

  @override
  Future<Either<Failure, Unit>> deletePersonalContact(String id) async {
    if (writeFailure != null) return Left(writeFailure!);
    deletedId = id;
    personal = personal.where((contact) => contact.id != id).toList();
    return const Right(unit);
  }
}
