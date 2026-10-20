import 'package:click_seguro_app/modules/help/data/datasources/personal_contacts_local_data_source.dart';
import 'package:click_seguro_app/modules/help/data/models/contact_model.dart';
import 'package:click_seguro_app/modules/help/domain/entities/contact_entity.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/help_fakes.dart';

ContactModel contact({
  String id = 'a',
  String? photoPath,
  String name = 'Ana',
}) => ContactModel(
  id: id,
  name: name,
  phone: '11999999999',
  type: ContactType.personal,
  photoPath: photoPath,
);

void main() {
  test(
    'sem cache retorna lista vazia e usa uma chave global nomeada',
    () async {
      final cache = FakeLocalCacheService();
      final source = PersonalContactsLocalDataSource(
        cache,
        FakeImageStorageService(),
      );

      expect(await source.read(), isEmpty);
      expect(PersonalContactsLocalDataSource.cacheKey, isNotEmpty);
      expect(PersonalContactsLocalDataSource.cacheKey, isNot(contains('user')));
    },
  );

  test(
    'persistência é relida por uma nova instância e edição substitui por id',
    () async {
      final cache = FakeLocalCacheService();
      final images = FakeImageStorageService();
      final first = PersonalContactsLocalDataSource(cache, images);
      await first.save(contact(photoPath: '/old.jpg'));

      final second = PersonalContactsLocalDataSource(cache, images);
      await second.save(contact(name: 'Ana atualizada', photoPath: '/new.jpg'));

      final contacts = await PersonalContactsLocalDataSource(
        cache,
        images,
      ).read();
      expect(contacts, hasLength(1));
      expect(contacts.single.name, 'Ana atualizada');
      expect(images.deletedPaths, ['/old.jpg']);
    },
  );

  test(
    'falha ao persistir preserva a foto anterior e a lista anterior',
    () async {
      final cache = FakeLocalCacheService();
      final images = FakeImageStorageService();
      final source = PersonalContactsLocalDataSource(cache, images);
      await source.save(contact(photoPath: '/old.jpg'));
      cache.failWrite = true;

      await expectLater(
        source.save(contact(name: 'Não persistido', photoPath: '/new.jpg')),
        throwsA(isA<StateError>()),
      );
      cache.failWrite = false;

      expect((await source.read()).single.name, 'Ana');
      expect(images.deletedPaths, isEmpty);
    },
  );

  test('exclusão persiste a lista antes de apagar a foto', () async {
    final cache = FakeLocalCacheService();
    final images = FakeImageStorageService();
    final source = PersonalContactsLocalDataSource(cache, images);
    await source.save(contact(photoPath: '/ana.jpg'));

    await source.delete('a');

    expect(await source.read(), isEmpty);
    expect(images.deletedPaths, ['/ana.jpg']);
  });

  test('falha ao persistir exclusão conserva contato e foto', () async {
    final cache = FakeLocalCacheService();
    final images = FakeImageStorageService();
    final source = PersonalContactsLocalDataSource(cache, images);
    await source.save(contact(photoPath: '/ana.jpg'));
    cache.failWrite = true;

    await expectLater(source.delete('a'), throwsA(isA<StateError>()));

    expect(images.deletedPaths, isEmpty);
    cache.failWrite = false;
    expect((await source.read()).single.id, 'a');
  });
}
