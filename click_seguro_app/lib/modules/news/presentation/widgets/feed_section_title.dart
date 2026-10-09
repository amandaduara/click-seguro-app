import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';

/// Título de seção do feed ("Novidades", "Destaques"…), 18/700 secondary.
class FeedSectionTitle extends StatelessWidget {
  const FeedSectionTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s5,
        AppSpacing.s6,
        AppSpacing.s5,
        AppSpacing.s3,
      ),
      child: Semantics(
        header: true,
        child: Text(
          text,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: context.colors.secondary,
          ),
        ),
      ),
    );
  }
}
