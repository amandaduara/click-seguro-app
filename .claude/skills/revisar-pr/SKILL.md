---
name: "revisar-pr"
description: "Revisa um ou mais PRs abertos do Click Seguro (código morto, código desnecessário ou complexo demais, padrões e arquitetura do projeto, mudança mínima, testes) e entrega um relatório em português, sem comentar no GitHub sem autorização."
argument-hint: "Número(s) do PR (ex.: 20 21). Vazio = todos os PRs abertos de outras pessoas."
user-invocable: true
disable-model-invocation: false
---

## Entrada

```text
$ARGUMENTS
```

Números de PR separados por espaço. Vazio: revisar todos os PRs abertos para `develop` cujo autor
não é quem está rodando a revisão (comparar `gh api user --jq .login` com
`gh pr list --state open --json number,author,baseRefName`).

## Objetivo

Garantir que cada PR:

1. **não traga código morto** (classes, métodos, parâmetros, campos, getters, chaves de i18n,
   imports, assets ou dependências que nada usa) **nem código que só existe para teste** em `lib/`
   (ex.: parâmetro só para injetar em teste, `Key` pública só achada em teste, `toJson` sem uso);
2. **não traga código desnecessário ou complexo demais** (abstração sem segundo uso, duplicação de
   algo que já existe em `core/`, `common/` ou outro widget, estado redundante, lógica que o
   serviço ou um widget pronto já resolve);
3. **siga os padrões e a arquitetura do projeto**;
4. **mude o mínimo possível** fora do escopo da tarefa;
5. **tenha testes** que provem o comportamento, e deixe `flutter analyze` e `flutter test` como
   estavam (sem avisos novos, tudo verde).

A revisão é **somente leitura**: não altere a branch do PR, não faça commit nem push.

## Passos

### 1. Contexto do projeto (ler sempre, porque pode ter mudado)

- `.specify/memory/constitution.md`: princípios I–V e regras globais (arquitetura em módulos
  `data → domain → presentation`, controller só fala com usecases, módulos não se importam exceto
  pelo barrel público ou `common`, SOLID/DRY/KISS, TDD, `Either<Failure, T>`, sem strings soltas,
  i18n por chave).
- `click_seguro_app/ENDPOINT_INTEGRATION_CONTEXT.md`: como integrar endpoints (`ApiClient` por
  composição, datasource lança `ApiException`, repository converte em `Failure`).
- `.specify/memory/tasks.md` e `.specify/memory/specification.md`: a tarefa que o PR diz cumprir,
  seus RF/RN, e o que está **fora da v1** (seção Notas).
- `.specify/memory/plan.md`: mapa de módulos, rotas e dependências permitidas entre módulos.
- `.specify/memory/api-contract.md`: endpoints, formatos e status (🧪/✅/⏸️).

### 2. Dados do PR

```bash
gh pr view <n> --json number,title,author,headRefName,baseRefName,body,additions,deletions,changedFiles,commits
gh pr diff <n> --name-only
gh pr diff <n>
```

- Base deve ser `develop`.
- Para PRs grandes, ler o diff por pastas (`lib/` primeiro, depois `test/`, depois o resto) e
  delegar pastas a subagentes se fizer sentido, pedindo a eles o mesmo checklist.

### 3. Rodar analyze e testes sem tocar na branch local

Usar um worktree temporário no scratchpad (nunca trocar a branch do diretório de trabalho):

```bash
git fetch origin pull/<n>/head:pr-<n>-review
git worktree add <scratchpad>/pr-<n> pr-<n>-review
cd <scratchpad>/pr-<n>/click_seguro_app && flutter pub get && flutter analyze && flutter test
# no fim:
git worktree remove <scratchpad>/pr-<n> --force && git branch -D pr-<n>-review
```

Comparar com a `develop` (rodar o mesmo na `develop` ou usar a linha de base mais recente
anotada no `tasks.md` da última feature). Avisos novos ou testes vermelhos são achados.

### 4. Checklist (anotar cada achado com arquivo:linha)

**A. Código morto e código só para teste**
- Para cada símbolo público novo em `lib/` (classe, método, getter, parâmetro opcional, campo,
  constante, chave de `AppStrings`, asset, dependência no `pubspec.yaml`), procurar usos em `lib/`
  (`git grep` no worktree). Uso só em `test/` = código só para teste.
- Chave de i18n nova sem uso, ou texto presente em só um dos JSON (`pt-BR`/`en-US`).
- Arquivos de `lib/dev/` ou atalhos de desenvolvimento esquecidos.
- `TODO`, código comentado, `print`/`debugPrint` soltos.

