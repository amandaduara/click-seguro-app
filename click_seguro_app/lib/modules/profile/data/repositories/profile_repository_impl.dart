import 'package:click_seguro_app/core/errors/errors.dart';
import 'package:click_seguro_app/modules/common/api_client/api_client.dart';
import 'package:click_seguro_app/modules/common/api_client/api_failure_mapper.dart';
import 'package:click_seguro_app/modules/profile/data/datasources/profile_remote_data_source.dart';
import 'package:click_seguro_app/modules/profile/domain/entities/activity_progress_entity.dart';
import 'package:click_seguro_app/modules/profile/domain/entities/news_counts_entity.dart';
import 'package:click_seguro_app/modules/profile/domain/entities/profile_entity.dart';
import 'package:click_seguro_app/modules/profile/domain/entities/profile_update.dart';
import 'package:click_seguro_app/modules/profile/domain/failures/profile_failures.dart';
import 'package:click_seguro_app/modules/profile/domain/repositories/profile_repository.dart';
import 'package:fpdart/fpdart.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl(this._remote, {int Function()? clock})
    : _clock = clock ?? _now;

  static const String emailInUseCode = 'USER_EMAIL_ALREADY_EXISTS';
  static const String invalidImageCode = 'INVALID_IMAGE_TYPE';

  /// Parâmetro da versão da foto no endereço mostrado.
  static const String photoVersionParam = 'v';

  final ProfileRemoteDataSource _remote;
  final int Function() _clock;

  /// Quando a foto foi trocada nesta abertura do app (`null` = não foi).
  ///
  /// O servidor pode devolver a foto nova no mesmo endereço da antiga; a
  /// imagem guardada (no app e na rede de entrega) continuaria aparecendo.
  /// Com a versão no endereço, a foto nova é baixada; sem troca, o endereço
  /// fica igual e a imagem guardada é aproveitada. O repositório é um
  /// singleton, então a versão vale para o Perfil e para a edição.
  int? _photoVersion;

  ProfileEntity? _lastProfile;

  @override
  ProfileEntity? get lastProfile => _lastProfile;

  static int _now() => DateTime.now().millisecondsSinceEpoch;

  @override
  Future<Either<Failure, ProfileEntity>> getProfile() => _guard(() async {
    final ProfileEntity profile = (await _remote.getProfile()).toEntity();
    final String? url = profile.avatarUrl;
    return _lastProfile = url == null
        ? profile
        : profile.withAvatarUrl(_versioned(url));
  });

  @override
  Future<Either<Failure, NewsCountsEntity>> getNewsCounts() =>
      _guard(_remote.getNewsCounts);

  @override
  Future<Either<Failure, ActivityProgressEntity>> getActivityProgress() =>
      _guard(() async => (await _remote.getActivityProgress()).toEntity());

  /// O 500 que o servidor devolve para qualquer troca de e-mail (R0) cai no
  /// mapeamento padrão: falha genérica.
  @override
  Future<Either<Failure, Unit>> updateProfile(ProfileUpdate update) =>
      _guard(() async {
        await _remote.updateProfile(update);
        return unit;
      }, specific: {emailInUseCode: const EmailInUseFailure()});

  @override
  Future<Either<Failure, String>> uploadAvatar(String filePath) =>
      _guard(() async {
        final String url = await _remote.uploadAvatar(filePath);
        _photoVersion = _clock();
        final String versioned = _versioned(url);
        _lastProfile = _lastProfile?.withAvatarUrl(versioned);
        return versioned;
      }, specific: {invalidImageCode: const AvatarTypeFailure()});

  @override
  Future<Either<Failure, Unit>> removeAvatar() => _guard(() async {
    await _remote.removeAvatar();
    _lastProfile = _lastProfile?.withAvatarUrl(null);
    return unit;
  });

  String _versioned(String url) {
    final int? version = _photoVersion;
    final Uri? uri = Uri.tryParse(url);
    if (version == null || uri == null) return url;
    return uri
        .replace(
          queryParameters: {
            ...uri.queryParameters,
            photoVersionParam: '$version',
          },
        )
        .toString();
  }

  /// [specific]: falha por `errorCode`, antes do mapeamento padrão.
  Future<Either<Failure, T>> _guard<T>(
    Future<T> Function() action, {
    Map<String, Failure> specific = const {},
  }) async {
    try {
      return Right(await action());
    } on ApiException catch (e) {
      return Left(specific[e.errorCode] ?? e.toFailure());
    }
  }
}
