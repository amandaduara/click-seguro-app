import 'package:click_seguro_app/modules/common/api_client/api_client.dart';
import 'package:click_seguro_app/modules/profile/data/datasources/profile_remote_data_source.dart';
import 'package:click_seguro_app/modules/profile/data/models/activity_progress_model.dart';
import 'package:click_seguro_app/modules/profile/data/models/profile_model.dart';
import 'package:click_seguro_app/modules/profile/domain/entities/news_counts_entity.dart';
import 'package:click_seguro_app/modules/profile/domain/entities/profile_update.dart';

import 'profile_fixtures.dart';

/// Datasource em memória: com [error], todo método lança.
class FakeProfileRemoteDataSource implements ProfileRemoteDataSource {
  ApiException? error;

  ProfileModel profile = ProfileModel.fromJson(profileJson());
  NewsCountsEntity counts = const NewsCountsEntity(
    read: 12,
    saved: 5,
    liked: 9,
  );
  ActivityProgressModel progress = ActivityProgressModel.fromJson(
    modulesJson(modules: [moduleJson(id: 'm1')]),
  );
  String avatarUrl = 'https://img.test/nova.png';

  final List<ProfileUpdate> updates = [];
  final List<String> uploadedPaths = [];
  int removeCalls = 0;

  Future<T> _answer<T>(T value) async {
    if (error != null) throw error!;
    return value;
  }

  @override
  Future<ProfileModel> getProfile() => _answer(profile);

  @override
  Future<NewsCountsEntity> getNewsCounts() => _answer(counts);

  @override
  Future<ActivityProgressModel> getActivityProgress() => _answer(progress);

  @override
  Future<void> updateProfile(ProfileUpdate update) {
    updates.add(update);
    return _answer(null);
  }

  @override
  Future<String> uploadAvatar(String filePath) {
    uploadedPaths.add(filePath);
    return _answer(avatarUrl);
  }

  @override
  Future<void> removeAvatar() {
    removeCalls++;
    return _answer(null);
  }
}
