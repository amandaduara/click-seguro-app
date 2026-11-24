# Research: Perguntas do módulo de atividades

**Feature**: [spec.md](spec.md) · **Plan**: [plan.md](plan.md) · **Date**: 2026-10-21

As decisões de produto estão na seção Clarifications da spec. As abaixo saem do código das
features 007, 009, 010, 014 e 015, do contrato da API 1.0.10 e da conferência no servidor (R0).

## R0. Conferência no servidor real

Feita em 2026-10-19 (conta de teste da B1, specs/015 R0) e repetida em 2026-10-21 como visitante:

| Pedido | Resultado |
|---|---|
| `GET /app/educational/modules/{id}` sem token | ✅ 200 `{id, title, description, order, iconUrl, lessonsCount, lessons[], progress{completedCount, progressPercent, score, totalScore, isCompleted}}` |
| `lessons[]` | `{id, order, question, explanation, imageUrl, options[{id, text}], isCompleted}`; módulo 1: 3 lições, com 4, 3 e 3 alternativas, todas com imagem; `isCompleted` falso para o visitante |
| Com conta (B1 R0) | `isCompleted` verdadeiro nas lições respondidas, certas ou erradas |
| Alternativa correta | não vem no detalhe (só no resultado da resposta, B3) |

**Decision**: nada novo no contrato além do 1.0.10. A `explanation` vem junto, mas **não é lida**
nesta feature (FR-016); a B3 usa a do resultado da resposta.

## R1. Onde fica: módulo `activities`

**Decision**: tudo no `activities` (criado na B1): `getModuleDetail` no mesmo datasource e
repositório; usecase e controller novos; `LessonPage` substitui a `ActivityModulePage` provisória
na rota `/activities/:moduleId` (que já existe, sobre as abas).

**Rationale**: mesmo endpoint-base, mesmo registro do visitante (`GuestProgressStore`), e a B3/B4
continuam aqui.

## R2. Entidades só com o que a B2 usa

**Decision**: `ModuleDetailEntity {id, title, lessons}` e `LessonEntity {id, order, question,
imageUrl?, options, isCompleted}` com `LessonOptionEntity {id, text}`. **Ficam de fora** a
`explanation` e o `progress` do módulo (`score`, `totalScore`, `isCompleted`): a B2 não os usa, e a
revisão do PR #22 pediu para não deixar campo sem uso; a B3/B4 acrescentam quando forem usar. O
model ordena as lições por `order` e descarta as com menos de 2 alternativas (CB-012); alternativas
ficam na ordem recebida (RF-027).

**Alternatives considered**: `ModuleProgressEntity` já agora, como diz o `tasks.md` (seria código
morto até a B3/B4).

**Revisão da branch (2026-10-22)**: saiu também o `id` do `ModuleDetailEntity` (a tela usa o da
rota). Ficam o `LessonOptionEntity.id`, que a B3 usa para responder, e o `LessonEntity.order`,
usado para ordenar no model (mesmo padrão do `ModuleSummaryEntity`).

## R3. "Respondida" para conta e para visitante

**Decision**: com conta, `LessonEntity.isCompleted` vem do serviço. Sem conta (visitante ou sessão
expirada, como na B1), o repositório troca pelo registro da sessão: `GuestProgressStore` ganha
`isAnswered(String lessonId)`. O `answeredCount` da B1 continua.

**Rationale**: a regra "sem conta = registro da sessão" fica num lugar só (repositório), igual ao
painel.

## R4. Navegação guiada

**Decision**: `LessonController` com `currentIndex`, `canGoPrevious` (índice > 0) e `canGoNext`
(lição atual respondida e não é a última). `goNext`/`goPrevious` ignoram toque quando não podem
(toques rápidos). Começa na primeira lição não respondida; todas respondidas → 0. A B3 vai marcar a
lição atual como respondida depois da resposta; **nada disso entra agora** (sem método só para a
B3).

**Rationale**: clarificação de 2026-10-21 (avançar só depois de responder). Regra no controller,
testável sem widget.

## R5. Leitura em voz alta: botão compartilhado

