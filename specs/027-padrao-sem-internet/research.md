# Research: Padrão único para a falta de internet

Decisões técnicas da feature 027. Levantamento feito no código de `develop` em 2026-11-23
(depois do merge do PR #33).

## R1. O tipo da falha já chega à tela

**Decision**: nenhuma mudança na camada de dados. Todos os repositórios que falam com a API
(`activities`, `assistant`, `authentication`, `help`, `news`, `notifications`, `profile`,
`settings/account`) devolvem `ConnectionFailure` para `ApiErrorType.connection` e `timeout`,
via `ApiFailureMapper.toFailure()` ou a lista `_offlineErrors` do `news`.

**Rationale**: o problema está só na apresentação: telas que descartam a `Failure` e mostram um
texto fixo, e o `SafeErrorState`, que adivinha a falha pelo texto.

**Alternatives considered**: um serviço de conectividade em tempo real (`connectivity_plus`).
Rejeitado: dependência nova, fora do escopo (spec, Assumptions) e não resolveria as telas que
escondem a falha.

## R2. `SafeErrorState` decide pela `Failure`, não pelo texto

**Decision**: o construtor passa a receber `Failure? failure` e um `String? message` opcional
(texto da tela, já traduzido, usado só quando a falha **não** é de conexão):

- `failure is ConnectionFailure` → nuvem (`stateOffline`) + `failure.message.tr()`;
- senão → tomada (`stateError`) + `message ?? (failure?.message ?? AppStrings.errorGeneric).tr()`.

Sai a comparação `message == AppStrings.errorConnection.tr()`.

**Rationale**: Princípio V da constituição (erros tipados, sem strings mágicas). Com isso, as
13 chamadas ficam mais curtas (`SafeErrorState(failure: controller.failure, onRetry: …)`) e
Atividades e Lição passam a acertar o desenho só por passarem a falha.

**Alternatives considered**:
- `bool offline` no construtor: cada tela teria de repetir `failure is ConnectionFailure`
  (DRY).
- Construtor nomeado `SafeErrorState.failure(...)` ao lado do atual: deixaria viva a forma que
  causou o defeito.

## R3. Mensagem das ações: `messageKeyOr`

**Decision**: nova extensão em `core/errors/failure_message.dart` (exportada pelo
`errors.dart`):

```dart
extension FailureMessageKey on Failure? {
  /// A chave da falta de internet, se for o caso; senão, a chave da tela.
  String messageKeyOr(String fallbackKey) =>
      this is ConnectionFailure ? this!.message : fallbackKey;
}
```

As telas trocam `AppStrings.xFailed.tr()` por `failure.messageKeyOr(AppStrings.xFailed).tr()`.

**Rationale**: devolve a **chave** (o `core/errors` não depende de `easy_localization`) e
mantém a mensagem própria para os outros erros (FR-008, SC-004). Um ponto só para a regra.

**Alternatives considered**: mudar as `Failure` dos módulos para carregar a mensagem da ação.
Rejeitado: espalharia textos de tela pela camada de domínio.

## R4. Onde a falha precisa passar a ser guardada

Levantamento das ações que hoje mostram texto genérico (FR-006), e o que muda:

| Ação | Hoje | Mudança |
|---|---|---|
| Atividades: carregar | `ActivitiesDashboardController.failure` existe, a tela ignora | só a tela |
| Lição: carregar | `LessonController._load` descarta a falha | guardar `failure` |
| Lição: responder | `confirm()` devolve `AnswerAttempt.failed`, sem a falha | guardar `answerFailure` |
| Trocar senha | `ChangePasswordController.saveFailure` existe | só a tela |
| Editar perfil: salvar | `EditProfileController.saveFailure` existe | só a tela |
| Editar perfil: trocar foto | `AvatarUpdateFailed(:failure)` existe | só a tela |
| Editar perfil: remover foto | `removePhoto()` devolve a falha | só a tela |
| Perfil: números e conquistas | `AreaFailed(:failure)` existe | só os widgets |
| Configurações: alertas | `setReceiveAlerts` devolve a falha mas não guarda; `AccountFailed(:failure)` | guardar `alertsFailure` |
| Feed, Salvas e Reels: carregar mais | `loadMoreFailure` existe | `FeedListFooter` recebe a falha; Reels, só a tela |

Já corretas (só conferir em teste): login, cadastro, esqueci a senha, Assistente, apagar e
enviar contato, mensagens do feed e do detalhe (`failure.message`).

**Rationale**: a mudança mínima é guardar a falha onde ela é jogada fora; o resto é troca de
texto na tela.

## R5. Reels: legibilidade no fundo preto

**Decision**: o `_Dark` dos Reels passa a sobrepor também a `AppPalette` (como o
`_ReelSkeleton` já faz): `textForeground` e `textMutedForeground` viram o branco
(`textPrimaryForeground`, o de apoio com transparência), além do `textTheme` que já ajusta.

**Rationale**: `SafeStateLayout` pinta o texto com `context.colors.textForeground`, e o `_Dark`
só mudava o `textTheme`, por isso a frase saía em tinta sobre preto. Corrigir na moldura dos
Reels conserta o erro **e** o vazio da mesma tela, sem dar ao `SafeStateLayout` um modo escuro
que só uma tela usa (KISS). Branco sobre preto passa de 4,5:1 (SC-003), também no alto
contraste.

**Alternatives considered**: parâmetro `foreground` no `SafeStateLayout`. Rejeitado: API nova
para um caso.

## R6. Faixa dos Alertas sem conteúdo guardado

**Decision**: `SafeOfflineBanner({bool showsSavedContent = true})`. Com `false`, mostra a chave
nova `common_offline_banner_short` ("Você está sem internet." / "You are offline."). O
`AlertsNotices` passa `showsSavedContent: alerts.isNotEmpty`.

**Rationale**: um só componente, aparência igual, texto honesto (FR-011).

## R7. Padrões que ficam como estão

- Formulários de entrada: texto na própria tela (login, cadastro, esqueci a senha).
- Demais ações: `SnackBar`.
- Blocos parciais: texto no próprio bloco com o tentar de novo dele (Perfil, fim da lista,
  linha dos alertas).

**Rationale**: a revisão aprovada pela usuária mudou o **texto**, não o lugar; trocar SnackBar
por faixa seria redesign fora do escopo.

## R8. Testes

**Decision**: TDD por história, com o fake do repositório devolvendo `ConnectionFailure` e
`ServerFailure`:

- `safe_error_state_test`: nuvem + frase com `ConnectionFailure`; tomada + `message` com
  `ServerFailure`; tomada + `errorGeneric` sem falha.
- `failure_message_test`: `messageKeyOr` para conexão, servidor e `null`.
- Telas: Atividades, Lição (carregar e responder), Reels (cor da frase), Trocar senha, Editar
  perfil (salvar, foto), Perfil (blocos), Configurações (linha dos alertas), rodapé do feed,
  faixa dos Alertas (com e sem alertas).
- Os testes atuais que esperam o texto genérico com falha de **servidor** continuam valendo
  (SC-004).
