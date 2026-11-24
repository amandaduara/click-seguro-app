import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:click_seguro_app/core/theme/app_typography.dart';
import 'package:click_seguro_app/core/widgets/safe_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Cabeçalho das telas internas no redesign 2.0 (o padrão das
/// Configurações): o botão redondo de voltar e, na mesma linha, logo ao lado,
/// o título grande. Com letra grande o título quebra linha em vez de
/// estourar. [actions] ficam à direita, depois do título.
///
/// O voltar usa o `maybePop`, para os avisos de `PopScope` (descartar
/// alterações, passo anterior) continuarem valendo; sem nada atrás, leva a
/// [fallbackLocation]. Sem [fallbackLocation] nem [onBack], o botão só
/// aparece quando há para onde voltar, como na barra do Material.
class SafePageHeader extends StatelessWidget {
  const SafePageHeader({
    super.key,
    required this.title,
    this.fallbackLocation,
    this.onBack,
    this.backEnabled = true,
    this.backHint,
    this.backLabel,
    this.actions = const [],
  });

  /// Chave padrão do botão de voltar, para os testes o acharem.
  static const Key defaultBackKey = ValueKey('safe-page-back');

  final String title;

  /// Para onde o voltar leva quando a tela foi aberta por link direto, sem
  /// nada atrás dela.
  final String? fallbackLocation;

  /// Troca o `maybePop` por outra ação. Com [backEnabled] falso, é o que o
  /// toque no botão desativado faz (ex.: mostrar um aviso).
  final VoidCallback? onBack;

  /// Falso: o voltar aparece desativado (ex.: durante um envio).
  final bool backEnabled;

  /// Dica lida pelo leitor de tela com o voltar desativado.
  final String? backHint;

  /// Rótulo do voltar; o padrão é o do Material ("Voltar").
  final String? backLabel;

  /// Botões à direita do título (ex.: [SafeIconButton]).
  final List<Widget> actions;

  bool _showBack(BuildContext context) =>
      onBack != null ||
      fallbackLocation != null ||
      (ModalRoute.of(context)?.impliesAppBarDismissal ?? false);

  @override
  Widget build(BuildContext context) {
    final bool showBack = _showBack(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s5,
        AppSpacing.s3,
        AppSpacing.s5,
        0,
      ),
      child: Row(
        children: [
          if (showBack) ...[
            _SafeBackButton(
              key: defaultBackKey,
              fallbackLocation: fallbackLocation,
              onBack: onBack,
              enabled: backEnabled,
              hint: backHint,
              label: backLabel,
            ),
            const SizedBox(width: AppSpacing.s4),
          ],
          Expanded(child: _PageTitle(title)),
          for (final Widget action in actions) ...[
            const SizedBox(width: AppSpacing.s2),
            action,
          ],
        ],
      ),
    );
  }
}

/// Quadro de uma tela interna: [header] no topo, [body] ocupando o resto e
/// [bottom] (ex.: o botão principal) fixo no fim da tela, acima da área
/// segura e do teclado.
class SafePageScaffold extends StatelessWidget {
  const SafePageScaffold({
    super.key,
    required this.header,
    required this.body,
    this.bottom,
  });

  final SafePageHeader header;
  final Widget body;

  /// Fixo embaixo, fora da rolagem.
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            header,
            Expanded(child: body),
            if (bottom case final Widget bottom)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.s5,
                  AppSpacing.s3,
                  AppSpacing.s5,
                  AppSpacing.s4,
                ),
                child: bottom,
              ),
          ],
        ),
      ),
    );
  }
}

/// Título grande da tela, no estilo do "Perfil", ao lado do voltar.
class _PageTitle extends StatelessWidget {
  const _PageTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Text(
        title,
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
          fontSize: AppTypography.display.fontSize,
          fontWeight: FontWeight.w800,
          height: 1.2,
          color: context.colors.secondary,
        ),
      ),
    );
  }
}

/// Botão redondo de voltar do [SafePageHeader].
class _SafeBackButton extends StatelessWidget {
  const _SafeBackButton({
    super.key,
    this.fallbackLocation,
    this.onBack,
    this.enabled = true,
    this.hint,
    this.label,
  });

  final String? fallbackLocation;
  final VoidCallback? onBack;
  final bool enabled;
  final String? hint;
  final String? label;

  /// Aparência do voltar desativado.
  static const double _disabledOpacity = 0.4;

  Future<void> _back(BuildContext context) async {
    final bool handled = await Navigator.of(context).maybePop();
    final String? fallback = fallbackLocation;
    if (!handled && fallback != null && context.mounted) context.go(fallback);
  }

  @override
  Widget build(BuildContext context) {
    final String semanticLabel =
        label ?? MaterialLocalizations.of(context).backButtonTooltip;
    if (!enabled) {
      // O leitor de tela ouve "Voltar, desativado" e a dica; o toque (dele
      // ou do dedo) só faz o [onBack], uma só ação.
      return Semantics(
        button: true,
        enabled: false,
        label: semanticLabel,
        hint: hint,
        onTap: onBack,
        excludeSemantics: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onBack,
          child: Opacity(
            opacity: _disabledOpacity,
            child: SafeIconButton(
              icon: LucideIcons.chevronLeft,
              semanticLabel: semanticLabel,
            ),
          ),
        ),
      );
    }
    return SafeIconButton(
      icon: LucideIcons.chevronLeft,
      semanticLabel: semanticLabel,
      onPressed: onBack ?? () => _back(context),
    );
  }
}
