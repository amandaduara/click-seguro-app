import 'package:click_seguro_app/core/errors/cache_failure.dart';
import 'package:click_seguro_app/core/errors/failure.dart';
import 'package:click_seguro_app/modules/help/data/datasources/official_contacts_local_data_source.dart';
import 'package:click_seguro_app/modules/help/data/datasources/personal_contacts_local_data_source.dart';
import 'package:click_seguro_app/modules/help/data/models/contact_model.dart';
import 'package:click_seguro_app/modules/help/domain/entities/contact_entity.dart';
import 'package:click_seguro_app/modules/help/domain/repositories/help_repository.dart';
import 'package:fpdart/fpdart.dart';

class HelpRepositoryImpl implements HelpRepository {
  HelpRepositoryImpl(this._official, this._personal);

  final OfficialContactsLocalDataSource _official;
  final PersonalContactsLocalDataSource _personal;

  @override
  Future<Either<Failure, List<ContactEntity>>> getOfficialContacts() =>
      _guard(() async => _official.read().then(_entities));

  @override
  Future<Either<Failure, List<ContactEntity>>> getPersonalContacts() =>
      _guard(() async => _personal.read().then(_entities));

  @override
  Future<Either<Failure, ContactEntity>> savePersonalContact(
    ContactEntity contact,
  ) => _guard(() async {
    final model = ContactModel.fromEntity(contact);
    await _personal.save(model);
    return model.toEntity();
  });

  @override
  Future<Either<Failure, Unit>> deletePersonalContact(String id) =>
      _guard(() async {
        await _personal.delete(id);
        return unit;
      });

  Future<Either<Failure, T>> _guard<T>(Future<T> Function() action) async {
    try {
      return Right(await action());
    } catch (_) {
      return const Left(CacheFailure());
    }
  }

  List<ContactEntity> _entities(List<ContactModel> models) => [
    for (final model in models) model.toEntity(),
  ];
}
