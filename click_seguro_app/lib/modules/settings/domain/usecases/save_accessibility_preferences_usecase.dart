import 'package:click_seguro_app/core/errors/failure.dart';
import 'package:click_seguro_app/modules/common/accessibility/accessibility_preferences.dart';
import 'package:click_seguro_app/modules/settings/domain/repositories/accessibility_repository.dart';
import 'package:fpdart/fpdart.dart';

class SaveAccessibilityPreferencesUseCase {
  SaveAccessibilityPreferencesUseCase(this._repository);

  final AccessibilityRepository _repository;

  Future<Either<Failure, Unit>> call(AccessibilityPreferences preferences) =>
      _repository.savePreferences(preferences);
}
