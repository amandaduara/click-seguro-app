import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:click_seguro_app/core/theme/app_typography.dart';
import 'package:click_seguro_app/core/widgets/safe_card.dart';
import 'package:click_seguro_app/modules/settings/presentation/widgets/settings_tile.dart';
import 'package:flutter/material.dart';

/// Um assunto das telas de texto das Configurações (Privacidade, Termos de
/// uso): ícone no círculo suave, título e o texto, num cartão padrão. [child]
/// vem abaixo do texto (ex.: um link).
class SettingsTopicCard extends StatelessWidget {
  const SettingsTopicCard({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    this.child,
  });

  final IconData icon;
  final String title;
  final String body;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final AppPalette colors = context.colors;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final Widget? child = this.child;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.s5),
      child: SafeCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SettingsIconCircle(icon: icon, color: colors.secondary),
                const SizedBox(width: AppSpacing.s3),
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      title,
                      style: textTheme.titleMedium?.copyWith(
                        fontSize: AppTypography.title3.fontSize,
                        fontWeight: FontWeight.w800,
                        color: colors.secondary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s3),
            Text(
              body,
              style: textTheme.bodyLarge?.copyWith(
                fontSize: AppTypography.body.fontSize,
                height: 1.5,
                color: colors.textBody,
              ),
            ),
            ?child,
          ],
        ),
      ),
    );
  }
}