**B. Desnecessário ou complexo demais**
- Algo que já existe e foi recriado: comparar com `lib/core/widgets/` (`Safe*`, `SlowRequestNotice`,
  `RefreshOnReturnMixin`…), `lib/core/theme/`, `lib/modules/common/` (serviços, `ApiClient`,
  `LocalCacheService`, `UserSessionService`), e widgets de outros módulos que deveriam ter sido
  movidos para `core`.
- Camadas ou classes sem motivo (interface com uma implementação e nenhum fake; usecase que só
  repassa é aceito pelo padrão do projeto, não marcar).
- Estado duplicado, `setState` + controller juntos, lógica de domínio em widget ou controller.
- Métodos longos ou aninhamento profundo que dariam para simplificar sem mudar comportamento.

**C. Padrões e arquitetura**
- Pastas `data/`, `domain/`, `presentation/` (nunca `ui/`); nomes `snake_case.dart`; sufixos
  (`…Entity`, `…Model`, `…Repository`, `…RepositoryImpl`, `…UseCase`, `…Controller`, `…Page`).
- Datasource usa o `ApiClient` (composição, constantes de caminho); repository pega `ApiException`
  e devolve `Either<Failure, T>`; usecases e repositories nunca lançam.
- Controller estende `ChangeNotifier` e só chama usecases (nem datasource, nem `Dio`, nem
  serviço de plataforma fora do que a constituição permite).
- DI pelo `GetIt` no `XxxModule.registerServices`; telas pegam controller via `provider`/`GetIt`
  como o resto do projeto.
- Módulo importando outro módulo fora do barrel público ou de `common` = violação.
- Textos visíveis por `AppStrings` + `tr()`, nas duas línguas; erros como `Failure` com chave de
  mensagem; códigos de erro e estados em `enum`/constantes.
- Acessibilidade (RNF-003/004): alvos ≥ 48 dp, texto base ≥ 16 sp, `Semantics` nos elementos
  interativos, cores por `context.colors` (alto contraste da B9), teste com letra 2×.
- Endpoints usados existem no `api-contract.md`; se o PR usa algo **fora da v1** ou muda o
  contrato, apontar.
- Spec Kit: o PR deve ter `specs/NNN-…/` (spec, plan, tasks…) com número sem colisão com outra
  feature, e marcar a tarefa no `.specify/memory/tasks.md`.

**D. Mudança mínima**
- Listar arquivos fora do módulo da tarefa (`core/`, `common/`, `main.dart`, roteador, outros
  módulos, `pubspec.yaml`, `.specify/memory/*`). Para cada um: a mudança é necessária para a
  tarefa? Está justificada no plano/PR? Muda comportamento de outra feature?
- Reformatação, renomeação ou refatoração não pedida em arquivos alheios = achado (baixo).
- Dependência nova no `pubspec.yaml` sem justificativa (constituição IV).

**E. Testes**
- Toda regra nova em `lib/` tem teste; widgets novos com widget test (estado de erro e de
  sucesso nas telas com API); testes offline (fakes, `FakeHttpClientAdapter`), `GetIt` resetado.
- Testes que só repetem a implementação, ou que testam código morto.

### 5. Relatório (em português, por PR)

```markdown
## PR #<n> — <título> (<autor>)

**Veredito:** Aprovar | Aprovar com ajustes | Pedir mudanças
**Resumo:** 2–3 frases.
**analyze/test:** <x> issues (develop: <y>) · <n> testes verdes / <m> falhas

| # | Severidade | Categoria | Arquivo:linha | Problema | Sugestão |
|---|---|---|---|---|---|
| 1 | Alta/Média/Baixa | morto / desnecessário / padrão / arquitetura / escopo / teste | … | … | … |

**Fora do escopo do PR** (arquivos alheios tocados): lista curta com "ok" ou "rever".
**Pontos positivos:** 1–3 itens.
```

Severidade: **Alta** = viola a constituição, quebra outra feature, teste vermelho, endpoint fora da
v1 sem decisão; **Média** = código morto/só para teste, duplicação, padrão não seguido, mudança
alheia sem justificativa; **Baixa** = estilo, nome, simplificação opcional.

Só reportar achados verificados no código (abrir o arquivo, procurar o uso). Na dúvida, marcar
"a confirmar" em vez de afirmar.

### 6. Comentários no GitHub

**Nunca** publicar comentário ou review sem a pessoa que pediu a revisão autorizar. Depois do relatório, perguntar se
quer publicar e em que forma (um comentário geral com o relatório, ou comentários por linha).
Se sim: `gh pr review <n> --comment --body-file <arquivo>` (nunca `--approve`/`--request-changes`
sem pedido explícito).
