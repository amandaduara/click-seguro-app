# Research: Perfil

**Feature**: [spec.md](spec.md) · **Plan**: [plan.md](plan.md) · **Date**: 2026-10-12

Sem NEEDS CLARIFICATION: as decisões de produto estão na seção Clarifications da spec (redesign do
Figma, e-mail e telefone). As decisões abaixo saem da conferência no servidor (R0), do código das
features 005, 007, 009, 010 e 011 e do plano do produto.

## R0. Conferência no servidor real (portão de API)

Feita em 2026-10-12 com contas de teste novas (`teste.claude.20261012@exemplo.com`, `…b`, `…c`;
senhas não guardadas, criadas com autorização da usuária). O servidor já tem **3 módulos** de
atividades (9 lições).

| Pedido | Resultado |
|---|---|
| `GET /users/me` | ✅ `{name, email, phone (null), role, receiveNotifications, avatarUrl (null)}` |
| `PATCH /users/me` nome, telefone, `receiveNotifications` | ✅ 204; o `GET` seguinte reflete |
| `PATCH` nome com 3 letras / telefone sem `+55` | ✅ 400 `VALIDATION_ERROR` com `errors[{field, message}]` |
| `PATCH` `phone: null` ou `""` | ⚠️ 400: **o telefone salvo não pode ser apagado** |
| `PATCH` com `email` (e-mail novo, o próprio ou o de outra conta) | ❌ **500 `INTERNAL_SERVER_ERROR` sempre** (o contrato prevê 409 `USER_EMAIL_ALREADY_EXISTS`). Bug do servidor, backend avisado |
| `POST /users/me/avatar` (PNG, campo `avatar`) | ✅ **200** `{avatarUrl}` (não 201); o `GET` passa a trazer a URL (com transformação do Cloudinary) |
| `POST /users/me/avatar` (texto) | ✅ 400 `INVALID_IMAGE_TYPE` |
| `DELETE /users/me/avatar` | ✅ 204, também quando já não há foto |
| `GET /users/me/news/{read,liked,saved}?limit=1` | ✅ `{data[], meta{page, limit, total, totalPages, hasNextPage, hasPreviousPage}}`; item = o da lista de salvas (`id, title, source, sourceUrl, imageUrl, publishedAt, originalPublishedAt, categories, interaction`) |
| `GET /app/educational/modules` | ✅ `{modules[{id, title, description, order, iconUrl?, lessonsCount, completedCount, progressPercent}], totalLessonsCompleted, totalLessonsAvailable}`, também sem conta (zerado) |

Efeitos: a notícia `cmuywjppz…` ganhou leituras das contas de teste; a curtida foi desfeita.

**Decision**: contrato da API → **1.0.8** (feito junto com este plano). E-mail continua editável
(clarificação): o 500 vira falha genérica e o 409 do contrato já fica tratado para quando o
backend corrigir. Telefone: sem opção de apagar.

## R1. Módulo `profile` e de onde vêm os dados

**Decision**: o módulo `profile` ganha `data` e `domain` próprios, com **um** datasource remoto
(`ProfileRemoteDataSource`) que fala com `GET/PATCH /users/me`, `POST/DELETE /users/me/avatar`,
`GET /users/me/news/{read,saved,liked}?limit=1` (só o `meta.total`) e `GET
/app/educational/modules`. Não importa `news`, `activities` nem `notifications`.

**Rationale**: o plano do produto (§4) e o contrato já decidiram "datasource próprio, sem importar
outros módulos". Os alertas (feature 011) fizeram o mesmo para `receiveNotifications`. Os três
totais saem em paralelo.

**Alternatives considered**: reaproveitar o `UserModel` do `authentication` (importaria outro
módulo) ou os usecases de salvas do `news` (idem). Um repositório de "conta" em `common` foi
rejeitado: só o perfil usa estes dados (a B8 usará o mesmo módulo pela rota `/profile/edit`).

## R2. Carga do perfil com falha parcial

**Decision**: três usecases independentes — `GetProfileUseCase` (perfil), `GetNewsCountsUseCase`
(lidas/salvas/curtidas) e `GetActivityProgressUseCase` (módulos) — chamados em paralelo pelo
`ProfileController`, que guarda um estado por área:

- perfil falhou → tela inteira em erro com "Tentar novamente" (FR-006);
- perfil ok e números falharam → aviso só no lugar dos números;
- conquistas precisam dos números (leituras) **e** do progresso; se algum falhar → aviso só no
  lugar das conquistas.

**Rationale**: a spec pede aviso só na área que falhou (US1 cenário 9). Um único usecase
"carregar tudo" esconderia isso.

## R3. Conquistas (RN-008)

**Decision**: regra pura no domínio, `AchievementsCalculator.build(readCount, progress)` →
`List<AchievementEntity>` já ordenada (FR-008/FR-009):

- fixas, na ordem da tabela: `firstLesson` (1 lição), `firstModule` (1 módulo), `dedicatedStudent`
  (10 lições), `securityMaster` (todos os módulos; só com ≥ 1 módulo), `attentiveReader` (1 lida),
  `dedicatedReader` (10 lidas); `AchievementKind` enum;
- uma por módulo com `lessonsCount > 0`: alcançada com `completedCount == lessonsCount`;
- "módulo concluído" = `completedCount >= lessonsCount` e `lessonsCount > 0`;
- ordem: alcançadas primeiro; depois maior proporção de progresso; empate → ordem da tabela e,
  entre módulos, `order` do serviço.

Nomes e textos ("8 de 10 lições") ficam numa extension de apresentação. As cores e ícones das
medalhas também (fixas por tipo; as de módulo alternam entre as cores do design system).

