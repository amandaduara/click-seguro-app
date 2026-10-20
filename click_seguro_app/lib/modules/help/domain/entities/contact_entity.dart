enum ContactType { official, personal }

class ContactEntity {
  const ContactEntity({
    required this.id,
    required this.name,
    required this.phone,
    required this.type,
    this.relationship,
    this.photoPath,
  });

  final String id;
  final String name;
  final String phone;
  final ContactType type;
  final String? relationship;
  final String? photoPath;

  @override
  bool operator ==(Object other) =>
      other is ContactEntity &&
      id == other.id &&
      name == other.name &&
      phone == other.phone &&
      type == other.type &&
      relationship == other.relationship &&
      photoPath == other.photoPath;

  @override
  int get hashCode =>
      Object.hash(id, name, phone, type, relationship, photoPath);
}
