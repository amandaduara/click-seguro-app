import 'package:click_seguro_app/core/errors/cache_failure.dart';
import 'package:click_seguro_app/core/errors/failure.dart';
import 'package:click_seguro_app/modules/common/api_client/api_client.dart';
import 'package:click_seguro_app/modules/common/api_client/api_failure_mapper.dart';
import 'package:click_seguro_app/modules/help/data/datasources/official_contacts_local_data_source.dart';
import 'package:click_seguro_app/modules/help/data/datasources/official_contacts_remote_data_source.dart';
import 'package:click_seguro_app/modules/help/data/datasources/personal_contacts_local_data_source.dart';
import 'package:click_seguro_app/modules/help/data/models/contact_model.dart';
import 'package:click_seguro_app/modules/help/domain/entities/contact_entity.dart';
import 'package:click_seguro_app/modules/help/domain/repositories/help_repository.dart';
import 'package:fpdart/fpdart.dart';

class HelpRepositoryImpl implements HelpRepository {
  HelpRepositoryImpl(this._officialRemote, this._official, this._personal);

  final OfficialContactsRemoteDataSource _officialRemote;
  final OfficialContactsLocalDataSource _official;
  final PersonalContactsLocalDataSource _personal;

  /// Offline-first: API → guarda a cópia → devolve. Se a API falhar (sem
  /// internet, servidor dormindo) ou vier vazia, devolve a cópia guardada;
  /// sem cópia, o asset do app. Numa emergência a lista não fica vazia por
  /// falta de rede se houver qualquer cópia.
  @override
  Future<Either<Failure, List<ContactEntity>>> getOfficialContacts() async {
    Failure failure = const CacheFailure();
    try {
      final remote = await _officialRemote.fetch();
      if (remote.isNotEmpty) {
        await _saveCopy(remote);
        return Right(_entities(remote));
      }
    } on ApiException catch (e) {
      failure = e.toFailure();
    } catch (_) {
      // Segue para a cópia local.
    }
    try {
      final copy = await _official.readCopy();
      if (copy.isNotEmpty) return Right(_entities(copy));
    } catch (_) {
      // Cópia ilegível: segue para o asset.
    }
    try {
      return Right(_entities(await _official.readAsset()));
    } catch (_) {
      return Left(failure);
    }
  }

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

  /// Falha ao guardar não esconde a lista que a API acabou de devolver.
  Future<void> _saveCopy(List<ContactModel> contacts) async {
    try {
      await _official.saveCopy(contacts);
    } catch (_) {
      // A próxima busca tenta guardar de novo.
    }
  }

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