**Rationale**: regra de negócio testável sem tela (Princípio III).

## R4. Atualizar ao voltar à aba (FR-007)

**Decision**: o `ProfilePage` ouve o `GoRouter` (`routerDelegate`, um `ChangeNotifier`). Quando o
caminho atual volta a ser `/profile` (vindo de outro), chama `controller.refresh()` — recarrega
sem trocar a tela por "carregando" (os números atualizam no lugar). Também chama ao voltar de
`/profile/edit`, `/news/{saved,read,liked}` e `/profile/achievements`.

**Rationale**: o `StatefulShellRoute.indexedStack` (feature 005) mantém a aba viva, então ela não
é reconstruída ao voltar. Ouvir o roteador não exige mudar o `shell`.

**Alternatives considered**: um aviso de "aba selecionada" no `AppShell` (mexe no `shell`, de
outra feature); recarregar só no `initState` (números ficariam velhos).

## R5. Editar perfil

**Decision**:

- `EditProfileController` com o rascunho (nome, e-mail, telefone), o original, `canSave`
  (algo mudou), erros por campo e `save()`.
- Validação no domínio (`ProfileFormValidator`): nome 6–150 sem espaços das pontas; e-mail com
  formato válido (mesma expressão do `CredentialsValidator`, copiada com comentário, porque o
  Princípio I proíbe importar o `authentication`); telefone: só dígitos de 10 ou 11 (aceita
  máscara e "+55"), enviado como `+55…`; vazio permitido **só** se o original era vazio
  (clarificação).
- `UpdateProfileUseCase` envia **só o que mudou** (FR-013); e-mail em minúsculas e sem espaços.
- Falhas: 409 `USER_EMAIL_ALREADY_EXISTS` → `EmailInUseFailure` (erro no campo de e-mail); 400
  `VALIDATION_ERROR` → erro no campo indicado em `errors[].field` quando for `name`, `email` ou
  `phone`; demais (incluindo o 500 do e-mail, R0) → `ServerFailure`/`ConnectionFailure`, com
  "Não foi possível salvar. Tente de novo mais tarde." e o rascunho mantido.
- Sucesso: `UserSessionService.updateProfile(name, email)` e "Dados salvos".
- Sair com alterações: `PopScope` + diálogo "Descartar alterações?" (FR-016).

## R6. Saudação atualizada (SC-003)

**Decision**: `UserSessionService` ganha `ValueListenable<int> profileVersion` (incrementado em
`updateProfile`); o `AppTopBar` passa a ouvir `sessionStatus` **e** `profileVersion` (um
`Listenable.merge`).

**Rationale**: hoje o `AppTopBar` só reconstrói quando o estado da sessão muda, e o nome salvo só
apareceria depois de outra mudança. É uma mudança pequena em `common` e `shell` (Fase 0 fechada):
justificada no Constitution Check, com teste.

**Alternatives considered**: `UserSessionService` virar `ChangeNotifier` (mudaria todos os
ouvintes atuais); recarregar o `/users/me` no Início (pedido a mais a cada abertura).

## R7. Foto

**Decision**: na tela de edição, tocar na foto abre uma folha com "Galeria", "Câmera" e, se houver
foto, "Remover foto". A escolha usa o `ImageStorageService` (F0.5, já reduz para 1024 px e copia
para a pasta do app); o arquivo é enviado com `ApiClient.postMultipart(fieldName: 'avatar',
contentType: image/jpeg|png|webp pela extensão)`. Enquanto envia, mostra a foto local com um
indicador; em sucesso usa a `avatarUrl` devolvida e **apaga a cópia local**; em falha volta à foto
anterior e mostra a mensagem. "Remover foto" pede confirmação e chama o `DELETE`. Sem permissão →
folha com a explicação de como liberar nas configurações do aparelho (CB-010).

## R8. Listas de lidas e curtidas (US4)

**Decision**: generalizar a lista de salvas da feature 010 no módulo `news`, dono de
`/users/me/news/*`:

- `NewsListKind { saved, read, liked }` com caminho, título, textos de vazio e uso de cópia
  (só `saved` guarda cópia, RNF-002);
- datasource/repository/usecase `getUserNewsList(kind, page)`; o caminho de salvas continua
  igual, com a cópia;
- o `SavedNewsController` vira `UserNewsListController(kind, …)` sem mudar o comportamento;
- rotas `/news/read` e `/news/liked` antes de `/news/:id`, como `/news/saved`;
- a página recebe o `kind` para título e vazio.

**Rationale**: mesma tela, sem cópia de código (Princípio II). O perfil só navega para as rotas.

**Risco de conflito**: mexe em arquivos da feature 010 (do outro desenvolvedor). Avisar antes de
começar; os testes de salvas existentes têm de continuar passando sem mudança de comportamento.

## R9. Conquistas: "Ver todas" e visitante

**Decision**: "Ver todas" abre `/profile/achievements` (navegador raiz), uma lista de cartões de
medalha em grade de 2 colunas, na mesma ordem. O visitante vê na aba o convite do quadro "Perfil —
visitante" (sem chamar o serviço), com "Entrar ou criar conta" → `/login`.

## R10. Testes

**Decision**: models com o JSON real da R0; datasource com `FakeHttpClientAdapter`; repository
(sucesso, 409, 400 por campo, 500, conexão); `AchievementsCalculator` (cada regra, ordem, sem
módulos, módulo sem lições); validador do formulário; controllers (carga parcial, refresh, salvar,
foto); widget tests das páginas (conta, visitante, erro parcial, fonte 2×, alvos ≥ 48); testes de
salvas da 010 continuam verdes e ganham os casos `read`/`liked`; `AppTopBar` mostra o nome novo
depois do `updateProfile`.
