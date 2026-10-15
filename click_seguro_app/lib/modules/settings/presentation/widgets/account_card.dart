import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Cartão da conta no topo das Configurações: foto (ou iniciais), nome e
/// "Ver e editar seu perfil".
class AccountCard extends StatelessWidget {
  const AccountCard({
    super.key,
    required this.name,
    required this.initials,
    required this.onTap,
    this.avatarUrl,
  });

  static const double _avatarSize = 56;

  final String name;
  final String initials;
  final String? avatarUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppPalette colors = context.colors;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final String? url = avatarUrl;
    final Widget fallback = ColoredBox(
      color: colors.input,
      child: Center(
        child: Text(
          initials,
          textScaler: TextScaler.noScaling,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: colors.secondary,
          ),
        ),
      ),
    );
    return MergeSemantics(
      child: Semantics(
        button: true,
        child: Material(
          color: colors.card,
          shape: RoundedRectangleBorder(
            borderRadius: AppSpacing.radius2xl,
            side: BorderSide(color: colors.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.s4),
              child: Row(
                children: [
                  ExcludeSemantics(
                    child: ClipOval(
                      child: SizedBox.square(
                        dimension: _avatarSize,
                        child: url == null
                            ? fallback
                            : Image.network(
                                url,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => fallback,
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.titleMedium?.copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: colors.secondary,
                          ),
                        ),
                        Text(
                          AppStrings.settingsAccountCardAction.tr(),
                          style: textTheme.bodyMedium?.copyWith(
                            fontSize: 14,
                            color: colors.textMutedForeground,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s2),
                  ExcludeSemantics(
                    child: Icon(
                      LucideIcons.chevronRight,
                      size: 20,
                      color: colors.textMutedForeground,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
