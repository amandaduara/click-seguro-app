import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:click_seguro_app/modules/profile/domain/entities/achievement_entity.dart';
import 'package:click_seguro_app/modules/profile/presentation/extensions/achievement_presentation_extension.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Cartão de uma conquista: medalha colorida e "Conquistada", ou cinza com
/// cadeado e o progresso ("8 de 10 lições").
class MedalCard extends StatelessWidget {
  const MedalCard({super.key, required this.achievement, this.width});

  /// Largura na faixa horizontal do perfil.
  static const double stripWidth = 124;

  final AchievementEntity achievement;

  /// Nula: ocupa a largura disponível (grade de "Ver todas").
  final double? width;

  @override
  Widget build(BuildContext context) {
    final AppPalette colors = context.colors;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final bool achieved = achievement.achieved;
    return MergeSemantics(
      child: Container(
        width: width,
        padding: const EdgeInsets.all(AppSpacing.s3),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: AppSpacing.radius2xl,
          border: Border.all(color: colors.border),
        ),
        child: Column(
          children: [
            _Medal(achievement: achievement),
            const SizedBox(height: AppSpacing.s2),
            Text(
              achievement.title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodyMedium?.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: colors.secondary,
              ),
            ),
            const SizedBox(height: AppSpacing.s1),
            Text(
              achieved
                  ? AppStrings.profileAchievementDone.tr()
                  : achievement.progressLabel,
              textAlign: TextAlign.center,
              style: textTheme.bodySmall?.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: achieved ? colors.success : colors.textMutedForeground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Disco com aro branco e fita por baixo.
class _Medal extends StatelessWidget {
  const _Medal({required this.achievement});

  static const double _disc = 64;
  static const double _ribbon = 18;

  final AchievementEntity achievement;

  @override
  Widget build(BuildContext context) {
    final AppPalette colors = context.colors;
    final bool achieved = achievement.achieved;
    final (Color start, Color end) = achieved
        ? achievement.medalColors(colors)
        : (colors.textMutedForeground, colors.border);
    return ExcludeSemantics(
      child: SizedBox(
        width: _disc,
        height: _disc + _ribbon,
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            Positioned(
              bottom: 0,
              child: CustomPaint(
                size: const Size(_disc * 0.6, _ribbon * 1.6),
                painter: _RibbonPainter(color: start),
              ),
            ),
            Container(
              width: _disc,
              height: _disc,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [end, start],
                ),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.55),
                  width: 3,
                ),
              ),
              child: Icon(
                achieved ? achievement.icon : LucideIcons.lock,
                size: 26,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Duas pontas de fita em "V", saindo de trás do disco.
class _RibbonPainter extends CustomPainter {
  const _RibbonPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..color = color;
    final double w = size.width;
    final double h = size.height;
    final double tail = w * 0.42;
    canvas
      ..drawPath(
        Path()
          ..moveTo(0, 0)
          ..lineTo(tail, 0)
          ..lineTo(tail, h)
          ..lineTo(tail / 2, h * 0.8)
          ..lineTo(0, h)
          ..close(),
        paint,
      )
      ..drawPath(
        Path()
          ..moveTo(w - tail, 0)
          ..lineTo(w, 0)
          ..lineTo(w, h)
          ..lineTo(w - tail / 2, h * 0.8)
          ..lineTo(w - tail, h)
          ..close(),
        paint,
      );
  }

  @override
  bool shouldRepaint(_RibbonPainter oldDelegate) => oldDelegate.color != color;
}
