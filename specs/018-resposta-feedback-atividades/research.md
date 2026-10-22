# Research: Resposta e feedback das atividades

**Feature**: [spec.md](spec.md) · **Plan**: [plan.md](plan.md) · **Date**: 2026-10-22

As decisões de produto estão na seção Clarifications da spec. As abaixo saem do código das
features 015 (B1) e 017 (B2), do contrato da API 1.0.10 e da conferência no servidor (R0).

## R0. Conferência no servidor real

Feita em 2026-10-22 **como visitante** (sem token o serviço corrige e não salva; nenhuma conta
criada), no módulo "Golpes Digitais":

| Pedido | Resultado |
|---|---|
| `POST …/lessons/{lessonId}/answer` com a correta | ✅ 200 `{isCorrect: true, correctOptionId, explanation}` |
| Com uma errada da mesma lição | ✅ 200 `{isCorrect: false, correctOptionId, explanation}` (a mesma explicação) |
| Com alternativa de **outra** lição (CUID válido) | 400 `EDUCATIONAL_INVALID_OPTION` |
| Lição que não existe | 404 `EDUCATIONAL_LESSON_NOT_FOUND` |
| Dois `GET /app/educational/modules/{id}` seguidos | **as alternativas vêm em outra ordem a cada pedido** |
| `progress` do visitante | `{completedCount: 0, progressPercent: 0, score: 0, totalScore: 0, isCompleted: false}` |

Da B1 (specs/015 R0, com conta): resposta errada também conta como lição concluída; `score`
considera a resposta mais recente; `totalScore` vem 0 até a primeira resposta da conta no módulo;
alternativa que não é CUID → 400 `VALIDATION_ERROR`.

**Decision**: contrato 1.0.10 confirmado; nada novo a anotar no contrato além do embaralhamento a
cada `GET` (já previsto em RF-027) e do efeito dele descrito no R3.

## R1. Um controller só (`LessonController`)

**Decision**: a resposta entra no `LessonController` da B2, em vez de um `QuizController` separado
como sugere o `tasks.md` do produto.

**Rationale**: avançar depende de responder (`canGoNext` usa a lição respondida), e o resultado
de cada pergunta precisa sobreviver à navegação dentro da visita (US4). Dois `ChangeNotifier`
sincronizando índice, lição concluída e resultado seriam mais código e mais pontos de erro
(Princípio II, KISS). O controller continua só com usecases.

**Alternatives considered**: `QuizController` só para a pergunta atual, recriado a cada troca
(perde o resultado ao voltar; precisaria de um mapa externo de resultados).

## R2. Entidades novas e o que entra agora

**Decision**:

- `AnswerResultEntity {isCorrect, correctOptionId, explanation?}` + `AnswerResultModel`.
- `ModuleScoreEntity {score, total}`: a pontuação do módulo. `ModuleDetailEntity` ganha
  `score` (opcional), que a B4 também vai usar na conclusão.
- `AnswerOutcome {result, score?}`: o que o usecase devolve à tela.
- `GuestAnswer` ganha `isCorrect` (pontuação do visitante, RN-005).

A `explanation` do detalhe do módulo continua **ignorada**: a mostrada é a da correção (spec,
Assumptions). O `progress.isCompleted` também fica de fora (é da B4).

