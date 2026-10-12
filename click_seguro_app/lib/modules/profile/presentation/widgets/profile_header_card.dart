import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:click_seguro_app/modules/profile/domain/entities/profile_entity.dart';
import 'package:click_seguro_app/modules/profile/presentation/widgets/profile_avatar.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Cartão da pessoa: foto (ou iniciais) com o lápis de editar e o nome. O
/// e-mail não aparece (quadro "Perfil — com conta (v4)").
class ProfileHeaderCard extends StatelessWidget {
  const ProfileHeaderCard({
    super.key,
    required this.profile,
    required this.onEdit,
  });

  static const double _avatarSize = 96;
  static const double _pencilSize = 36;
  static const double _touchSize = 48;

  /// Espaço em volta da foto para a área de toque do lápis.
  static const double _inset = 8;

  final ProfileEntity profile;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final AppPalette colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s6),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: AppSpacing.radius3xl,
        border: Border.all(color: colors.border),
        boxShadow: colors.shadowSm,
      ),
      child: Column(
        children: [
          SizedBox.square(
            dimension: _avatarSize + 2 * _inset,
            child: Stack(
              children: [
                Positioned(
                  left: _inset,
                  top: _inset,
                  child: ProfileAvatar(
                    initials: profile.initials,
                    imageUrl: profile.avatarUrl,
                    size: _avatarSize,
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: _EditButton(onPressed: onEdit),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.s3),
          Text(
            profile.name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: colors.secondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _EditButton extends StatelessWidget {
  const _EditButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final AppPalette colors = context.colors;
    // Nó próprio: sem o container, o rótulo se junta ao nome da pessoa.
    return Semantics(
      container: true,
      button: true,
      label: AppStrings.profileEditPhotoLabel.tr(),
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: SizedBox.square(
          dimension: ProfileHeaderCard._touchSize,
          child: Center(
            child: Container(
              width: ProfileHeaderCard._pencilSize,
              height: ProfileHeaderCard._pencilSize,
              decoration: BoxDecoration(
                color: colors.primary,
                shape: BoxShape.circle,
                border: Border.all(color: colors.card, width: 3),
              ),
              child: Icon(
                LucideIcons.pencil,
                size: 16,
                color: colors.textPrimaryForeground,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
