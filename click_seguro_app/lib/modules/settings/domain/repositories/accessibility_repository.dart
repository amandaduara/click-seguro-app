import 'package:click_seguro_app/core/errors/failure.dart';
import 'package:click_seguro_app/modules/common/accessibility/accessibility_preferences.dart';
import 'package:fpdart/fpdart.dart';

abstract class AccessibilityRepository {
  /// Preferências salvas; sem registro ou com falha de leitura, os padrões
  /// (FR-008, FR-009).
  Future<AccessibilityPreferences> getPreferences();

  Future<Either<Failure, Unit>> savePreferences(
    AccessibilityPreferences preferences,
  );
}
