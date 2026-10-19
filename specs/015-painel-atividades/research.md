# Research: Painel de atividades

**Feature**: [spec.md](spec.md) · **Plan**: [plan.md](plan.md) · **Date**: 2026-10-19

As decisões de produto estão na seção Clarifications da spec. As decisões abaixo saem do código das
features 001, 003, 005, 006, 009, 012 e 014, do contrato da API 1.0.9 e da conferência no servidor
(R0).

## R0. Conferência no servidor real (portão de API)

Feita em 2026-10-19: leitura como visitante e, com autorização da usuária, a conta de teste nova
`teste.claude.20261019@exemplo.com` (senha aleatória, não guardada).

| Pedido | Resultado |
|---|---|
| `GET /app/educational/modules` sem token | ✅ 200; 3 módulos (3 lições cada), `completedCount`/`progressPercent` 0, totais `0/9` |
| `POST /auth/app/register` + login | ✅ 201 / 200 |
| `GET /app/educational/modules` conta nova | ✅ `0/9` |
| `GET /app/educational/modules/{id}` conta nova | ✅ `progress {completedCount 0, progressPercent 0, score 0, totalScore 0, isCompleted false}`; ⚠️ `totalScore` só vira 3 depois da 1ª resposta |
| `POST …/answer` **errada** (lição 1) | ⚠️ 200 `isCorrect false`; a lição **conta como concluída** (`1/9`, módulo 33%, `score` 0) |
| Lição 2 errada e depois certa | ✅ continua concluída (`2/9`); `score` 0 → 1: vale a resposta **mais recente** |
| `POST …/answer` sem token | ✅ corrige e **não salva** (os totais da conta não mudam) |
| `selectedOptionId` que não é CUID | ⚠️ 400 `VALIDATION_ERROR` (`field: selectedOptionId`), não `EDUCATIONAL_INVALID_OPTION` |

**Decision**: "concluída" = respondida (certa ou errada), no painel do visitante e no da conta. O
registro do visitante guarda a **resposta mais recente** de cada lição; reenviá-la depois de criar
a conta dá à conta as mesmas lições concluídas e a mesma pontuação. Contrato da API → **1.0.10**
(endpoints de atividades conferidos; as três ressalvas ⚠️ acima, que a B3/B4 vão precisar).

## R1. Camadas e independência do Perfil

**Decision**: o `activities` ganha `data` → `domain` → `presentation` próprios, com
`ActivitiesRemoteDataSource` lendo `GET /app/educational/modules` (e, para a transferência,
`POST …/answer`). O `profile` continua com a sua leitura para as conquistas; nenhum dos dois
importa o outro.

**Rationale**: Princípio I (módulos só se falam pelo `common` ou pelo barrel público; o plano do
produto diz que cada módulo lê os seus endpoints). Os dois usos pedem campos e regras diferentes
(conquistas × painel com status e progresso de visitante).

**Alternatives considered**: mover a leitura para o `common` e as duas features usarem (o `common`
é infraestrutura, não domínio); importar o `profile` (proibido).

## R2. Status do módulo

**Decision**: `enum ModuleStatus { notStarted, inProgress, completed, unavailable }` derivado na
entidade `ModuleSummaryEntity`: `lessonsCount == 0` → `unavailable`; `completedCount == 0` →
`notStarted`; `completedCount >= lessonsCount` → `completed`; senão `inProgress`. O
`completedCount` é limitado a `lessonsCount` na entidade (dado inconsistente, edge case). A
extensão de apresentação dá rótulo (chave), tom do `SafeBadge` (`neutral`, `primary`, `success`,
`neutral`) e ícone Lucide.

**Rationale**: o serviço não manda status; deixar a regra na entidade a mantém testável sem
widget e igual para conta e visitante.

**Alternatives considered**: usar `progressPercent` (arredondado pelo serviço: 33/67, e não existe
para o visitante); status no controller (regra de domínio fora do domínio).

## R3. Progresso do visitante: `GuestProgressStore`

**Decision**: classe do `activities/data` (`GuestProgressStore`), registrada como **singleton** no
`ActivitiesModule`, só em memória:

- `recordAnswer({moduleId, lessonId, selectedOptionId})`: guarda/substitui a resposta mais
  recente da lição (a B3 chama; a B1 testa).
