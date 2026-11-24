# Data Model: Tela de Acessibilidade

**Feature**: [spec.md](spec.md) · **Plan**: [plan.md](plan.md) · **Research**: [research.md](research.md)

Esta feature **não cria nem muda dados guardados**. Ela mostra e altera as preferências da feature
009 e reorganiza o estado das Configurações para o visitante.

## 1. Entidades existentes (sem mudança)

### `AccessibilityPreferences` (`common/accessibility`, feature 009)

| Campo | Tipo | Padrão | Na tela |
|---|---|---|---|
| `fontScale` | `FontScaleLevel` (`standard` 1,0 · `large` 1,15 · `larger` 1,3 · `largest` 1,5) | `standard` | 4 opções, porcentagem = `factor × 100` |
| `highContrast` | `bool` | `false` | chave "Alto contraste" |
| `autoReadAloud` | `bool` | `false` | chave "Ler automaticamente" |
| `readingSpeed` | `ReadingSpeed` (`slow` · `normal` · `fast`) | `normal` | 3 opções |

Guardada pelo `AccessibilityRepository` sob a chave `accessibility_preferences_v1` do
`LocalCacheService`, uma por aparelho. Teto da escala total (sistema × app): 2,0. Valores ilegíveis
caem no padrão, campo a campo (feature 009).

### `AccessibilityController` (`settings/presentation`, feature 009)

Único, carregado no `setupApp()`. Interface usada pela tela:

| Membro | Uso na tela |
|---|---|
| `preferences` | valores marcados (FR-009) |
| `setFontScale(FontScaleLevel)` | opção de tamanho |
| `setHighContrast(bool)` | chave de contraste |
| `setAutoReadAloud(bool)` | chave de leitura automática |
| `setReadingSpeed(ReadingSpeed)` | opção de velocidade |

Regras que já valem (testadas na 009): aplica no notifier antes de gravar; escolha igual à atual não
grava; gravações em fila, a última por último; falha de gravação engolida.

## 2. Mudança de estado: `SettingsController` (`settings/presentation`, feature 013)

| Membro | Antes | Depois |
|---|---|---|
| `load()` | conta + versão + idioma | `Future.wait([_loadAccount(), loadDeviceSettings()])` (mesmo efeito) |
| `loadDeviceSettings()` | — | **novo**: versão + idioma, sem a conta (FR-015) |
| `account` | `AccountLoading` até a resposta | sem mudança; no visitante fica `AccountLoading` e não é lido |

Quem chama qual (página, R6):

```text
abre /settings ─┬─ sessão conectada ──→ load()               → lista com conta
                └─ sem conta ─────────→ loadDeviceSettings() → lista do visitante
sessão expira com a tela aberta ──────→ (nada recarrega)     → lista do visitante
```

## 3. Apresentação (novos, `settings/presentation`)

### Extensões de rótulo (`extensions/accessibility_presentation.dart`)

| Valor | Chave de texto | pt-BR | en-US |
|---|---|---|---|
| `FontScaleLevel.standard` | `settings_accessibility_font_standard` | Padrão | Default |
| `FontScaleLevel.large` | `settings_accessibility_font_large` | Grande | Large |
| `FontScaleLevel.larger` | `settings_accessibility_font_larger` | Maior | Larger |
| `FontScaleLevel.largest` | `settings_accessibility_font_largest` | Muito grande | Extra large |
| `ReadingSpeed.slow` | `settings_accessibility_speed_slow` | Lenta | Slow |
| `ReadingSpeed.normal` | `settings_accessibility_speed_normal` | Normal | Normal |
| `ReadingSpeed.fast` | `settings_accessibility_speed_fast` | Rápida | Fast |

`FontScaleLevel.percentLabel` → `"${(factor * 100).round()}%"` (não traduzido).

### Widgets

| Widget | Papel |
|---|---|
| `AccessibilityPage` | a tela (`/settings/accessibility`) |
| `SettingsOptionTile<T>` | linha de escolha única com `Radio<T>` dentro de um `RadioGroup<T>` (R3) |
| `SettingsSwitchTile` | linha com chave, extraída da `AlertsSwitchTile` (R4) |
| `FontPreviewCard` | cartão com o texto de exemplo (R2) |
| `SettingsSectionTitle` · `SettingsCard` | extraídos do `SettingsSection` (que passa a ser os dois em coluna), para a prévia e o rótulo da velocidade ficarem fora do cartão |

## 4. Textos novos e alterados (i18n)

Novos (`AppStrings` + `pt-BR.json` + `en-US.json`):

| Chave | pt-BR | en-US |
|---|---|---|
| `settings_accessibility_section_font` | Tamanho da letra | Text size |
| `settings_accessibility_preview_title` | Golpe do falso parente | Fake relative scam |
| `settings_accessibility_preview_body` | Desconfie de mensagem de número novo pedindo dinheiro com urgência. | Be wary of messages from a new number urgently asking for money. |
| `settings_accessibility_font_*` (4) | ver §3 | ver §3 |
| `settings_accessibility_section_appearance` | Aparência | Appearance |
| `settings_accessibility_high_contrast` | Alto contraste | High contrast |
| `settings_accessibility_high_contrast_sub` | Cores mais fortes para ler melhor | Stronger colors for easier reading |
| `settings_accessibility_section_voice` | Leitura em voz alta | Read aloud |
| `settings_accessibility_auto_read` | Ler automaticamente | Read automatically |
| `settings_accessibility_auto_read_sub` | Ao abrir uma notícia, o app começa a ler sozinho | When you open a news story, the app starts reading on its own |
| `settings_accessibility_speed` | Velocidade da voz | Voice speed |
| `settings_accessibility_speed_*` (3) | ver §3 | ver §3 |

Alterado: `settings_guest_body` → "Para trocar a senha, entre na sua conta." / "Sign in to your
account to change your password." (só a `ChangePasswordPage` usa o convite agora, R6).

O título da tela reaproveita `settings_accessibility_title` (já existe).
