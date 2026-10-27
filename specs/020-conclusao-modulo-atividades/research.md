# Research: Conclusão do módulo e aviso de login

**Feature**: [spec.md](spec.md) · **Plan**: [plan.md](plan.md) · **Date**: 2026-10-27

As decisões de produto estão na seção Clarifications da spec. As abaixo saem do código das
features 003 (login/cadastro), 007 (compartilhar), 015 (painel e transferência do visitante), 017
(perguntas) e 018 (resposta e pontuação).

## R0. Nada novo no serviço

**Decision**: a B4 não faz pedido novo. A pontuação já está no `LessonController` depois da
última resposta (`score`, specs/018 R3): do serviço com conta, do registro sem conta.

**Rationale**: SC-001 (conclusão em até 1 s, sem esperar o serviço); o contrato 1.1.2 não muda.

## R1. Quando o módulo está concluído

**Decision**: o `LessonController` ganha `isModuleCompleted` = todas as lições válidas
`isCompleted`. Na última pergunta, o painel de feedback mostra "Ver resultado" quando
`isModuleCompleted`, senão "Voltar às atividades" (B3).

**Rationale**: a mesma regra do serviço (`progress.isCompleted`) e do visitante (RN-005: todas
respondidas). Ler `progress.isCompleted` do serviço exigiria mais um campo e um pedido; a lista
na tela já tem a resposta, para conta e visitante.

## R2. Tela de conclusão como rota empilhada sobre as perguntas

**Decision**: `CompletionPage` numa rota filha `/activities/:moduleId/done`, aberta pela
`LessonPage` com `context.push<CompletionAction>(…, extra: ModuleCompletion)`. Ela devolve a
ação: `redo` → a `LessonPage` recarrega o módulo (`load`, que abre na primeira pergunta porque
todas estão respondidas, B2); `finish` ou voltar do aparelho (`null`) → a `LessonPage` faz
`context.pop()` e a pessoa chega ao painel, que recarrega pelo `RefreshOnReturnMixin` (B1), como o
"Voltar às atividades" da B3.

Sem `extra` (rota aberta direto, ex.: restauração do app), a página volta às atividades.

**Rationale**: a navegação continua com quem já a controla (a `LessonPage`), sem `go` que
recrie páginas; "Refazer" não precisa de rota nova. O voltar do aparelho na conclusão nunca
reabre a última pergunta (FR-005).

**Alternatives considered**: `pushReplacement` da `LessonPage` pela conclusão (o `push` do
painel completaria cedo e a recarga do painel ficaria fora de hora); a conclusão como estado da
própria `LessonPage` (mistura duas telas num widget só).

## R3. Aviso do visitante

**Decision**: `showGuestProgressAlert(context)` (folha modal, padrão do convite de conta do
shell), aberta pela `LessonPage` antes da conclusão quando a sessão não tem conta. Devolve
`GuestAlertAction.createAccount`, `.continueWithoutAccount` ou `null` (voltar = continuar).

"Criar conta" → `context.push('/login?mode=register&next=/activities')`. Se a pessoa entrar, a
página de login vai para `/activities` (R4) e a pilha das perguntas sai. Se voltar sem entrar, o
`push` termina e a `LessonPage` segue para a conclusão, como visitante.

**Rationale**: FR-007 a FR-009 e a clarificação 1; quem decide "com conta ou não" é a sessão
(`UserSessionService.isAuthenticated`), como no resto das atividades; o aviso não chama a rede.

**Alternatives considered**: reaproveitar o `AccountRequiredSheet` do shell (outro texto e
outros botões; e o `activities` não importa o `shell`).

## R4. Login que abre em "Criar conta" e volta para Atividades

**Decision**: a rota `/login` lê dois parâmetros opcionais: `mode=register` (abre no modo de
cadastro) e `next` (para onde ir ao entrar, só caminho interno começando com `/`; o resto é
ignorado). `LoginPage({AuthMode initialMode, String? next})`: depois do `reset()` do primeiro
quadro, aplica o modo; ao entrar, `context.go(next ?? '/home')`. Sem parâmetros, nada muda para
as outras telas.

A transferência do progresso para a conta nova continua a da B1 (`startedFromSignUp` →
`GuestProgressStore.onSignUp` → envio); a aba Atividades recarrega ao aparecer
(`RefreshOnReturnMixin`) e mostra o módulo concluído (SC-004).

**Rationale**: menor mudança no módulo `authentication` (do Arthur também): dois parâmetros
opcionais, sem acoplamento ao `activities` (só um texto de rota). Vale também para quem troca
para "Entrar" nessa tela (spec, FR-008).

**Alternatives considered**: tela de cadastro separada (duplicaria a 003); guardar "voltar para"
num serviço global (estado escondido).

## R5. Resultado e mensagem

**Decision**: `ModuleCompletion {title, score?}` (apresentação, montado pela `LessonPage`).
Extensão de apresentação com:

- faixa da mensagem: `ModuleCompletionTier { perfect, good, retry }` — todas certas; pelo menos
  metade; menos da metade (sem pontuação → `good`, mensagem neutra de parabéns);
- texto falado: título, pontuação e mensagem;
- texto para compartilhar: com ou sem números, com `AppIdentity.name`.

**Rationale**: textos por chave (Princípio V), regra testável sem widget.

## R6. Compartilhar

**Decision**: `ShareService.shareText(text, subject: título)` do `common`, como o detalhe da
notícia: cancelar/falhar não mostra nada; um toque por vez (`_sharing` na página).

## R7. Voz na conclusão

**Decision**: um `ReadAloudController` (GetIt, factory) na `CompletionPage`, como nas perguntas:
`prepare(locale)`, leitura automática uma vez ao abrir se `autoReadAloud` e voz disponível,
`ListenButton` "Ouvir"/"Parar", `dispose` ao sair (para a leitura). O aviso do visitante não é
lido sozinho (spec, Assumptions).

## R8. Layout

**Decision**: `CompletionPage`: `AppBar` com o título do módulo; conteúdo rolável e centrado:
ícone grande de troféu (`LucideIcons.trophy`, `colors.success`), "Módulo concluído!" (20/700,
`liveRegion`), "Você acertou X de Y" (18/700) quando houver, mensagem da faixa (16),
`ListenButton`; botões: "Voltar às atividades" (primário), "Compartilhar" e "Refazer o módulo"
(secundários). Aviso do visitante: título (18/700), texto (16), "Criar conta" (primário) e
"Continuar sem conta" (secundário), rolável com letra grande.

## R9. Testes

- Controller: `isModuleCompleted` (conta e visitante; falso com uma não respondida).
- Extensão: faixas (3/3, 2/3, 1/3, sem pontuação), texto falado, texto de compartilhar com e sem
  pontuação.
- Login: `/login?mode=register&next=/activities` abre em "Criar conta" e, ao cadastrar, vai para
  `/activities`; `next` externo é ignorado; sem parâmetros, como antes (`/home`).
- Painel de feedback: rótulo "Ver resultado" com o módulo concluído.
- Aviso: textos, ações, voltar = continuar.
- Conclusão: conteúdo, sem pontuação, compartilhar (fake: texto e toque duplo), refazer, voltar,
  voz (fake), letra 2×, inglês.
- Página das perguntas: conta → conclusão sem aviso; visitante → aviso → continuar → conclusão;
  visitante → criar conta → login no modo cadastro; refazer abre a primeira pergunta.