- `answeredCount(moduleId)` e `answers` (lista para reenviar).
- Escuta `UserSessionService.sessionStatus`. Ao sair de `guest`:
  - para `authenticated` **e** a sessão nasceu de um cadastro (R4) → as respostas viram
    **pendentes de envio** (R5);
  - qualquer outro caso → apaga tudo (FR-008).
- Ao sair de uma conta (`authenticated` → outro estado) → apaga também as pendentes.

O painel do visitante usa a lista de módulos do serviço (sem token) e troca `completedCount` de
cada módulo por `answeredCount(moduleId)` (limitado a `lessonsCount`); o total concluído é a soma,
e o total disponível é o do serviço.

**Rationale**: uma instância por execução do app é exatamente "a sessão atual" da RN-006; ficar no
`data` do `activities` deixa a B3 (mesmo módulo) gravar sem depender de outro módulo. Ouvir a
sessão no próprio registro concentra a regra de descarte num lugar testável com uma
`UserSessionService` de verdade sobre o fake do armazenamento.

**Alternatives considered**: `LocalCacheService` (sobreviveria ao fechar o app, contra a RN-006);
registro no `common` (não é infraestrutura; só o `activities` usa); limpar no controller do
painel (só funcionaria com o painel aberto).

## R4. Saber que a conta acabou de ser criada

**Decision**: `UserSessionService.saveSession` ganha `bool newAccount = false`; o valor fica em
`bool get startedFromSignUp` (só em memória, não gravado) e é definido **antes** de `sessionStatus`
mudar, para quem ouve a mudança já ler o valor certo. No `authentication`, o
`AuthRepositoryImpl.register` passa `newAccount: true` ao `_signIn` (parâmetro novo, repassado ao
`saveSession`); o login continua com o padrão `false`. `restoreSession` e `startGuestSession`
voltam o valor a `false`.

**Rationale**: login e cadastro chamam o mesmo `saveSession`; a sessão é o único ponto que o
`activities` pode ouvir sem importar o `authentication` (Princípio I). Mudança pequena e com teste
na `common` e no `authentication` (feature fechada), justificada aqui.

**Alternatives considered**: o `activities` ouvir o `authentication` (proibido); um "evento de
conta criada" novo no `common` (outro canal para a mesma transição; o flag junto da sessão evita
corrida entre os dois avisos); transferir também no login (descartado na clarificação).

## R5. Transferência: reenvio das respostas

**Decision**: `ActivitiesRepositoryImpl.syncGuestAnswers()` envia, uma a uma, as respostas
pendentes do `GuestProgressStore` (`POST …/lessons/{lessonId}/answer` com token) e tira do registro
cada uma que der 2xx; as que falharem ficam. Quem chama:

1. o próprio registro, logo depois da passagem visitante → conta nova (sem `await`: não atrasa a
   entrada, FR-008a);
2. `getDashboard()` com conta, **antes** do `GET` dos módulos (com `await`), para o painel já vir
   com essas lições e para tentar de novo as que falharam.

Um envio em andamento é reaproveitado (um `Future` só), para os dois caminhos não repetirem
respostas. 404 do módulo/lição ou 400 da opção (conteúdo mudou no serviço) → a resposta é
descartada (não adianta repetir). Falhas nunca chegam à pessoa.

**Rationale**: o serviço só aceita respostas uma a uma (R0); como a conta é nova, não há lição já
feita para conflitar. Com poucos módulos (hoje 9 lições), o número de pedidos é pequeno.

**Alternatives considered**: enviar no controller do painel (a transferência dependeria de a
pessoa abrir a aba); enviar em paralelo (a ordem não importa, mas em sequência fica mais simples de
testar e não sobrecarrega o servidor gratuito).

## R6. Atualizar ao voltar para a aba ou de um módulo

