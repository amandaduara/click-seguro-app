import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Como o app cuida dos dados (FR-022): o que fica no serviço e o que fica
/// só no celular (RN-007, RNF-008).
class PrivacyPage extends StatelessWidget {
  const PrivacyPage({super.key});

  static const List<(String, String)> _sections = [
    (
      AppStrings.settingsPrivacyAccountTitle,
      AppStrings.settingsPrivacyAccountBody,
    ),
    (
      AppStrings.settingsPrivacyDeviceTitle,
      AppStrings.settingsPrivacyDeviceBody,
    ),
    (AppStrings.settingsPrivacyUseTitle, AppStrings.settingsPrivacyUseBody),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.settingsPrivacy.tr())),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.s5),
          children: [
            for (final (title, body) in _sections)
              _Paragraph(title: title.tr(), body: body.tr()),
          ],
        ),
      ),
    );
  }
}

/// Título de seção e o texto dela.
class _Paragraph extends StatelessWidget {
  const _Paragraph({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(
              title,
              style: textTheme.titleMedium?.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: context.colors.secondary,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.s2),
          Text(
            body,
            style: textTheme.bodyLarge?.copyWith(
              fontSize: 16,
              height: 1.5,
              color: context.colors.textForeground,
            ),
          ),
        ],
      ),
    );
  }
}
