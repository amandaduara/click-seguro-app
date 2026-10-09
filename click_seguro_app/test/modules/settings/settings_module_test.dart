import 'package:click_seguro_app/modules/common/accessibility/accessibility_preferences.dart';
import 'package:click_seguro_app/modules/common/accessibility/accessibility_preferences_notifier.dart';
import 'package:click_seguro_app/modules/common/common.dart';
import 'package:click_seguro_app/modules/settings/settings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final GetIt injector = GetIt.instance;

  tearDown(() => injector.reset());

  Future<void> register(Map<String, Object> stored) async {
    await injector.reset();
    SharedPreferences.setMockInitialValues(stored);
    await CommonModule().registerServices(injector);
    await SettingsModule().registerServices(injector);
  }

  test('AccessibilityController é um só e expõe um Provider', () async {
    await register({});

    expect(
      injector<AccessibilityController>(),
      same(injector<AccessibilityController>()),
    );
    expect(SettingsModule().providers(injector), hasLength(1));
  });

  test('load lê o registro salvo no aparelho e publica no notifier', () async {
    await register({
      'accessibility_preferences_v1':
          '{"fontScale":"largest","highContrast":true}',
    });

    await injector<AccessibilityController>().load();

    final preferences = injector<AccessibilityPreferencesNotifier>().value;
    expect(preferences.fontScale, FontScaleLevel.largest);
    expect(preferences.highContrast, isTrue);
  });
}