**Decision**: extrair a técnica do Perfil (B7, `_AccountProfileState`: ouvir o `routerDelegate` e
recarregar quando o caminho volta a ser o da aba; `push` + recarregar na volta, porque o `pop` não
avisa o roteador) para um mixin em `core/widgets/refresh_on_return.dart`
(`RefreshOnReturnMixin`, com `tabPath`, `onReturn()` e `pushAndRefresh(location)`). O Perfil passa
a usá-lo sem mudar de comportamento (os testes "voltar de uma lista atualiza" e "trocar de aba e
voltar atualiza" da B7 continuam iguais) e o painel também.

**Rationale**: Princípio II (DRY): a mesma lógica não sutil em dois módulos. Ela é de navegação, não
de domínio, por isso fica em `core/widgets`.

**Alternatives considered**: copiar o código no painel (duplicação de lógica com contador de
recargas); recarregar só no `initState` (a aba fica viva no `StatefulShellRoute` e não remonta).

## R7. Controller e estados

**Decision**: `ActivitiesDashboardController` (`ChangeNotifier`, `registerFactory`) com
`ActivitiesDashboardStatus { loading, loaded, empty, error }`, `dashboard`, `failure`, `load()` e
`refresh()`. `refresh()` não volta a `loading`: mantém o conteúdo e, se falhar, continua `loaded`
(FR-011). Respostas de cargas antigas são ignoradas (contador de pedidos, como o `FeedController`).
Na carga inicial demorada, `SlowRequestNotice` (core) aparece depois de 5 s com a frase de servidor
acordando, como no login e no detalhe da notícia.

**Rationale**: o mesmo padrão do Início e do Perfil; o servidor gratuito leva ~40 s para acordar.

## R8. Layout de uma ou duas colunas

**Decision**: a página mede `MediaQuery.textScalerOf(context).scale(16) / 16` (a escala total,
sistema × app da B9, como o `ClickSeguroApp` faz). Igual a 1,0 → duas colunas: os cartões em
linhas de dois, com `IntrinsicHeight` para os dois da linha terem a mesma altura, descrição com
`maxLines: 3` e reticências, e `Semantics(label:)` com a descrição inteira. Maior que 1,0 → uma
coluna com a descrição inteira. Número ímpar: o último cartão ocupa meia largura (um `Expanded`
vazio ao lado). Dentro de um `ListView` com o progresso geral, o aviso do visitante e os cartões.

**Rationale**: atende à clarificação (duas colunas só com a letra normal) e troca na hora quando a
pessoa muda a letra (o `MediaQuery` muda e a página reconstrói).

**Alternatives considered**: `GridView` com `childAspectRatio` fixo (corta o texto ao aumentar a
letra); `LayoutBuilder` pela largura (a regra combinada é pela letra, não pela largura).

## R9. Ícone do módulo

**Decision**: `Image.network(iconUrl, width/height 48, errorBuilder → ícone padrão,
loadingBuilder → o mesmo ícone padrão)`, como o `NewsCard`. Sem `iconUrl` → ícone padrão
(`LucideIcons.graduationCap`, `colors.primary`, num quadrado claro). Imagem decorativa
(`ExcludeSemantics`).

**Rationale**: sem dependência nova; mesmo padrão já usado nas notícias.

## R10. Aviso do visitante

**Decision**: `GuestProgressNotice` acima dos cartões, só com `UserSessionService.isGuest`: ícone
`info`, a frase e um `SafeButton` "Entrar ou criar conta" → `context.go('/login')`, como o convite
do Perfil. A sessão continua de visitante até o cadastro, por isso o progresso não se perde no
caminho até a tela de criar conta (conferido no roteador: `/login` não encerra a sessão).

## R11. Testes

**Decision**:

- Models e entidades: JSON real do R0 (`modules`, `totalLessonsCompleted`,
  `totalLessonsAvailable`); `iconUrl` vazio → `null`; status nos quatro casos; `completedCount` >
  `lessonsCount` limitado.
- Datasource: `FakeHttpClientAdapter` — `GET` sem token para o visitante e com token para a conta;
  `POST …/answer` com `{selectedOptionId}`.
- `GuestProgressStore` com `UserSessionService(FakeSecureStorageService())` de verdade: grava,
  substitui, conta; descarta nas transições do R3; vira pendente só com `newAccount: true`.
- `UserSessionService`: `startedFromSignUp` no cadastro, no login, na restauração e no visitante;
  definido antes da notificação. `AuthRepositoryImpl.register` passa `newAccount: true` e o login
  não.
- Repository: visitante (soma do registro, totais do serviço), conta, transferência (sucesso tira,
  falha fica, 404/400 descarta, envio único em andamento), mapeamento de falhas.
- Usecase, controller (estados, refresh que mantém conteúdo, resposta antiga ignorada).
- Página: progresso geral, ordem dos cartões, status, ícone padrão, toque abre `/activities/:id`
  uma vez, indisponível não abre, aviso e botão do visitante, recarga ao voltar, erro com tentar de
  novo, vazio, duas colunas com letra 100% e uma coluna com 115% (B9) e com o celular em 2×, inglês.
- `RefreshOnReturnMixin`: os testes da B7 continuam verdes sem mudança.
