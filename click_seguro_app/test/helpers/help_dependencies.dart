import 'package:click_seguro_app/modules/common/services/external_launcher_service.dart';
import 'package:click_seguro_app/modules/common/services/image_storage_service.dart';
import 'package:click_seguro_app/modules/common/services/local_cache_service.dart';
import 'package:click_seguro_app/modules/help/domain/repositories/help_repository.dart';
import 'package:click_seguro_app/modules/help/help_module.dart';
import 'package:get_it/get_it.dart';

import '../fakes/fake_external_launcher_service.dart';
import '../fakes/fake_image_storage_service.dart';
import '../fakes/fake_local_cache_service.dart';
import '../modules/help/fakes/fake_help_repository.dart';

FakeHelpRepository registerHelpDependencies(
  GetIt injector, {
  FakeHelpRepository? repository,
  FakeImageStorageService? images,
  FakeExternalLauncherService? launcher,
}) {
  final fakeRepository = repository ?? FakeHelpRepository();
  final imageStorage = images ?? FakeImageStorageService();
  final externalLauncher = launcher ?? FakeExternalLauncherService();
  injector
    ..registerSingleton<LocalCacheService>(FakeLocalCacheService())
    ..registerSingleton<ImageStorageService>(imageStorage)
    ..registerSingleton<ExternalLauncherService>(externalLauncher);
  HelpModule().registerServices(injector);
  injector
    ..unregister<HelpRepository>()
    ..registerSingleton<HelpRepository>(fakeRepository);
  return fakeRepository;
}
