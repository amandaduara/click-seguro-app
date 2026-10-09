import 'package:click_seguro_app/core/errors/cache_failure.dart';
import 'package:click_seguro_app/core/errors/failure.dart';
import 'package:click_seguro_app/modules/common/accessibility/accessibility_preferences.dart';
import 'package:click_seguro_app/modules/settings/data/datasources/accessibility_local_data_source.dart';
import 'package:click_seguro_app/modules/settings/data/models/accessibility_preferences_model.dart';
import 'package:click_seguro_app/modules/settings/domain/repositories/accessibility_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:fpdart/fpdart.dart';

class AccessibilityRepositoryImpl implements AccessibilityRepository {
  AccessibilityRepositoryImpl(this._local);

  final AccessibilityLocalDataSource _local;

  @override
  Future<AccessibilityPreferences> getPreferences() async {
    try {
      final Map<String, dynamic>? json = await _local.read();
      return json == null
          ? const AccessibilityPreferences.defaults()
          : AccessibilityPreferencesModel.fromJson(json);
    } catch (error) {
      // O app abre com os padrões (FR-009, SC-005).
      debugPrint('Preferências de acessibilidade ilegíveis: $error');
      return const AccessibilityPreferences.defaults();
    }
  }

  @override
  Future<Either<Failure, Unit>> savePreferences(
    AccessibilityPreferences preferences,
  ) async {
    try {
      await _local.write(AccessibilityPreferencesModel.toJson(preferences));
      return const Right(unit);
    } catch (error) {
      debugPrint('Falha ao salvar a acessibilidade: $error');
      return const Left(CacheFailure());
    }
  }
}
