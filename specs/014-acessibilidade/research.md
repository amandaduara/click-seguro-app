# Research: Tela de Acessibilidade

**Feature**: [spec.md](spec.md) · **Plan**: [plan.md](plan.md) · **Date**: 2026-10-15

As decisões de produto estão na seção Clarifications da spec. As decisões abaixo saem do código das
features 005, 007, 009, 010, 012 e 013 e do Flutter 3.47.5. Não há chamada de API nesta feature,
então não há portão de servidor (R0 das features anteriores).

## R1. Estado da tela: o `AccessibilityController` que já existe

**Decision**: a `AccessibilityPage` usa o `AccessibilityController` da feature 009 sem mudar a
interface dele. Ele já é um único objeto (`registerLazySingleton`), carregado no `setupApp()` antes
da primeira tela e entregue ao app inteiro pelo `ChangeNotifierProvider.value` do
`SettingsModule.providers`. A página o lê com `context.watch<AccessibilityController>()` e chama
`setFontScale`, `setHighContrast`, `setAutoReadAloud` e `setReadingSpeed`.

**Rationale**: o controller já aplica na hora pelo `AccessibilityPreferencesNotifier` (FR-007),
grava em fila com a última escolha por último (caso de toques rápidos), ignora a escolha igual à
atual (caso "tocar no nível já marcado") e engole a falha de gravação (FR-010). Tudo isso já tem
teste em `accessibility_controller_test.dart`. A tela é só apresentação.

**Alternatives considered**: um controller novo para a tela (estado duplicado do notifier, sem
ganho); `GetIt.instance<AccessibilityController>()` direto na página (funciona, mas o provider já
existe para isso, como diz o comentário do `SettingsModule`).

## R2. Tamanho da letra e prévia ao vivo

**Decision**: seção "Tamanho da letra" com, no topo, um cartão de prévia (um título e uma frase
curta de notícia de golpe, em `bodyLarge`) e, abaixo, as quatro opções de `FontScaleLevel` como
linhas de escolha única: nome do nível ("Padrão", "Grande", "Maior", "Muito grande") e a
porcentagem à direita, calculada de `factor` (`100%`, `115%`, `130%`, `150%`). A linha inteira é
tocável.

A prévia não precisa de escala própria: como o app inteiro muda na hora (`ClickSeguroApp` aplica o
`textScaler` a partir do notifier), o cartão e a própria tela crescem juntos. O cartão serve para a
pessoa ter um texto de leitura corrida para comparar, já que o resto da tela são rótulos.

**Rationale**: linhas grandes com rótulo escrito são mais fáceis para o público idoso do que um
controle deslizante ou uma fileira de "A" de tamanhos diferentes, e funcionam bem com leitor de
tela (cada linha anuncia o nome, a porcentagem e "selecionado"). Quatro níveis cabem numa lista.

**Alternatives considered**: `Slider` com 4 paradas (pequeno de acertar, pior no TalkBack);
`SegmentedButton` com "A" em 4 tamanhos (no nível máximo × escala do sistema, quatro segmentos não
cabem na largura do celular); prévia com `MediaQuery` próprio simulando o nível antes de aplicar
(contradiz FR-007, que pede efeito imediato, sem "salvar").

## R3. Linhas de escolha única no Flutter 3.47

**Decision**: um widget novo `SettingsOptionTile<T>` no módulo, no mesmo visual do `SettingsTile`
(altura mínima 64, título 16 sp em negrito), com um `Radio<T>` à direita. O grupo usa o
`RadioGroup<T>` (`groupValue` + `onChanged` no ancestral), o modo atual do Flutter; `Radio` com
`groupValue`/`onChanged` próprios está obsoleto desde o 3.32. A linha inteira chama `onChanged` ao
toque e fica dentro de um `MergeSemantics`, como o `SettingsTile`, para o leitor de tela ler nome e
estado juntos.

**Rationale**: reaproveita o visual da B8 dentro do `SettingsSection` (cartão branco com divisórias)
e evita a API obsoleta, que geraria aviso no `flutter analyze`.

