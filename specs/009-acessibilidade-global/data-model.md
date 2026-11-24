# Data Model: Acessibilidade global

## `FontScaleLevel` (enum, `common/accessibility/`)

| Valor | Fator | Rótulo (B9) |
|---|---|---|
| `standard` | 1.0 | Padrão |
| `large` | 1.15 | Grande |
| `larger` | 1.3 | Maior |
| `largest` | 1.5 | Muito grande |

`FontScaleLevel.maxTotalScale = 2.0` (teto da escala sistema × app, FR-004).

## `AccessibilityPreferences` (entity, `common/accessibility/`)

| Campo | Tipo | Padrão |
|---|---|---|
| `fontScale` | `FontScaleLevel` | `standard` |
| `highContrast` | `bool` | `false` |
| `autoReadAloud` | `bool` | `false` |
| `readingSpeed` | `ReadingSpeed` (feature 007) | `normal` |

Imutável, com `copyWith`, `==`/`hashCode` e `const AccessibilityPreferences.defaults()`.

## Registro salvo (`LocalCacheService`, chave `accessibility_preferences_v1`)

```json
{
  "fontScale": "larger",
  "highContrast": true,
  "autoReadAloud": false,
  "readingSpeed": "slow"
}
```

`AccessibilityPreferencesModel.fromJson` lê campo a campo: ausente, tipo errado ou nome
desconhecido → padrão só daquele campo (FR-008). `toJson` grava os nomes dos enums.

## Estado em vigor

- `AccessibilityPreferencesNotifier extends ValueNotifier<AccessibilityPreferences>` (`common`),
  singleton no `CommonModule`. Lido pelo `ClickSeguroApp` (tema e escala) e pelo
  `ReadAloudController` (velocidade); A5/B2 leem `autoReadAloud`.
- `AccessibilityController` (`settings`), singleton, também exposto como Provider: `load()`,
  `preferences`, `setFontScale`, `setHighContrast`, `setAutoReadAloud`, `setReadingSpeed`.
  Cada `set` atualiza o notifier e grava.
