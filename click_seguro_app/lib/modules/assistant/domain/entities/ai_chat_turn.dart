enum AiChatRole { user, model }

class AiChatTurn {
  const AiChatTurn({required this.role, required this.content});

  final AiChatRole role;
  final String content;

  Map<String, Object> toJson() => {'role': role.name, 'content': content};
}
