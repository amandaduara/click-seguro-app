/// O que mudou na edição (FR-013): campos nulos não são enviados.
class ProfileUpdate {
  const ProfileUpdate({this.name, this.email, this.phone});

  final String? name;
  final String? email;
  final String? phone;

  bool get isEmpty => name == null && email == null && phone == null;
}
