import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:click_seguro_app/core/theme/app_typography.dart';
import 'package:flutter/material.dart';

/// Título de seção do feed ("Novidades", "Destaques"…), título 2 do
/// redesign 2.0.
///
/// [trailing] fica ao lado do título (o "Ouvir" dos destaques, Figma quadro
/// 04); sem espaço, como com letra grande, desce para logo abaixo dele.
class FeedSectionTitle extends StatelessWidget {
  const FeedSectionTitle(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final Widget title = Semantics(
      header: true,
      child: Text(
        text,
        style: AppTypography.title2.copyWith(
          color: context.colors.textForeground,
        ),
      ),
    );
    final Widget? trailing = this.trailing;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s5,
        AppSpacing.s6,
        AppSpacing.s5,
        AppSpacing.s3,
      ),
      child: trailing == null
          ? title
          : SizedBox(
              width: double.infinity,
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: AppSpacing.s3,
                runSpacing: AppSpacing.s2,
                children: [title, trailing],
              ),
            ),
    );
  }
}
