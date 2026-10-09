import 'dart:async';

import 'package:click_seguro_app/core/errors/failure.dart';
import 'package:click_seguro_app/modules/common/accessibility/accessibility_preferences.dart';
import 'package:click_seguro_app/modules/settings/domain/repositories/accessibility_repository.dart';
import 'package:fpdart/fpdart.dart';

class FakeAccessibilityRepository implements AccessibilityRepository {
  AccessibilityPreferences stored = const AccessibilityPreferences.defaults();

  /// Gravações pedidas, em ordem (inclusive as que falharam).
  final List<AccessibilityPreferences> saved = [];

  Failure? saveFailure;

  /// Quando definido, a gravação só termina ao completar.
  Completer<void>? saveGate;

  @override
  Future<AccessibilityPreferences> getPreferences() async => stored;

  @override
  Future<Either<Failure, Unit>> savePreferences(
    AccessibilityPreferences preferences,
  ) async {
    saved.add(preferences);
    await saveGate?.future;
    final Failure? failure = saveFailure;
    if (failure != null) return Left(failure);
    stored = preferences;
    return const Right(unit);
  }
}
