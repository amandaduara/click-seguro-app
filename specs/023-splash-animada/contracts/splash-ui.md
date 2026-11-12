# Contrato de UI — Splash e marca

## SplashPage

- Entrada: `SplashController` via Provider; `AppMotion.of(context)`.
- Navega com `context.go(destino.path)` **uma vez**, quando `resolveDestination()` e a animação
  (1 800 ms; 0 ms com movimento reduzido) terminaram.
- Semântica: um único nó com "Click Seguro" e a frase; cena animada em `ExcludeSemantics`.
- Chaves para teste: `SplashPage.sceneKey` (cena animada), `SplashPage.logoKey` (marca).

## SplashAnimation (widget)

```text
SplashAnimation({required VoidCallback? onCompleted, required bool breathing})
```
- Toca uma vez ao montar; chama `onCompleted` ao chegar a `final` (imediato com movimento
  reduzido).
- `breathing: true` liga a respiração do logo (ignorado com movimento reduzido).
- Cores só de `context.colors`.

## BrandMark / BrandMarkPainter (core/widgets)

```text
BrandMarkPainter({required Color color, double strokeProgress = 1, double elderProgress = 1})
```
- `AppLogo(size)` = `BrandMark` em `context.colors.primary`, decorativo (sem semântica).
- `shouldRepaint` quando cor ou progressos mudam.
