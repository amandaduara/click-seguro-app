import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:click_seguro_app/core/theme/app_typography.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Aceite do cadastro (specs/026 FR-005 a FR-010): "Li e aceito os Termos de
/// uso e a Política de privacidade." Tocar no quadrado ou no texto marca;
/// os dois nomes são links para os documentos. Marcado, o cartão fica coral
/// claro com borda coral.
class TermsAcceptance extends StatefulWidget {
  const TermsAcceptance({
    super.key,
    required this.accepted,
    required this.onChanged,
    required this.onOpenTerms,
    required this.onOpenPrivacy,
  });

  final bool accepted;
  final ValueChanged<bool> onChanged;
  final VoidCallback onOpenTerms;
  final VoidCallback onOpenPrivacy;

  @override
  State<TermsAcceptance> createState() => _TermsAcceptanceState();
}

class _TermsAcceptanceState extends State<TermsAcceptance> {
  late final TapGestureRecognizer _terms = TapGestureRecognizer()
    ..onTap = () => widget.onOpenTerms();
  late final TapGestureRecognizer _privacy = TapGestureRecognizer()
    ..onTap = () => widget.onOpenPrivacy();

  @override
  void dispose() {
    _terms.dispose();
    _privacy.dispose();
    super.dispose();
  }

  void _toggle() => widget.onChanged(!widget.accepted);

  @override
  Widget build(BuildContext context) {
    final AppPalette colors = context.colors;
    final bool accepted = widget.accepted;
    final String prefix = AppStrings.authTermsPrefix.tr();
    final String terms = AppStrings.authTermsLink.tr();
    final String and = AppStrings.authTermsAnd.tr();
    final String privacy = AppStrings.authPrivacyLink.tr();
    final TextStyle linkStyle = TextStyle(
      fontWeight: FontWeight.w700,
      color: colors.primaryPressed,
      decoration: TextDecoration.underline,
      decorationColor: colors.primaryPressed,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: accepted ? colors.primarySoft : colors.card,
        borderRadius: AppSpacing.radiusMd,
        border: Border.all(
          color: accepted ? colors.primary : colors.border,
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.s1,
          AppSpacing.s1,
          AppSpacing.s4,
          AppSpacing.s1,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TermsCheckbox(
              value: accepted,
              label: '$prefix $terms $and $privacy.',
              onChanged: widget.onChanged,
            ),
            const SizedBox(width: AppSpacing.s1),
            Expanded(
              child: Padding(
                // Centra a 1ª linha com o quadrado (área de 48).
                padding: const EdgeInsets.symmetric(vertical: 13),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _toggle,
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: '$prefix '),
                        TextSpan(
                          text: terms,
                          style: linkStyle,
                          recognizer: _terms,
                        ),
                        TextSpan(text: ' $and '),
                        TextSpan(
                          text: privacy,
                          style: linkStyle,
                          recognizer: _privacy,
                        ),
                        const TextSpan(text: '.'),
                      ],
                    ),
                    style: AppTypography.label.copyWith(
                      fontWeight: FontWeight.w400,
                      height: 1.45,
                      color: colors.textForeground,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// O quadrado do aceite: 28 com canto 8, numa área de toque de 48. Para o
/// leitor de tela, é a caixa de seleção com o texto completo ([label]).
class TermsCheckbox extends StatelessWidget {
  const TermsCheckbox({
    super.key,
    required this.value,
    required this.label,
    required this.onChanged,
  });

  final bool value;
  final String label;
  final ValueChanged<bool> onChanged;

  static const double _box = 28;
  static const double _touch = 48;
  static const BorderRadius _radius = BorderRadius.all(Radius.circular(8));

  @override
  Widget build(BuildContext context) {
    final AppPalette colors = context.colors;
    return Semantics(
      container: true,
      checked: value,
      enabled: true,
      label: label,
      child: InkResponse(
        onTap: () => onChanged(!value),
        radius: _touch / 2,
        child: SizedBox.square(
          dimension: _touch,
          child: Center(
            child: Container(
              width: _box,
              height: _box,
              decoration: BoxDecoration(
                color: value ? colors.primary : colors.card,
                borderRadius: _radius,
                border: value
                    ? null
                    : Border.all(color: colors.inputBorder, width: 2),
              ),
              child: value
                  ? Icon(
                      LucideIcons.check,
                      size: 18,
                      color: colors.textPrimaryForeground,
                    )
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}
