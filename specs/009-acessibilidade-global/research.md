# Research: Acessibilidade global

**Feature**: [spec.md](spec.md) · **Plan**: [plan.md](plan.md)

## R1 — Onde mora a entidade das preferências

**Decision**: `AccessibilityPreferences` (e o enum `FontScaleLevel`) ficam em
`common/accessibility/`, junto com o `AccessibilityPreferencesNotifier`. O módulo `settings`
importa de `common`.

**Rationale**: o plano do produto (§3.2) põe o notifier em `common` para que `news` e
`activities` leiam `autoReadAloud` sem importar `settings`. O notifier é um
`ValueNotifier<AccessibilityPreferences>`, então a entidade precisa estar no mesmo lugar, senão
`common` dependeria de `settings` (constituição, Seção I).

**Alternatives**: entidade em `settings/domain` e notifier com tipo próprio em `common` →
duplicaria os campos (Seção II, DRY).

## R2 — Tema de alto contraste que alcança todas as telas

**Decision**: criar `AppPalette` (`ThemeExtension`) com os mesmos nomes de `AppColors`, em duas
versões (`AppPalette.light` com os valores atuais e `AppPalette.highContrast`), e um atalho
`context.colors`. `AppTheme.lightTheme` e o novo `AppTheme.highContrastTheme` são montados a partir
da paleta. Os widgets que usam `AppColors.x` passam a usar `context.colors.x`. `AppColors`
continua como fonte dos valores da versão light (design system).

**Rationale**: hoje 34 arquivos usam as cores fixas de `AppColors` (139 usos). Só trocar o
`ThemeData` mudaria barras e cards do Material e deixaria botões, textos e ícones com as cores de
sempre, o que não atende o FR-005/SC-003. Com a extensão, a troca de tema chega a todos os widgets
sem `if (highContrast)` espalhado (Seção II, KISS).

**Alternatives**: `if` em cada widget (repetição); trocar `AppColors` para getters globais
mutáveis (estado global fora do Provider, não reconstrói a árvore).

**Paleta de alto contraste** (razões medidas sobre branco `#FFFFFF`):

| Cor | Light | Alto contraste | Razão |
|---|---|---|---|
| `textForeground` | `#121932` | `#000000` | 21:1 |
| `textMutedForeground` | `#596475` | `#333333` | 12,6:1 |
| `primary` / `primaryGlow` / `destructive` | `#FE3152`… | `#9E0019` | 8,5:1 (branco sobre ele também) |
| `secondary` | `#182A4E` | `#0B1A3A` | 17,2:1 |
| `background` / `card` | `#FFFDFB` / `#FFFFFF` | `#FFFFFF` | — |
| `input` | `#EDEDF1` | `#F2F2F2` | texto preto 18,8:1 |
| `border` | `#E6E6EA` | `#000000` | 21:1 (≥ 3:1 exigido) |
| `success` | `#10B981` | `#005A3C` | 8,3:1 |
| `warning` | `#F59E0B` | `#6E4200` | 8,6:1 |
| `textPrimaryForeground` | `#FFFFFF` | `#FFFFFF` | sobre `primary` 8,5:1 |

O gradiente vira cor sólida (`primary` → `primaryGlow` iguais) e as sombras somem (a borda preta
separa os cartões).

## R3 — Escala de fonte somada à do sistema, com teto

**Decision**: no `builder` do `MaterialApp.router`, envolver o app num `MediaQuery` com
`textScaler = TextScaler.linear(min(sistema × nível, 2.0))`, onde `sistema` é
`MediaQuery.textScalerOf(context).scale(16) / 16`.

**Rationale**: `textScaler` é o caminho oficial do Flutter (o antigo `textScaleFactor` está
obsoleto) e vale para todo `Text`. Medir a escala do sistema num tamanho de referência (16 sp,
texto base do RNF-003) funciona também com a escala não linear do Android 14.

**Alternatives**: multiplicar os `fontSize` do `TextTheme` (não alcança `TextStyle` fixos dos
widgets).

## R4 — Carregar antes da primeira tela e falhas de armazenamento

**Decision**: `_setup()` chama `AccessibilityController.load()` depois de registrar os módulos e
antes do `runApp` (como o `restoreSession`). Leitura com erro, registro ausente ou campo
desconhecido → padrão do campo. Ao mudar uma preferência, o notifier muda na hora e a gravação
vai em seguida; gravação que falha é ignorada (o valor vale até fechar o app). Gravações seguidas
são feitas em ordem, e a última vence.

**Rationale**: FR-007, FR-008, FR-009 e SC-005. `shared_preferences` é rápido o bastante para não
atrasar o splash.

## R5 — Velocidade da voz guardada

**Decision**: `ReadAloudController` recebe o `AccessibilityPreferencesNotifier` (opcional nos
testes antigos) e usa `readingSpeed` dele como velocidade das próximas leituras. `setSpeed` da
página continua valendo só para aquela página, sem gravar.

**Rationale**: FR-012; a feature 007 deixou guardar a velocidade para cá. A B9 grava pela
`AccessibilityController`.

## R6 — Validação no aparelho sem a tela da B9

**Decision**: entrada de desenvolvimento `lib/dev/accessibility_playground.dart`, no mesmo
espírito da `platform_services_playground.dart` da 007: sobe o app real (`setupApp()` do
`main.dart`) com um botão flutuante só nessa entrada, que abre um painel para trocar as quatro
preferências pelo `AccessibilityController`. O app normal não tem esse botão.

**Rationale**: permite testar FR-006 (efeito imediato) e RF-041 (fechar e abrir com
`flutter run` normal) no emulador.
