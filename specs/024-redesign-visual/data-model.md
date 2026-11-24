# Data Model: Redesign visual 2.0

**Feature**: [spec.md](spec.md) · **Research**: [research.md](research.md)

A feature não cria dados de negócio nem muda a API. As "entidades" são os tokens visuais, uma
preferência nova salva no aparelho e o catálogo de ilustrações.

## AccessibilityPreferences (muda)

Entidade em `lib/modules/common/accessibility/accessibility_preferences.dart`, salva pelo módulo
settings (features 009 e 014).

| Campo | Tipo | Padrão | Novo? | Regra |
|---|---|---|---|---|
| `fontScale` | `FontScaleLevel` | `standard` | não | RF-038 |
| `highContrast` | `bool` | `false` | não | RF-039 |
| `autoReadAloud` | `bool` | `false` | não | RF-040 |
| `readingSpeed` | `ReadingSpeed` | `normal` | não | RF-040 |
| `reduceMotion` | `bool` | `false` | **sim** | FR-024: desliga as animações do app |

- **Persistência**: nova chave no `AccessibilityLocalDataSource` (`shared_preferences`). Se a chave
  não existir (quem atualiza o app), o valor é `false`.
- **Aplicação**: no `main.dart`, `MediaQueryData.disableAnimations = sistema || reduceMotion`
  ([R8](research.md#r8-reduzir-animações-um-sinal-só)).
- **Transições**: o interruptor muda o valor, o notifier publica e a tela seguinte já abre sem
  animação. As animações que estão rodando terminam no estado final.

## Tokens visuais (novos ou mudam)

### AppPalette

Campos que existem e mudam de valor (tema claro):

| Campo | Tema claro | Alto contraste |
|---|---|---|
| `primary` | #E31C3D | #9E0019 |
| `secondary` / `textForeground` | #1B2440 | #0B1A3A / #000000 |
| `textMutedForeground` | #5E6577 | #333333 |
| `background` / `card` | #FFFFFF | #FFFFFF |
| `border` | #E4E1DA | #000000 |
| `input` | #F7F5F0 | #F2F2F2 |
| `inputBorder` | #8A8F9C (o #C9C5BD do Figma dava 1,7:1; WCAG 1.4.11 pede 3:1) | #000000 |
| `success` | #0F7B4F | #005A3C |
| `warning` | #8F5600 | #6E4200 |
| `destructive` | #C4122F | #9E0019 |

Campos novos:

| Campo | Tema claro | Alto contraste |
|---|---|---|
| `primaryPressed` | #C2112F | #7A0013 |
| `primarySoft` | #FFE8EB | #FFFFFF |
| `textBody` | #3D4457 | #000000 |
| `surface` | #F7F5F0 | #FFFFFF |
| `surfaceStrong` | #EFEBE3 | #F2F2F2 |
| `info` | #2554C7 | #0B3A9E |
| `successSoft` / `warningSoft` / `infoSoft` | #DFF3E8 / #FDF0D5 / #E4ECFB | #FFFFFF (com borda) |
| `pastelPeach` / `Sage` / `Sky` / `Butter` / `Lilac` | #FFD9CE / #D3E8DA / #D8E6F7 / #FCEBB6 / #E6DFF6 | #FFFFFF |
| `shadow` | sombra única ([R4](research.md#r4-cantos-sombra-e-espaçamento)) | `[]` |

Campos removidos: `primaryGlow`, `shadowPrimary`, `gradient` (e `shadowSm`/`shadowMd`, trocados
por `shadow`).

**Validação**: todo par de texto e fundo usado nos componentes MUST ter contraste de 4,5:1 ou
mais no claro (3:1 para texto de 24 ou mais em negrito) e de 7:1 no alto contraste. O teste está
em `app_palette_test.dart` (SC-002).

### AppTypography, AppSpacing, AppMotion

Valores em [R3](research.md#r3-escala-de-texto), [R4](research.md#r4-cantos-sombra-e-espaçamento)
e [R8](research.md#r8-reduzir-animações-um-sinal-só). São constantes, sem estado.

## Ilustração

`AppIllustration` (enum em `lib/core/illustrations/app_illustration.dart`) → asset SVG em
`assets/illustrations/`.

| Valor | Arquivo | Onde aparece |
|---|---|---|
| `onboardingProtect` | `onboarding_protect.svg` | onboarding, slide 1 |
| `onboardingNews` | `onboarding_news.svg` | onboarding, slide 2 (novo, no mesmo estilo) |
| `onboardingPractice` | `onboarding_practice.svg` | onboarding, slide 3 (novo, no mesmo estilo) |
| `themeWhatsapp` | `theme_whatsapp.svg` | módulo e capa de notícia |
| `themePix` | `theme_pix.svg` | módulo e capa |
| `themeLink` | `theme_link.svg` | módulo e capa |
| `themeCall` | `theme_call.svg` | módulo e capa |
| `themePassword` | `theme_password.svg` | módulo e capa |
| `themeFakeNews` | `theme_fake_news.svg` | módulo e capa |
| `themeGeneric` | `theme_generic.svg` | módulo e capa sem tema reconhecido |
| `stateOffline` | `state_offline.svg` | sem internet |
| `stateError` | `state_error.svg` | erro |
| `stateEmpty` | `state_empty.svg` | lista vazia, notícia não encontrada |
| `stateTrophy` | `state_trophy.svg` | conclusão do módulo |
| `answerCorrect` | `answer_correct.svg` | feedback certo |
| `answerWrong` | `answer_wrong.svg` | feedback errado (lâmpada) |

Regras:
- Toda ilustração é decorativa (fica fora da árvore de semântica).
- Usa só as cores da paleta das ilustrações (tinta, branco, coral, dourado, verde, menta, cinza e
  os pastéis), para o `ColorMapper` do alto contraste conseguir trocar cada uma
  ([R5](research.md#r5-ilustrações-em-svg-com-flutter_svg)).
- Nas capas de tema (`theme*`), o fundo pastel não faz parte do SVG: vem do container (capa ou
  cartão). Nas de estado, onboarding e resposta, o círculo pastel atrás do desenho faz parte dele,
  como no Figma, e vira branco no alto contraste.

## IllustrationTheme

Enum em `lib/core/illustrations/illustration_theme.dart`: `whatsapp`, `pix`, `link`, `call`,
`password`, `fakeNews`, `generic`.

- `static IllustrationTheme fromText(String? text)`: normaliza (minúsculas, sem acentos) e devolve
  o primeiro tema cuja palavra-chave aparece. Se nenhuma aparecer ou o texto for vazio, devolve
  `generic`. A tabela está em [R7](research.md#r7-reconhecer-o-tema-do-módulo-e-da-notícia).
- `AppIllustration get illustration` e `Color pastel(AppPalette)`: a ilustração e a cor de fundo
  do tema. No alto contraste, a cor é branca.

Entradas por uso:
- Cartão de módulo: `ModuleSummaryEntity.title` (e o `title` do `suggestedModule` no detalhe da
  notícia).
- Capa de notícia sem imagem: a primeira categoria; se der `generic`, o título.
