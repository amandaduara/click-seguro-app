import 'package:click_seguro_app/core/errors/cache_failure.dart';
import 'package:click_seguro_app/core/errors/failure.dart';
import 'package:click_seguro_app/modules/common/accessibility/accessibility_preferences.dart';
import 'package:click_seguro_app/modules/settings/domain/repositories/accessibility_repository.dart';
import 'package:click_seguro_app/modules/settings/domain/usecases/get_accessibility_preferences_usecase.dart';
import 'package:click_seguro_app/modules/settings/domain/usecases/save_accessibility_preferences_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../fakes/fake_accessibility_repository.dart';

void main() {
  late FakeAccessibilityRepository repository;

  setUp(() => repository = FakeAccessibilityRepository());

  test('Get devolve o que o repository leu', () async {
    final stored = const AccessibilityPreferences.defaults().copyWith(
      highContrast: true,
    );
    repository.stored = stored;

    expect(
      await GetAccessibilityPreferencesUseCase(repository).call(),
      stored,
    );
  });

  test('Save repassa ao repository e devolve o resultado', () async {
    final AccessibilityRepository repo = repository;
    final preferences = const AccessibilityPreferences.defaults().copyWith(
      fontScale: FontScaleLevel.large,
    );

    final Either<Failure, Unit> ok = await SaveAccessibilityPreferencesUseCase(
      repo,
    ).call(preferences);
    expect(ok.isRight(), isTrue);
    expect(repository.saved, [preferences]);

    repository.saveFailure = const CacheFailure();
    final failed = await SaveAccessibilityPreferencesUseCase(
      repo,
    ).call(preferences);
    expect(failed.isLeft(), isTrue);
  });
}
