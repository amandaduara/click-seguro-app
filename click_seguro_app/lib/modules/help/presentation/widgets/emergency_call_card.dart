import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:click_seguro_app/core/theme/app_typography.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Número da polícia no cartão de emergência (serviço brasileiro, igual em
/// qualquer idioma do app).
abstract final class EmergencyNumbers {
  static const String police = '190';
}

/// "Caiu em um golpe?" no topo da Central de ajuda (FR-016 de
/// specs/022-redesign-visual): cartão coral com o botão branco
/// "Ligar para 190".
class EmergencyCallCard extends StatelessWidget {
  const EmergencyCallCard({super.key, required this.onCall});

  final VoidCallback onCall;

  @override
  Widget build(BuildContext context) {
    final AppPalette colors = context.colors;
    final Color onCoral = colors.textPrimaryForeground;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s5),
      decoration: BoxDecoration(
        color: colors.primary,
        borderRadius: AppSpacing.radiusXl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              ExcludeSemantics(
                child: Icon(
                  LucideIcons.triangleAlert,
                  size: 28,
                  color: onCoral,
                ),
              ),
              const SizedBox(width: AppSpacing.s3),
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    AppStrings.helpEmergencyTitle.tr(),
                    style: AppTypography.title2.copyWith(color: onCoral),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s2),
          Text(
            AppStrings.helpEmergencyBody.tr(),
            style: AppTypography.body.copyWith(
              fontSize: 17,
              height: 1.45,
              color: onCoral,
            ),
          ),
          const SizedBox(height: AppSpacing.s4),
          Semantics(
            button: true,
            label: AppStrings.helpEmergencyCall.tr(),
            excludeSemantics: true,
            child: Material(
              color: colors.card,
              borderRadius: AppSpacing.radiusMd,
              child: InkWell(
                borderRadius: AppSpacing.radiusMd,
                onTap: onCall,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 56),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.s4,
                      vertical: AppSpacing.s3,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          LucideIcons.phone,
                          size: 22,
                          color: colors.primary,
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            AppStrings.helpEmergencyCall.tr(),
                            textAlign: TextAlign.center,
                            style: AppTypography.button.copyWith(
                              color: colors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
