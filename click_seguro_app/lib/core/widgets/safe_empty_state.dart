import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:click_seguro_app/core/theme/app_colors.dart';
import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:click_seguro_app/core/widgets/safe_button.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Estado vazio (FR-015): ícone, mensagem (padrão "Nada por aqui ainda.") e
/// uma ação opcional. Textos já traduzidos.
class SafeEmptyState extends StatelessWidget {
  const SafeEmptyState({
    super.key,
    this.icon = LucideIcons.inbox,
    this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final String? label = actionLabel;
    final VoidCallback? action = onAction;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: AppColors.textMutedForeground),
            const SizedBox(height: AppSpacing.s3),
            Text(
              message ?? AppStrings.commonEmpty.tr(),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontSize: 16,
                color: AppColors.textMutedForeground,
              ),
            ),
            if (label != null && action != null) ...[
              const SizedBox(height: AppSpacing.s5),
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                child: SafeButton(
                  label: label,
                  size: SafeButtonSize.compact,
                  onPressed: action,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
