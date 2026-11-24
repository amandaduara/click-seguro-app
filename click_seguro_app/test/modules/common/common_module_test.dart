import 'package:click_seguro_app/modules/common/accessibility/accessibility_preferences_notifier.dart';
import 'package:click_seguro_app/modules/common/common.dart';
import 'package:click_seguro_app/modules/common/presentation/controller/read_aloud_controller.dart';
import 'package:click_seguro_app/modules/common/services/external_launcher_service.dart';
import 'package:click_seguro_app/modules/common/services/image_storage_service.dart';
import 'package:click_seguro_app/modules/common/services/share_service.dart';
import 'package:click_seguro_app/modules/common/services/text_to_speech_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  // O FlutterTts() registra um canal de plataforma ao ser criado.
  TestWidgetsFlutterBinding.ensureInitialized();

  final GetIt injector = GetIt.instance;

  setUp(() async {
    await injector.reset();
    SharedPreferences.setMockInitialValues({});
    await CommonModule().registerServices(injector);
  });

  tearDown(() => injector.reset());

  test('registra a voz pelo contrato', () {
    expect(injector<TextToSpeechService>(), isA<FlutterTextToSpeechService>());
  });

  test('registra abrir endereço e ligar pelo contrato', () {
    expect(
      injector<ExternalLauncherService>(),
      isA<UrlLauncherExternalLauncherService>(),
    );
  });

  test('registra compartilhar pelo contrato', () {
    expect(injector<ShareService>(), isA<SharePlusShareService>());
  });

  test('registra fotos pelo contrato', () {
    expect(injector<ImageStorageService>(), isA<PlatformImageStorageService>());
  });

  test('ReadAloudController é um por página (factory)', () {
    expect(
      injector<ReadAloudController>(),
      isNot(same(injector<ReadAloudController>())),
    );
  });

  test('preferências de acessibilidade em vigor: uma só para o app', () {
    expect(
      injector<AccessibilityPreferencesNotifier>(),
      same(injector<AccessibilityPreferencesNotifier>()),
    );
  });
}
