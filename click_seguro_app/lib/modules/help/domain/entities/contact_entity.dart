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
}
