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
}
