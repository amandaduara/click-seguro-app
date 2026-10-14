import 'package:click_seguro_app/modules/profile/data/models/activity_progress_model.dart';
import 'package:click_seguro_app/modules/profile/data/models/profile_model.dart';
import 'package:click_seguro_app/modules/profile/domain/entities/activity_progress_entity.dart';
import 'package:click_seguro_app/modules/profile/domain/entities/profile_entity.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fakes/profile_fixtures.dart';

void main() {
  group('ProfileModel', () {
    test('lê todos os campos do GET /users/me', () {
      final profile = ProfileModel.fromJson(
        profileJson(
          phone: '+5511912345678',
          avatarUrl: 'https://img.test/a.png',
          receiveNotifications: false,
        ),
      ).toEntity();

      expect(profile.name, 'Maria da Silva');
      expect(profile.email, 'maria@exemplo.com');
      expect(profile.phone, '+5511912345678');
      expect(profile.avatarUrl, 'https://img.test/a.png');
      expect(profile.receiveNotifications, isFalse);
    });

    test('phone e avatarUrl nulos ficam nulos', () {
      final profile = ProfileModel.fromJson(profileJson()).toEntity();

      expect(profile.phone, isNull);
      expect(profile.avatarUrl, isNull);
    });

    test('avatarUrl vazia vira null', () {
      final profile = ProfileModel.fromJson(
        profileJson(avatarUrl: ''),
      ).toEntity();

      expect(profile.avatarUrl, isNull);
    });

    test('receiveNotifications ausente vale true', () {
      final json = profileJson()..remove('receiveNotifications');

      expect(ProfileModel.fromJson(json).toEntity().receiveNotifications, true);
    });
  });

  group('ProfileEntity.initials', () {
    ProfileEntity named(String name) =>
        ProfileEntity(name: name, email: 'maria@exemplo.com');

    test('duas primeiras palavras', () {
      expect(named('Maria da Silva').initials, 'MS');
    });

    test('uma palavra', () {
      expect(named('Ana').initials, 'A');
    });

    test('ignora espaços extras e usa maiúsculas', () {
      expect(named('  maria   da  silva ').initials, 'MS');
    });

    test('pula conectivos curtos (da, de, do)', () {
      expect(named('João de Souza').initials, 'JS');
    });
  });

  group('ActivityProgressModel', () {
    test('lê os módulos e o total de lições concluídas', () {
      final progress = ActivityProgressModel.fromJson(
        modulesJson(
          modules: [
            moduleJson(id: 'm1', completedCount: 3),
            moduleJson(
              id: 'm2',
              title: 'Phishing',
              order: 2,
              lessonsCount: 4,
              completedCount: 1,
            ),
          ],
          totalLessonsCompleted: 4,
        ),
      ).toEntity();

      expect(progress.lessonsCompleted, 4);
      expect(progress.modules, hasLength(2));
      final ModuleProgressEntity second = progress.modules[1];
      expect(second.title, 'Phishing');
      expect(second.order, 2);
      expect(second.lessonsCount, 4);
      expect(second.completedCount, 1);
    });

    test('números em double viram int', () {
      final json = modulesJson(
        modules: [
          {...moduleJson(id: 'm1'), 'lessonsCount': 3.0, 'completedCount': 2.0},
        ],
      )..['totalLessonsCompleted'] = 2.0;

      final progress = ActivityProgressModel.fromJson(json).toEntity();

      expect(progress.modules.single.lessonsCount, 3);
      expect(progress.modules.single.completedCount, 2);
      expect(progress.lessonsCompleted, 2);
    });

    test('isCompleted, modulesCompleted e modulesWithLessons', () {
      final progress = ActivityProgressModel.fromJson(
        modulesJson(
          modules: [
            moduleJson(id: 'm1', completedCount: 3),
            moduleJson(id: 'm2', completedCount: 1),
            moduleJson(id: 'm3', lessonsCount: 0),
          ],
        ),
      ).toEntity();

      expect(progress.modules.map((m) => m.isCompleted), [true, false, false]);
      expect(progress.modulesCompleted, 1);
      expect(progress.modulesWithLessons, 2);
    });

    test('sem módulos', () {
      final progress = ActivityProgressModel.fromJson(modulesJson()).toEntity();

      expect(progress.modules, isEmpty);
      expect(progress.modulesCompleted, 0);
      expect(progress.modulesWithLessons, 0);
    });
  });
}