**Alternatives considered**: `RadioListTile` (visual diferente das linhas das Configurações e padding
do Material que não segue o design system); um ícone de "check" sem `Radio` (perde a semântica de
botão de opção sem trabalho extra).

## R4. Chaves (alto contraste e leitura automática): `SettingsSwitchTile`

**Decision**: extrair da `AlertsSwitchTile` um `SettingsSwitchTile` (ícone, título, subtítulo,
valor, `onChanged` anulável) com a mesma chave (`activeTrackColor: success`). A `AlertsSwitchTile`
passa a usá-lo (ela continua cuidando de "carregando" e de "Tentar novamente"), e a tela de
Acessibilidade usa duas instâncias: "Alto contraste" e "Ler automaticamente".

**Rationale**: três chaves com o mesmo visual pedem um widget só (Princípio II, DRY); a mudança na
`AlertsSwitchTile` é interna, e os testes da B8 continuam valendo.

**Alternatives considered**: copiar o `SettingsTile` + `Switch` da `AlertsSwitchTile` nas duas
chaves novas (repetição); `SwitchListTile` (mesmo problema de visual do R3).

## R5. Velocidade da voz

**Decision**: na seção "Leitura em voz alta", depois da chave de leitura automática, um subtítulo
"Velocidade da voz" e as três opções de `ReadingSpeed` com o mesmo `SettingsOptionTile` (R3):
"Lenta", "Normal", "Rápida". A velocidade fica disponível com a leitura automática ligada ou
desligada, porque vale também para o botão "Ouvir".

As chaves de texto são novas (`settings_accessibility_speed_*`, com maiúscula): as da notícia
(`news_detail_speed_*`) são minúsculas, feitas para a frase "Velocidade: lenta", e pertencem a outro
módulo.

**Rationale**: a spec (Assumptions) inclui a velocidade porque a feature 009 a guarda e não há outra
tela para escolhê-la; a barra de leitura da notícia (feature 010) troca só a velocidade daquela
leitura.

**Alternatives considered**: esconder a velocidade com a leitura automática desligada (a
velocidade também vale para o "Ouvir"); `SegmentedButton` (mesmo problema de largura do R2).

## R6. Visitante nas Configurações

**Decision**:

- **Engrenagem para todos**: o `AppTopBar` (shell) deixa de esconder `_SettingsButton` para o
  visitante (some o `ValueListenableBuilder` em volta dele), e o `_Header` do `ProfilePage`
  (profile) deixa de testar `isAuthenticated`.
- **Uma lista para cada caso**: a `SettingsPage` cria **um** `SettingsController` acima do
  `ValueListenableBuilder` da sessão. Com conta, a lista atual; sem conta, `_GuestSettingsList`, só
  com as seções "Leitura e aparência" (Acessibilidade, Idioma) e "Sobre" (Privacidade, Sobre o
  SafeNews), sem cartão, sem "Sair" e sem convite. As duas seções são extraídas para widgets
  privados (`_ReadingSection`, `_AboutSection`) usados pelas duas listas.
- **Sem pedido ao serviço** (FR-015): o `SettingsController` ganha `loadDeviceSettings()` (versão e
  idioma, sem a conta); `load()` passa a ser conta + `loadDeviceSettings()`. A página chama `load()`
  se a sessão estiver conectada ao abrir, e `loadDeviceSettings()` se não.
- **Sessão expira com a tela aberta**: o `ValueListenableBuilder` troca para a lista do visitante;
  o controller é o mesmo e já tem idioma e versão.
- **Convite**: o `SettingsGuestInvite` sai da `SettingsPage`, mas continua na `ChangePasswordPage`
  (link direto sem conta, como na B8). O texto `settings_guest_body` ("As configurações são da sua
  conta.") deixa de servir, porque agora o visitante tem Configurações; passa a "Para trocar a
  senha, entre na sua conta." (en-US: "Sign in to your account to change your password.").

**Rationale**: o controller único evita recarregar ao trocar de estado e mantém a regra de "nenhum
pedido para o visitante" num lugar só (a página decide qual carga chamar, o controller não precisa
conhecer a sessão). Extrair as duas seções evita duplicar as linhas.

