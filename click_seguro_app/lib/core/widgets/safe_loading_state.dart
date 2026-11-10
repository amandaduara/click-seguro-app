import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:click_seguro_app/core/theme/app_typography.dart';
import 'package:click_seguro_app/core/widgets/safe_skeleton.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Formato dos blocos de carregamento: como o conteúdo que vai chegar.
enum SafeLoadingLayout { cards, list, detail }

/// Estado de carregando (FR-015, FR-018). Redesign 2.0: blocos com brilho
/// no formato do conteúdo, no lugar do círculo girando. O leitor de tela
/// ouve "Carregando" como antes; os blocos são decorativos.
class SafeLoadingState extends StatelessWidget {
  const SafeLoadingState({
    super.key,
    this.message,
    this.layout = SafeLoadingLayout.cards,
  });

  final String? message;
  final SafeLoadingLayout layout;

  static const BorderRadius _block = BorderRadius.all(Radius.circular(16));

  @override
  Widget build(BuildContext context) {
    final String? text = message;
    return Semantics(
      liveRegion: true,
      label: AppStrings.commonLoading.tr(),
      child: ClipRect(
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.s5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (text != null) ...[
                Text(
                  text,
                  textAlign: TextAlign.center,
                  style: AppTypography.body.copyWith(
                    color: context.colors.textMutedForeground,
                  ),
                ),
                const SizedBox(height: AppSpacing.s4),
              ],
              ...switch (layout) {
                SafeLoadingLayout.cards => _cards(),
                SafeLoadingLayout.list => _list(),
                SafeLoadingLayout.detail => _detail(),
              },
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _cards() => [
    for (int i = 0; i < 2; i++) ...[
      const SafeSkeleton(height: 150, radius: _block),
      const SizedBox(height: AppSpacing.s3),
      const FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: 0.65,
        child: SafeSkeleton(height: 20),
      ),
      const SizedBox(height: AppSpacing.s2),
      const FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: 0.4,
        child: SafeSkeleton(height: 16),
      ),
      const SizedBox(height: AppSpacing.s6),
    ],
  ];

  List<Widget> _list() => [
    for (int i = 0; i < 5; i++)
      const Padding(
        padding: EdgeInsets.only(bottom: AppSpacing.s4),
        child: Row(
          children: [
            SafeSkeleton(width: 56, height: 56, radius: _block),
            SizedBox(width: AppSpacing.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SafeSkeleton(height: 18),
                  SizedBox(height: AppSpacing.s2),
                  FractionallySizedBox(
                    widthFactor: 0.6,
                    child: SafeSkeleton(height: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
  ];

  List<Widget> _detail() => [
    const SafeSkeleton(height: 220, radius: _block),
    const SizedBox(height: AppSpacing.s5),
    const SafeSkeleton(height: 28),
    const SizedBox(height: AppSpacing.s3),
    const FractionallySizedBox(
      alignment: Alignment.centerLeft,
      widthFactor: 0.7,
      child: SafeSkeleton(height: 28),
    ),
    const SizedBox(height: AppSpacing.s5),
    for (int i = 0; i < 4; i++) ...[
      const SafeSkeleton(height: 16),
      const SizedBox(height: AppSpacing.s2),
    ],
  ];
}
