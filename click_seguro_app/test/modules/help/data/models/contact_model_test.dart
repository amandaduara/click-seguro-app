import 'package:click_seguro_app/modules/help/data/models/contact_model.dart';
import 'package:click_seguro_app/modules/help/domain/entities/contact_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ContactModel serializa todos os campos de forma tipada', () {
    const contact = ContactEntity(
      id: 'c1',
      name: 'Ana',
      phone: '+5511999999999',
      type: ContactType.personal,
      relationship: 'Irmã',
      photoPath: '/app/images/ana.jpg',
    );

    final model = ContactModel.fromEntity(contact);
    final json = model.toJson();
    final restored = ContactModel.fromJson(json).toEntity();

    expect(json, {
      'id': 'c1',
      'name': 'Ana',
      'phone': '+5511999999999',
      'type': 'personal',
      'relationship': 'Irmã',
      'photoPath': '/app/images/ana.jpg',
    });
    expect(restored.id, contact.id);
    expect(restored.name, contact.name);
    expect(restored.phone, contact.phone);
    expect(restored.type, contact.type);
    expect(restored.relationship, contact.relationship);
    expect(restored.photoPath, contact.photoPath);
  });

  test('campos opcionais ausentes assumem contato oficial', () {
    final model = ContactModel.fromJson({
      'id': 'official-1',
      'name': 'Polícia',
      'phone': '190',
    });

    expect(model.type, ContactType.official);
    expect(model.relationship, isNull);
    expect(model.photoPath, isNull);
    expect(model.toEntity().name, 'Polícia');
  });

  group('contato oficial da API (GET /app/official-contacts)', () {
    test('lê nome, telefone e descrição; a categoria vira oficial', () {
      final model = ContactModel.fromOfficialJson({
        'id': 'cmwji7nwg0000c12bs899nhx1',
        'name': 'Polícia Militar',
        'description': 'Emergência: ligue 190 se estiver em perigo',
        'type': 'POLICIA',
        'phone': '190',
        'email': null,
        'website': null,
      });

      expect(model.id, 'cmwji7nwg0000c12bs899nhx1');
      expect(model.name, 'Polícia Militar');
      expect(model.phone, '190');
      expect(model.type, ContactType.official);
      expect(
        model.toEntity().description,
        'Emergência: ligue 190 se estiver em perigo',
      );
    });

    test('descrição ausente, vazia ou de outro tipo fica nula', () {
      for (final Object? description in [null, '', '  ', 42]) {
        final model = ContactModel.fromOfficialJson({
          'id': 'o1',
          'name': 'Anatel',
          'phone': '1331',
          'description': ?description,
        });
        expect(model.description, isNull, reason: '$description');
      }
    });

    test('sem id, nome ou telefone (ou vazio) é inválido', () {
      final valid = {'id': 'o1', 'name': 'INSS', 'phone': '135'};
      for (final key in ['id', 'name', 'phone']) {
        expect(
          () => ContactModel.fromOfficialJson({...valid}..remove(key)),
          throwsFormatException,
          reason: key,
        );
        expect(
          () => ContactModel.fromOfficialJson({...valid, key: ' '}),
          throwsFormatException,
          reason: key,
        );
      }
      expect(
        () => ContactModel.fromOfficialJson({...valid, 'phone': null}),
        throwsFormatException,
      );
    });

    test('officialList ignora itens inválidos e mantém a ordem', () {
      final models = ContactModel.officialList([
        {'id': 'a', 'name': 'Polícia', 'phone': '190'},
        {'id': 'b', 'name': 'SaferNet', 'phone': null},
        'lixo',
        {'id': 'c', 'name': 'INSS', 'phone': '135'},
      ]);

      expect(models.map((model) => model.id), ['a', 'c']);
    });

    test('a cópia local (toJson) volta igual, com a descrição', () {
      final model = ContactModel.fromOfficialJson({
        'id': 'o1',
        'name': 'Banco Central',
        'phone': '145',
        'description': 'Atendimento ao cidadão: 145',
        'type': 'BANCO',
      });

      final restored = ContactModel.officialList([model.toJson()]).single;

      expect(model.toJson()['description'], 'Atendimento ao cidadão: 145');
      expect(restored.id, 'o1');
      expect(restored.name, 'Banco Central');
      expect(restored.phone, '145');
      expect(restored.description, 'Atendimento ao cidadão: 145');
    });
  });
}