**Alternatives considered**: um `SettingsController` por ramo do `ValueListenableBuilder` (recarrega
idioma e versão quando a sessão expira, e o controller antigo seria descartado no meio de um
`await`); o controller consultar a `UserSessionService` (mistura sessão e tela, e os testes do
controller passariam a precisar da sessão); uma página separada para o visitante (duas rotas para a
mesma tela).

## R7. Leitura automática nas perguntas (B2)

**Decision**: nada a fazer aqui. A `NewsDetailPage` (feature 010) já lê
`AccessibilityPreferencesNotifier.value.autoReadAloud`; a tela de perguntas da B2 fará o mesmo. O
subtítulo da chave diz só "notícia" até a B2 existir, para não prometer o que ainda não funciona;
a B2 atualiza o texto.

**Rationale**: a spec deixa as perguntas para a B2 (Assumptions); o valor já fica disponível para
ela em `common`.

**Alternatives considered**: subtítulo já citando as atividades (promete um comportamento que não
existe na v1 desta tela).

## R8. Atalhos de desenvolvimento

**Decision**: o `lib/dev/accessibility_playground.dart` perde o painel de acessibilidade (botão na
borda esquerda e `_panel()`), que só existia para validar a feature 009 sem esta tela, e o atalho
"Notícias salvas", que esperava a entrada do Perfil (já entregue na B7). Ficam os atalhos dos
alertas (feature 011), com o comentário do topo atualizado.

**Rationale**: o usuário pede que código sem uso saia antes do commit; os dois atalhos ficaram
obsoletos e o arquivo não é importado pelo app.

**Alternatives considered**: apagar o arquivo (os atalhos dos alertas ainda são o único jeito de
testar os alertas no aparelho, porque o servidor de desenvolvimento não publica notícia a pedido);
deixar como está (código morto).

## R9. Testes

**Decision**:

- `accessibility_page_test.dart` (novo): monta o `ClickSeguroApp` com um `GoRouter` só com
  `/settings/accessibility`, como o `accessibility_app_test.dart`, e um `AccessibilityController`
  **real** sobre `AccessibilityRepositoryImpl` → `AccessibilityLocalDataSourceImpl` →
  `FakeLocalCacheService` (o que a tarefa B9 pede). Confere, para cada opção: marcada/ligada na
  tela, efeito no app (`MediaQuery.textScalerOf`, `context.colors`) e valor gravado na chave
  `accessibility_preferences_v1`. "Próxima abertura": um controller novo sobre o mesmo fake carrega
  e a tela, montada de novo, mostra as escolhas. Também: falha de gravação (`throwOnWrite`) não
  trava nem mostra erro; nível máximo × escala do sistema 2,0 sem estouro e com linhas ≥ 48 dp;
  semântica das opções (selecionado/ligado).
- `settings_page_test.dart`: o grupo "sem conta" passa a esperar as quatro linhas, a ausência do
  cartão, de Conta, Alertas, "Sair" e do convite, e **nenhum** pedido ao `FakeAccountRepository`;
  "sessão expira" passa a esperar a lista do visitante.
- `settings_controller_test.dart`: `loadDeviceSettings()` carrega idioma e versão sem chamar a conta.
- `app_top_bar_test.dart` e `profile_page_test.dart`: o visitante vê a engrenagem e ela abre
  `/settings`.
- `alerts_switch_tile`: coberto pelos testes de alertas da `settings_page_test.dart`, que não mudam.

**Rationale**: o teste com o repositório de verdade sobre o fake do armazenamento prova o caminho
inteiro (tela → controller → notifier → app, e tela → gravação → próxima carga) sem mexer no
`shared_preferences`.

**Alternatives considered**: `FakeAccessibilityRepository` (não prova a gravação real no formato
salvo, que é o que a tarefa pede).
