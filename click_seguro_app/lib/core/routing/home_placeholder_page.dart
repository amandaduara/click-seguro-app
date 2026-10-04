import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:click_seguro_app/core/theme/app_colors.dart';
import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:click_seguro_app/modules/common/services/user_session_service.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

// TODO(F0.9): substituir pelo shell com as abas.
/// Destino provisório depois de entrar (feature 003).
class HomePlaceholderPage extends StatelessWidget {
  const HomePlaceholderPage({super.key});

  @override
  Widget build(BuildContext context) {
    final session = GetIt.instance<UserSessionService>();
    final name = session.userName;
    final title = session.isAuthenticated && name != null && name.isNotEmpty
        ? AppStrings.homePlaceholderGreeting.tr(args: [name])
        : AppStrings.homePlaceholderWelcome.tr();
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: textTheme.headlineSmall?.copyWith(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.s2),
              Text(
                AppStrings.homePlaceholderBody.tr(),
                style: textTheme.bodyLarge?.copyWith(
                  color: AppColors.textMutedForeground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
