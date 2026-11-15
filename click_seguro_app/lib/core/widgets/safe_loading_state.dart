import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:click_seguro_app/core/widgets/safe_skeleton.dart';
import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

/// Formato dos blocos de carregamento: como o conteúdo que vai chegar.
enum SafeLoadingLayout { cards, list, detail }

/// Estado de carregando (FR-015, FR-018). Redesign 2.0: blocos com brilho
/// no formato do conteúdo, no lugar do círculo girando, para as telas sem
/// dados de exemplo próprios. O [SafeSkeleton] anuncia "Carregando" e para o
/// brilho com o movimento reduzido.
class SafeLoadingState extends StatelessWidget {
  const SafeLoadingState({super.key, this.layout = SafeLoadingLayout.cards});

  final SafeLoadingLayout layout;

  static final BorderRadius _block = AppSpacing.radiusMd;
  static final BorderRadius _line = AppSpacing.radiusSm;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.s5),
        child: SafeSkeleton(
          enabled: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: switch (layout) {
              SafeLoadingLayout.cards => _cards(),
              SafeLoadingLayout.list => _list(),
              SafeLoadingLayout.detail => _detail(),
            },
          ),
        ),
      ),
    );
  }

  List<Widget> _cards() => [
    for (int i = 0; i < 2; i++) ...[
      Bone(height: 150, borderRadius: _block),
      const SizedBox(height: AppSpacing.s3),
      FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: 0.65,
        child: Bone(height: 20, borderRadius: _line),
      ),
      const SizedBox(height: AppSpacing.s2),
      FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: 0.4,
        child: Bone(height: 16, borderRadius: _line),
      ),
      const SizedBox(height: AppSpacing.s6),
    ],
  ];

  List<Widget> _list() => [
    for (int i = 0; i < 5; i++)
      Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.s4),
        child: Row(
          children: [
            Bone(width: 56, height: 56, borderRadius: _block),
            const SizedBox(width: AppSpacing.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Bone(height: 18, borderRadius: _line),
                  const SizedBox(height: AppSpacing.s2),
                  FractionallySizedBox(
                    widthFactor: 0.6,
                    child: Bone(height: 14, borderRadius: _line),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
  ];

  List<Widget> _detail() => [
    Bone(height: 220, borderRadius: _block),
    const SizedBox(height: AppSpacing.s5),
    Bone(height: 28, borderRadius: _line),
    const SizedBox(height: AppSpacing.s3),
    FractionallySizedBox(
      alignment: Alignment.centerLeft,
      widthFactor: 0.7,
      child: Bone(height: 28, borderRadius: _line),
    ),
    const SizedBox(height: AppSpacing.s5),
    for (int i = 0; i < 4; i++) ...[
      Bone(height: 16, borderRadius: _line),
      const SizedBox(height: AppSpacing.s2),
    ],
  ];
}
