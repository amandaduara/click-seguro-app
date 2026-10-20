import 'dart:convert';

import 'package:click_seguro_app/modules/common/services/image_storage_service.dart';
import 'package:click_seguro_app/modules/common/services/external_launcher_service.dart';
import 'package:click_seguro_app/modules/common/services/local_cache_service.dart';

class FakeLocalCacheService implements LocalCacheService {
  final Map<String, Map<String, dynamic>> values = {};
  bool failWrite = false;

  @override
  Future<Map<String, dynamic>?> readJson(String key) async {
    final value = values[key];
    return value == null
        ? null
        : jsonDecode(jsonEncode(value)) as Map<String, dynamic>;
  }

  @override
  Future<void> writeJson(String key, Map<String, dynamic> value) async {
    if (failWrite) throw StateError('write failed');
    values[key] = jsonDecode(jsonEncode(value)) as Map<String, dynamic>;
  }

  @override
  Future<void> remove(String key) async => values.remove(key);
}

class FakeImageStorageService implements ImageStorageService {
  final List<String> deletedPaths = [];

  @override
  Future<void> delete(String path) async => deletedPaths.add(path);

  @override
  Future<PickImageResult> pickImage(PhotoSource source) async =>
      const PickImageCancelled();
}

class FakeExternalLauncherService implements ExternalLauncherService {
  bool canCallResult = true;
  bool callResult = true;
  String? calledPhone;

  @override
  Future<bool> canCall() async => canCallResult;

  @override
  Future<bool> call(String phoneNumber) async {
    calledPhone = phoneNumber;
    return callResult;
  }

  @override
  Future<bool> openUrl(String url) async => false;
}
