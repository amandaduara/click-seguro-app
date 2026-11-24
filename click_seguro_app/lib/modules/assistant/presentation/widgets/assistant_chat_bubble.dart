import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:click_seguro_app/core/theme/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Canto "da ponta" do balão: o lado de quem fala fica menos arredondado.
const Radius _round = Radius.circular(20);
const Radius _tip = Radius.circular(6);

/// Avatar redondo em coral suave com o brilho (quadro "10 Assistente" do
/// redesign 2.0).
class AssistantAvatar extends StatelessWidget {
  const AssistantAvatar({super.key, this.size = 40});

  final double size;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: context.colors.primarySoft,
        shape: BoxShape.circle,
      ),
      child: Icon(
        LucideIcons.sparkles,
        size: size * 0.5,
        color: context.colors.primary,
      ),
    ),
  );
}

/// Fundo do balão do assistente: creme à esquerda, com a ponta embaixo à
/// esquerda. No alto contraste (sem sombra), ganha borda.
BoxDecoration assistantBubbleDecoration(AppPalette colors) => BoxDecoration(
  color: colors.surface,
  border: colors.shadow.isEmpty ? Border.all(color: colors.border) : null,
  borderRadius: const BorderRadius.only(
    topLeft: _round,
    topRight: _round,
    bottomLeft: _tip,
    bottomRight: _round,
  ),
);

/// Balão da conversa (redesign 2.0): o da pessoa em tinta com texto branco, à
/// direita; o do assistente em creme, à esquerda, com o avatar de brilho.
///
/// [footer] fica logo abaixo do balão do assistente, alinhado ao início dele
/// (o "Ouvir" da mensagem, specs/025); vem depois do texto na ordem de
/// leitura do leitor de tela. Ignorado no balão da pessoa.
class AssistantChatBubble extends StatelessWidget {
  const AssistantChatBubble({
    super.key,
    required this.text,
    required this.fromUser,
    this.footer,
  });

  final String text;
  final bool fromUser;
  final Widget? footer;

  static const double _avatarSize = 40;

  static const EdgeInsets _padding = EdgeInsets.symmetric(
    horizontal: AppSpacing.s4,
    vertical: 14,
  );

  @override
  Widget build(BuildContext context) {
    final AppPalette colors = context.colors;
    final double maxWidth = MediaQuery.sizeOf(context).width * 0.84;
    if (fromUser) {
      return Align(
        alignment: AlignmentDirectional.centerEnd,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: DecoratedBox(
            key: const ValueKey('assistant-bubble-user'),
            decoration: BoxDecoration(
              color: colors.secondary,
              borderRadius: const BorderRadius.only(
                topLeft: _round,
                topRight: _round,
                bottomLeft: _round,
                bottomRight: _tip,
              ),
            ),
            child: Padding(
              padding: _padding,
              child: SelectableText(
                text,
                style: AppTypography.bodyLarge.copyWith(
                  color: colors.textPrimaryForeground,
                ),
              ),
            ),
          ),
        ),
      );
    }
    final Widget bubble = Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const AssistantAvatar(size: _avatarSize),
        const SizedBox(width: AppSpacing.s3),
        Flexible(
          child: DecoratedBox(
            key: const ValueKey('assistant-bubble-assistant'),
            decoration: assistantBubbleDecoration(colors),
            child: Padding(
              padding: _padding,
              child: SelectableText(
                text,
                style: AppTypography.bodyLarge.copyWith(
                  color: colors.textForeground,
                ),
              ),
            ),
          ),
        ),
      ],
    );
    final Widget? below = footer;
    if (below == null) return bubble;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        bubble,
        const SizedBox(height: AppSpacing.s2),
        Padding(
          padding: const EdgeInsetsDirectional.only(
            start: _avatarSize + AppSpacing.s3,
          ),
          child: below,
        ),
      ],
    );
  }
}
