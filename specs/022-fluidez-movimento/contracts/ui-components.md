# Contrato: componentes de movimento e estado (`lib/core/`)

Interfaces públicas que as telas usam. As assinaturas são o contrato; os detalhes internos ficam
na implementação.

## AppMotion / AppMotionScope — `core/theme/app_motion.dart`

```dart
final class AppMotion {
  static AppMotion of(BuildContext context);
  bool get reduced;
  Duration get short;   // 150 ms | 0
  Duration get medium;  // 250 ms | 0
  Duration get long;    // 350 ms | 0
  static const Curve enter, exit, standard, emphasis;
}

class AppMotionScope extends StatelessWidget {
  const AppMotionScope({required bool appReduceMotion, required Widget child});
}
```

Regra: nenhum widget do app usa `Duration(milliseconds: …)` literal para animação de interface; só
`AppMotion.of(context)`.

## SafeStateSwitcher — `core/widgets/safe_state_switcher.dart`

```dart
class SafeStateSwitcher extends StatelessWidget {
  /// Troca animada (fade, topo) quando [stateKey] muda.
  const SafeStateSwitcher({required Object stateKey, required Widget child});
}
```

## SafeSkeleton — `core/widgets/safe_skeleton.dart`

```dart
class SafeSkeleton extends StatelessWidget {
  /// Ligado: esqueleto de [child] (dados de exemplo), lido como "Carregando".
  /// Desligado: [child] normal, com troca animada.
  const SafeSkeleton({required bool enabled, required Widget child});
}
```

## SafeNetworkImage — `core/widgets/safe_network_image.dart`

```dart
class SafeNetworkImage extends StatelessWidget {
  const SafeNetworkImage({
    required String? url,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    required Widget placeholder, // sem url, carregando ou falha
  });
}
```

Decodifica no tamanho exibido e esmaece ao chegar (sem esmaecer se veio do cache na hora).

## AppHaptics — `core/utils/app_haptics.dart`

```dart
abstract final class AppHaptics {
  static Future<void> selection(); // curtir, alternar
  static Future<void> success();   // resposta certa
  static Future<void> error();     // resposta errada
}
```

## Rotas — `core/routing/`

```dart
/// Página com esmaecimento, para rotas que substituem a pilha (go).
CustomTransitionPage<void> appFadePage(GoRouterState state, Widget child);

/// Container das abas: Offstage + TickerMode + FadeThrough na aba que entra.
class TabBranchContainer extends StatefulWidget {
  const TabBranchContainer({required int currentIndex, required List<Widget> children});
}
```

## SafeButton / SafeCard (alterados)

- Anunciados com `Semantics(button: true, enabled: …)`.
- O afundamento dura no mínimo `AppMotion.short`, mesmo com toque curto.
- `SafeButton`: troca ícone ⇄ spinner com `AnimatedSwitcher`.
- A API pública não muda.
