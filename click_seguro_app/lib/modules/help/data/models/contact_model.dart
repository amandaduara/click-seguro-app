import 'package:click_seguro_app/modules/help/domain/entities/contact_entity.dart';

class ContactModel {
  const ContactModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.type,
    this.relationship,
    this.photoPath,
  });

  factory ContactModel.fromJson(Map<String, dynamic> json) {
    final typeValue = json['type'];
    final type = ContactType.values.where((value) => value.name == typeValue);
    if (typeValue != null && type.isEmpty) {
      throw const FormatException('Unknown contact type');
    }
    return ContactModel(
      id: _requiredString(json, 'id'),
      name: _requiredString(json, 'name'),
      phone: _requiredString(json, 'phone'),
      type: type.isEmpty ? ContactType.official : type.first,
      relationship: _optionalString(json, 'relationship'),
      photoPath: _optionalString(json, 'photoPath'),
    );
  }

  factory ContactModel.fromEntity(ContactEntity entity) => ContactModel(
    id: entity.id,
    name: entity.name,
    phone: entity.phone,
    type: entity.type,
    relationship: entity.relationship,
    photoPath: entity.photoPath,
  );

  final String id;
  final String name;
  final String phone;
  final ContactType type;
  final String? relationship;
  final String? photoPath;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'phone': phone,
    'type': type.name,
    if (relationship != null) 'relationship': relationship,
    if (photoPath != null) 'photoPath': photoPath,
  };

  ContactEntity toEntity() => ContactEntity(
    id: id,
    name: name,
    phone: phone,
    type: type,
    relationship: relationship,
    photoPath: photoPath,
  );

  static String _requiredString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is String) return value;
    throw FormatException('Contact field $key must be a string');
  }

  static String? _optionalString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null) return null;
    if (value is String) return value;
    throw FormatException('Contact field $key must be a string or null');
  }
}
