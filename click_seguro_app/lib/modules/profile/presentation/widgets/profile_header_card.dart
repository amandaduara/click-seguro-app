import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:click_seguro_app/modules/profile/domain/entities/profile_entity.dart';
import 'package:click_seguro_app/modules/profile/presentation/widgets/profile_avatar.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Cartão da pessoa (quadro "Perfil — com conta (v4)"): a foto (ou
/// iniciais) fica sobre a borda de cima do cartão, com o lápis de editar;
/// dentro, o nome e o [footer] (os números). O e-mail não aparece.
class ProfileHeaderCard extends StatelessWidget {
  const ProfileHeaderCard({
    super.key,
    required this.profile,
    required this.onEdit,
    required this.footer,
  });

  static const double _avatarSize = 96;
  static const double _ringWidth = 4;
  static const double _pencilSize = 36;
  static const double _touchSize = 48;

  /// Espaço em volta da foto para a área de toque do lápis.
  static const double _inset = 8;

  /// Quanto da foto (com o aro) fica acima do cartão: a metade.
  static const double _overlap = _avatarSize / 2 + _ringWidth + _inset;

  final ProfileEntity profile;
  final VoidCallback onEdit;
  final Widget footer;

  @override
  Widget build(BuildContext context) {
    final AppPalette colors = context.colors;
    const double photoBox = _avatarSize + 2 * (_ringWidth + _inset);
    // A foto fica dentro do Stack (e não com overflow), para o toque no
    // lápis funcionar também na parte de fora do cartão.
    return Stack(
      children: [
        Container(
          margin: const EdgeInsets.only(top: _overlap),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.s4,
            photoBox - _overlap + AppSpacing.s2,
            AppSpacing.s4,
            AppSpacing.s4,
          ),
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: AppSpacing.radius3xl,
            border: Border.all(color: colors.border),
            boxShadow: colors.shadowSm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
              const SizedBox(height: AppSpacing.s4),
              footer,
            ],
          ),
        ),
        Align(
          alignment: Alignment.topCenter,
          child: SizedBox.square(
            dimension: photoBox,
            child: Stack(
              children: [
                Positioned(
                  left: _inset,
                  top: _inset,
                  child: Container(
                    padding: const EdgeInsets.all(_ringWidth),
                    decoration: BoxDecoration(
                      color: colors.card,
                      shape: BoxShape.circle,
                      boxShadow: colors.shadowSm,
                    ),
                    child: ProfileAvatar(
                      initials: profile.initials,
                      imageUrl: profile.avatarUrl,
                      size: _avatarSize,
                    ),
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
        ),
      ],
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
