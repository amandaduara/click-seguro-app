import 'package:click_seguro_app/modules/help/domain/entities/contact_entity.dart';

class ContactModel {
  const ContactModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.type,
    this.relationship,
    this.photoPath,
    this.description,
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
      description: _optionalString(json, 'description'),
    );
  }

  /// Contato oficial de `GET /app/official-contacts` (ou da cópia local e do
  /// asset, no mesmo formato). A categoria da API (`POLICIA`, `BANCO`...)
  /// não é usada pela tela: todo contato daqui é [ContactType.official].
  /// Sem `id`, `name` ou `phone` (não dá para ligar) lança
  /// [FormatException]; descrição ausente ou inválida fica nula.
  factory ContactModel.fromOfficialJson(Map<String, dynamic> json) {
    final description = json['description'];
    return ContactModel(
      id: _requiredText(json, 'id'),
      name: _requiredText(json, 'name'),
      phone: _requiredText(json, 'phone'),
      type: ContactType.official,
      description: description is String && description.trim().isNotEmpty
          ? description.trim()
          : null,
    );
  }

  /// Contatos oficiais válidos de [items], na mesma ordem; item inválido é
  /// ignorado.
  static List<ContactModel> officialList(List<Object?> items) => [
    for (final item in items) ?_tryOfficial(item),
  ];

  static ContactModel? _tryOfficial(Object? item) {
    if (item is! Map<String, dynamic>) return null;
    try {
      return ContactModel.fromOfficialJson(item);
    } on FormatException {
      return null;
    }
  }

  factory ContactModel.fromEntity(ContactEntity entity) => ContactModel(
    id: entity.id,
    name: entity.name,
    phone: entity.phone,
    type: entity.type,
    relationship: entity.relationship,
    photoPath: entity.photoPath,
    description: entity.description,
  );

  final String id;
  final String name;
  final String phone;
  final ContactType type;
  final String? relationship;
  final String? photoPath;
  final String? description;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'phone': phone,
    'type': type.name,
    if (relationship != null) 'relationship': relationship,
    if (photoPath != null) 'photoPath': photoPath,
    if (description != null) 'description': description,
  };

  ContactEntity toEntity() => ContactEntity(
    id: id,
    name: name,
    phone: phone,
    type: type,
    relationship: relationship,
    photoPath: photoPath,
    description: description,
  );

  static String _requiredString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is String) return value;
    throw FormatException('Contact field $key must be a string');
  }

  static String _requiredText(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is String && value.trim().isNotEmpty) return value.trim();
    throw FormatException('Official contact field $key must be a text');
  }

  static String? _optionalString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null) return null;
    if (value is String) return value;
    throw FormatException('Contact field $key must be a string or null');
  }
}
