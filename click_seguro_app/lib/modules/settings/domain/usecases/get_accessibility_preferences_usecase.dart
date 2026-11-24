import 'package:click_seguro_app/modules/common/accessibility/accessibility_preferences.dart';
import 'package:click_seguro_app/modules/settings/domain/repositories/accessibility_repository.dart';

class GetAccessibilityPreferencesUseCase {
  GetAccessibilityPreferencesUseCase(this._repository);

  final AccessibilityRepository _repository;

  Future<AccessibilityPreferences> call() => _repository.getPreferences();
}
