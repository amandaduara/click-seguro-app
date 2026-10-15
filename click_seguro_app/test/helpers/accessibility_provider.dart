import 'package:click_seguro_app/modules/common/accessibility/accessibility_preferences_notifier.dart';
import 'package:click_seguro_app/modules/settings/data/datasources/accessibility_local_data_source_impl.dart';
import 'package:click_seguro_app/modules/settings/data/repositories/accessibility_repository_impl.dart';
import 'package:click_seguro_app/modules/settings/domain/usecases/get_accessibility_preferences_usecase.dart';
import 'package:click_seguro_app/modules/settings/domain/usecases/save_accessibility_preferences_usecase.dart';
import 'package:click_seguro_app/modules/settings/presentation/controller/accessibility_controller.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../fakes/fake_local_cache_service.dart';

/// `AccessibilityController` de verdade sobre [cache] (padrão: vazio), como o
/// `SettingsModule` entrega ao app. [notifier] é o valor em vigor.
AccessibilityController buildAccessibilityController({
  FakeLocalCacheService? cache,
  AccessibilityPreferencesNotifier? notifier,
}) {
  final repository = AccessibilityRepositoryImpl(
    AccessibilityLocalDataSourceImpl(cache ?? FakeLocalCacheService()),
  );
  return AccessibilityController(
    getPreferences: GetAccessibilityPreferencesUseCase(repository),
    savePreferences: SaveAccessibilityPreferencesUseCase(repository),
    notifier: notifier ?? AccessibilityPreferencesNotifier(),
  );
}

/// O controller acima do app, para a tela de Acessibilidade abrir.
SingleChildWidget fakeAccessibilityProvider() =>
    ChangeNotifierProvider(create: (_) => buildAccessibilityController());
