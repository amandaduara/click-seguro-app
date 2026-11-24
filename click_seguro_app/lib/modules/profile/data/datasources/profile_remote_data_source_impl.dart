import 'package:click_seguro_app/modules/common/api_client/api_client.dart';
import 'package:click_seguro_app/modules/profile/data/datasources/profile_remote_data_source.dart';
import 'package:click_seguro_app/modules/profile/data/models/activity_progress_model.dart';
import 'package:click_seguro_app/modules/profile/data/models/profile_model.dart';
import 'package:click_seguro_app/modules/profile/domain/entities/news_counts_entity.dart';
import 'package:click_seguro_app/modules/profile/domain/entities/profile_update.dart';

/// Datasource próprio: não importa `news` nem `activities` (R1 de
/// specs/012-perfil).
class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  ProfileRemoteDataSourceImpl(this._apiClient);

  static const String mePath = '/users/me';
  static const String avatarPath = '/users/me/avatar';
  static const String modulesPath = '/app/educational/modules';
  static String newsListPath(String list) => '/users/me/news/$list';

  static const String _avatarField = 'avatar';
  static const String _jpeg = 'image/jpeg';
  static const Map<String, String> _imageTypes = {
    'png': 'image/png',
    'webp': 'image/webp',
    'jpg': _jpeg,
    'jpeg': _jpeg,
  };

  final ApiClient _apiClient;

  @override
  Future<ProfileModel> getProfile() async {
    final response = await _apiClient.get(mePath);
    return response.toModel(ProfileModel.fromJson);
  }

  @override
  Future<NewsCountsEntity> getNewsCounts() async {
    final [read, saved, liked] = await Future.wait([
      _newsTotal('read'),
      _newsTotal('saved'),
      _newsTotal('liked'),
    ]);
    return NewsCountsEntity(read: read, saved: saved, liked: liked);
  }

  @override
  Future<ActivityProgressModel> getActivityProgress() async {
    final response = await _apiClient.get(modulesPath);
    return response.toModel(ActivityProgressModel.fromJson);
  }

  @override
  Future<void> updateProfile(ProfileUpdate update) async {
    await _apiClient.patch(
      mePath,
      data: {
        'name': ?update.name,
        'email': ?update.email,
        'phone': ?update.phone,
      },
    );
  }

  @override
  Future<String> uploadAvatar(String filePath) async {
    final response = await _apiClient.postMultipart(
      avatarPath,
      fieldName: _avatarField,
      filePath: filePath,
      contentType: _contentTypeOf(filePath),
    );
    return response.toModel((json) => json['avatarUrl'] as String);
  }

  @override
  Future<void> removeAvatar() async {
    await _apiClient.delete(avatarPath);
  }

  Future<int> _newsTotal(String list) async {
    final response = await _apiClient.get(
      newsListPath(list),
      queryParameters: {'limit': 1},
    );
    return response.toModel(
      (json) =>
          ((json['meta'] as Map<String, dynamic>)['total'] as num).toInt(),
    );
  }

  /// O `ImageStorageService` guarda com a extensão original; sem uma
  /// conhecida, JPEG.
  static String _contentTypeOf(String path) {
    final String extension = path.split('.').last.toLowerCase();
    return _imageTypes[extension] ?? _jpeg;
  }
}
