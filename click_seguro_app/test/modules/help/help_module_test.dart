import 'package:click_seguro_app/modules/common/services/external_launcher_service.dart';
import 'package:click_seguro_app/modules/common/services/image_storage_service.dart';
import 'package:click_seguro_app/modules/common/services/local_cache_service.dart';
import 'package:click_seguro_app/modules/help/help_module.dart';
import 'package:click_seguro_app/modules/help/presentation/controller/contact_form_controller.dart';
import 'package:click_seguro_app/modules/help/presentation/controller/help_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

import '../../fakes/fake_external_launcher_service.dart';
import '../../fakes/fake_image_storage_service.dart';
import '../../fakes/fake_local_cache_service.dart';

void main() {
  final injector = GetIt.instance;

  setUp(() async => injector.reset());
  tearDown(() async => injector.reset());

  test(
    'registra serviços e resolve controllers por abertura de tela',
    () async {
      injector
        ..registerSingleton<LocalCacheService>(FakeLocalCacheService())
        ..registerSingleton<ImageStorageService>(FakeImageStorageService())
        ..registerSingleton<ExternalLauncherService>(
          FakeExternalLauncherService(),
        );

      await HelpModule().registerServices(injector);

      final help = injector<HelpController>();
      final form = injector<ContactFormController>(param1: null);
      expect(help, isA<HelpController>());
      expect(form, isA<ContactFormController>());
      help.dispose();
      form.dispose();
    },
  );
}