**Decision**: extrair do `ReadAloudBar` (módulo `news`, feature 010) o botão "Ouvir"/"Parar" para
`core/widgets/listen_button.dart` (`ListenButton`), com textos `common_listen`/`common_stop`. O
`ReadAloudBar` passa a usar o `ListenButton` (mesmo visual e semântica; os testes da notícia
continuam) e as chaves `news_detail_listen`/`news_detail_stop` saem. A `LessonPage` usa só o
`ListenButton`: a velocidade é a da Acessibilidade (B9), sem seletor na tela.

O `ReadAloudController` (`common`) é usado como na notícia: um por página, `prepare(locale)` no
`didChangeDependencies`, `stop()` ao trocar de pergunta, `dispose` ao sair.

Texto lido: enunciado + cada alternativa como "Alternativa 1: …" (`activities_lesson_option_spoken`),
numa só leitura.

**Rationale**: Princípio II (sem copiar o botão) e Princípio I (o `activities` não importa o
`news`). O seletor de velocidade da notícia fica onde está (só a notícia o usa).

**Alternatives considered**: mover o `ReadAloudBar` inteiro para o `core` (leva junto o seletor que
a B2 não usa e mais strings da notícia); copiar o botão no `activities` (duplicação).

## R6. Leitura automática

**Decision**: como na notícia (feature 010): a página ouve o controller e o `ReadAloudController`;
quando a lição atual está carregada, a voz está pronta, a preferência `autoReadAloud` está ligada e
aquela lição ainda não foi lida sozinha, lê e marca. O controle "já lida sozinha" é por índice
(`Set<int>` na página); trocar de pergunta para a leitura anterior e permite a automática da nova.

**Revisão da branch (2026-10-22)**: a revisão achou um defeito no `ReadAloudController.stop()`
(`common`): ele avisava "parado" antes de mandar o motor parar, e a leitura automática da pergunta
nova (que começa nesse aviso) era cancelada pelo próprio parar. Agora o motor recebe o "parar"
primeiro; o detalhe da notícia também se beneficia. A cadeia de condições da leitura automática
continua parecida com a da notícia (duas páginas); levar um "ler uma vez por chave" para o
controller fica como melhoria futura.

**Validação no aparelho (2026-10-22)**: a regra inicial ("cada pergunta é lida sozinha uma vez
por visita") atrapalhou: ao voltar e avançar de novo, a pergunta não era lida. Agora a leitura
automática acontece cada vez que uma pergunta aparece na tela (`_autoReadDone` volta a `false` a
cada troca), sem repetir enquanto ela continua na tela.

## R7. Estados

**Decision**: `LessonStatus { loading, loaded, empty, error }`; `empty` = módulo sem lições
válidas **ou** 404 `EDUCATIONAL_MODULE_NOT_FOUND` (vira `ModuleNotFoundFailure`, falha do domínio
do `activities`); carregando com `SlowRequestNotice` (como a B1); erro com `SafeErrorState`.

## R8. Layout

**Decision**: `AppBar` com o título do módulo; abaixo, "Pergunta X de Y" e uma fileira de marcas
(uma por pergunta: concluída com check, atual destacada, demais vazias; a fileira quebra linha com
letra grande e é um item só para o leitor de tela: "Pergunta 2 de 3, 1 concluída"). Conteúdo rolável:
imagem (`Image.network`, altura máxima 220, `errorBuilder` → nada), enunciado (`titleMedium`
18/700), alternativas numeradas em cartões (não tocáveis na B2; a B3 os torna escolha) e o
`ListenButton`. Rodapé fixo com "Anterior" e "Próxima" (`SafeButton`, desativados conforme o
controller).

## R9. Testes

- Models: JSON real do R0; ordena por `order`; lição com 1 alternativa descartada; alternativas na
  ordem recebida; `explanation` ignorada.
- Datasource: `GET /app/educational/modules/{id}` com e sem token.
- Registro: `isAnswered`.
- Repositório: conta (do serviço), visitante (do registro), 404 → `ModuleNotFoundFailure`.
- Controller: início na primeira não respondida; anterior/próxima; próxima bloqueada sem resposta;
  limites; estados.
- Página: conteúdo, posição, marcas, navegação, imagem que falha, "Ouvir"/"Parar" com leitor de voz
  falso (texto lido), leitura automática a cada vez que a pergunta aparece, sem voz, estados, letra 2×, inglês.
- `ListenButton` e a notícia: os testes do detalhe da notícia continuam verdes.
