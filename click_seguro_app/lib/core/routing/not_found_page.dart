import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:click_seguro_app/core/widgets/safe_button.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Caminho desconhecido (FR-007): avisa e oferece voltar ao Início.
class NotFoundPage extends StatelessWidget {
  const NotFoundPage({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.s6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  LucideIcons.searchX,
                  size: 40,
                  color: context.colors.textMutedForeground,
                ),
                const SizedBox(height: AppSpacing.s4),
                Semantics(
                  header: true,
                  child: Text(
                    AppStrings.commonNotFoundTitle.tr(),
                    textAlign: TextAlign.center,
                    style: textTheme.titleMedium?.copyWith(
                      color: context.colors.secondary,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.s6),
                ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 48),
                  child: SafeButton(
                    label: AppStrings.commonBackHome.tr(),
                    size: SafeButtonSize.compact,
                    onPressed: () => context.go('/home'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