**Rationale**: só o que a B3 usa (regra da revisão do PR #22); a pontuação entra no detalhe porque
é de lá que o serviço a devolve.

## R3. Pontuação depois de responder, sem trocar as alternativas

**Decision**: depois de uma resposta corrigida, o `AnswerLessonUseCase` pede de novo o detalhe do
módulo ao repositório e usa **só** o `score`. As lições da tela **não** são substituídas.

**Rationale**: R0 mostrou que cada `GET` embaralha as alternativas; trocar as lições faria as
alternativas pularem de lugar na frente da pessoa (viola RF-027 e confunde o público idoso).

- **Com conta**: `score = progress.score`, `total = progress.totalScore`; `totalScore` 0 → `score`
  `null` (nunca "0 de 0", FR-011).
- **Sem conta** (visitante ou sessão expirada): o repositório troca pela conta do registro:
  `score = store.correctCount(moduleId)`, `total = número de lições válidas do módulo`;
  nenhuma resposta → `null`. É a mesma regra "sem conta = registro" do `getModuleDetail` da B2.
- Falha nessa busca → `score: null` no resultado; a tela mostra a última pontuação conhecida (ou
  nenhuma) e **não** mostra erro (FR-009).

**Alternatives considered**: calcular a pontuação do visitante sem ir ao serviço (exigiria passar
o total de lições ao repositório ou ao registro; dois caminhos diferentes para conta e visitante);
um endpoint de progresso só (não existe na API).

## R4. Gravar a resposta do visitante

**Decision**: `ActivitiesRepositoryImpl.answerLesson` envia a resposta e, **sem conta**, chama
`store.recordAnswer(moduleId, lessonId, selectedOptionId, isCorrect)` antes de devolver. O
`GuestProgressStore` ganha `correctCount(moduleId)`; a transferência para a conta nova (B1)
continua mandando só `selectedOptionId`.

**Rationale**: a regra fica na camada de dados, como o resto da RN-006; e como o repositório é
singleton, a resposta é gravada mesmo se a pessoa sair da tela no meio do envio (US6, cenário 5).

O `ActivitiesRemoteDataSource.answerLesson` passa a devolver `AnswerResultModel` (antes `void`,
usado só pela transferência, que continua ignorando o resultado).

## R5. Erros ao responder

**Decision**: falha nova `AnswerRejectedFailure` (mensagem `activities_answer_rejected`) para 400
`EDUCATIONAL_INVALID_OPTION`, 400 `VALIDATION_ERROR` e 404 `EDUCATIONAL_LESSON_NOT_FOUND` /
`EDUCATIONAL_MODULE_NOT_FOUND`: o controller recarrega o módulo (volta à primeira não respondida,
esquece os resultados da visita) e a página mostra a mensagem num `SnackBar`. Qualquer outra falha
(rede, 5xx, sessão expirada) mantém a alternativa marcada, não marca a lição e mostra
`activities_answer_failed`; "Confirmar resposta" volta a funcionar.

Sessão expirada no meio do envio: o aviso é o do app (`SessionExpiredListener`); a resposta conta
como falha e pode ser repetida, agora sem conta (spec ajustada no plano).

**Rationale**: os códigos vêm do contrato e do R0; mensagens por chave (Princípio V), como a
`ModuleNotFoundFailure` da B2. `SnackBar` é o padrão das outras telas (perfil, troca de senha).

## R6. Estado da pergunta na visita

**Decision**: o controller guarda, por `lessonId`, a alternativa escolhida e o resultado recebido
**nesta visita** (`Map<String, LessonAnswerState>`):

- `select(optionId)`: só sem envio em andamento e sem resultado na tela;
- `confirm()`: uma vez (ignora toque com envio em andamento); sucesso → guarda o resultado, marca a
  lição como concluída (`withCompleted(true)` na lista da tela), guarda a pontuação quando vier;
- `answerAgain()`: apaga o resultado da pergunta atual (a lição continua concluída);
- recarregar o módulo esvazia o mapa.

Pergunta respondida **antes** da visita: concluída, sem alternativa marcada nem resultado
(o serviço não diz qual foi escolhida); pode ser respondida de novo (clarificação Q1).

## R7. Painel de feedback

**Decision**: `showModalBottomSheet` com `isDismissible: false` e `enableDrag: false`
(clarificação Q3); o voltar do aparelho fecha (padrão da rota do sheet). Conteúdo rolável:
título com ícone (acertou/errou), "Resposta correta: …" (a correta pelo `correctOptionId`; se não
estiver entre as alternativas, a linha some), explicação quando houver, "Você está com X de Y
acertos" quando houver pontuação, `ListenButton` e o botão de seguir: "Próxima pergunta" ou, na
última, "Voltar às atividades". O sheet devolve a ação escolhida; a página chama `goNext()` ou
volta ao painel (`context.pop()`; o painel recarrega pelo `RefreshOnReturnMixin` da B1). Fechado
pelo voltar, a página fica na pergunta com o resultado nas alternativas.

Cores: acerto com `success` e erro com `destructive` da paleta, **sempre** com ícone e texto
(não só cor, FR-001/FR-005).

**Alternatives considered**: painel embutido na página (não é "painel deslizante", RF-026);
`DraggableScrollableSheet` (arrastar é justamente o que foi pedido para não fechar).

## R8. Alternativas escolhíveis e rodapé

**Decision**: o `LessonOptionCard` da B2 vira escolhível: ganha `state`
(`idle`, `selected`, `correct`, `wrong`) e `onTap` (nulo quando não pode trocar). Marcada: borda
grossa da cor primária e ícone de seleção; correta: ícone de check e texto "correta"; errada:
ícone de X e "sua resposta, errada". Semântica de opção única (`inMutuallyExclusiveGroup`,
`checked`), alvo ≥ 48 dp. A ordem é a do serviço (RF-027; R3 garante que não muda).

O rodapé fixo (`ConfirmAnswerFooter`) ganha uma linha acima de "Anterior"/"Próxima": "Confirmar
resposta" (desativado sem escolha, `loading` durante o envio, com o `SlowRequestNotice` acima
quando demora) ou, se a pergunta já tem resultado nesta visita, "Responder de novo".

**Rationale**: um widget de alternativa só (Princípio II); o nome `MultipleChoiceWidget` do
`tasks.md` vira a lista de `LessonOptionCard` dentro da página, sem widget extra.

## R9. Voz no feedback

**Decision**: o painel recebe o `ReadAloudController` da página (um por tela). Texto lido
(extensão de apresentação, como o `spokenText` da lição): resultado, "Resposta correta: …",
explicação e pontuação, nessa ordem (clarificação Q4). Ao confirmar, a página para a leitura da
pergunta; ao abrir o painel com a leitura automática ligada, lê o feedback uma vez; ao fechar ou
seguir, para. A leitura automática da pergunta (B2) não repete ao marcar a lição como concluída,
porque o índice não muda (`_autoReadDone` continua `true`).

## R10. Testes

- Models: `AnswerResultModel` com e sem `explanation`; `ModuleDetailModel` lendo `progress`
  (`totalScore` 0 → sem pontuação).
- Datasource: `POST …/answer` com `{selectedOptionId}`, com e sem token, devolvendo o model.
- Registro: `recordAnswer` com `isCorrect`, `correctCount`, a mesma lição substitui; transferência
  continua mandando só a alternativa.
- Repositório: conta (não grava no registro); visitante (grava); `score` com conta e sem conta;
  códigos do R5 → `AnswerRejectedFailure`; rede → falha genérica.
- Usecase: resposta + pontuação; pontuação que falha não derruba o resultado.
- Controller: escolher, trocar, confirmar uma vez, sucesso (concluída, `canGoNext`, resultado,
  pontuação), falha comum (mantém escolha), rejeitada (recarrega), responder de novo, voltar a uma
  pergunta com resultado, toque depois do `dispose`.
- Widgets: `LessonOptionCard` (estados e semântica), rodapé, painel (acerto, erro, sem
  explicação, correta ausente, não fecha ao tocar fora, voltar fecha), página (fluxo completo como
  conta e visitante, última pergunta volta ao painel, voz no painel, letra 2×, inglês).
