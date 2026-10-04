# Research: Splash com sessão e onboarding

**Feature**: [spec.md](spec.md) · **Plan**: [plan.md](plan.md) · **Date**: 2026-10-04

Não restou nenhum NEEDS CLARIFICATION no Technical Context. As decisões abaixo resolvem as
escolhas de desenho levantadas ao ler o código atual.

## R1. O que o usecase de validação devolve

**Status**: confirmada pelo usuário em 2026-10-04.

**Decision**: `ValidateStoredSessionUseCase` chama `SessionValidationService.validateStoredSession()`
e devolve o `UserSessionStatus` **resultante** (`Future<UserSessionStatus> call()`). Ele recebe o
`SessionValidationService` e o `UserSessionService` (ambos do `common`, via GetIt).

**Rationale**:
- O controller precisa de duas coisas, a conferência e o estado da sessão depois dela, e só pode
  falar com usecases (Princípio I). Um único usecase entrega as duas, sem um segundo
  `GetSessionStatusUseCase` só para ler um getter (KISS).
- O serviço da feature 002 nunca lança e já decide sozinho entre manter e encerrar a sessão
  (CB-003/CB-014 ficam no `ApiClient`, ponto central exigido pelo Princípio V). O usecase só lê o
  estado depois dele, sem duplicar regra (FR-004).
- Por isso não há `Failure` possível para a UI distinguir: o resultado é sempre um estado. Um
  `Either<Failure, UserSessionStatus>` teria um `Left` que nunca acontece. A constituição exige
  que usecases **não lancem**, o que é garantido por um `try/catch` de proteção (FR-008): qualquer
  erro inesperado vira "devolver o estado atual da sessão".

**Alternatives considered**:
- `Future<Either<Failure, Unit>>` + ler `UserSessionService` no controller: viola o Princípio I
  (controller acessando serviço).
- Dois usecases (validar + ler estado): mais arquivos e testes para o mesmo resultado.

## R2. Paralelismo e ordem da decisão

**Decision**: o controller dispara ao mesmo tempo o atraso mínimo, a leitura da marcação do
onboarding e a validação da sessão, e espera os três (`Future.wait`). Depois decide:
onboarding não visto → `onboarding`; senão `authenticated`/`guest` → `home`; senão → `login`.

**Rationale**:
- Atende ao FR-002 (tudo em paralelo; o splash dura `max(mínimo, validação)`).
- Para visitante ou sem sessão, a validação retorna na hora (o serviço sai cedo se não está
  conectado), então o splash dura só o mínimo (FR-007, SC-003).
- Pior caso: mínimo de 2 s × prazo de 3 s do serviço (o `.timeout` envolve o `GET` inteiro,
  inclusive uma renovação de credencial disparada por ele) → cerca de 3 s, dentro dos 4 s do SC-003.
- Validar mesmo quando o onboarding não foi visto é inofensivo (a sessão já fica conferida para
  depois) e mantém o código sem ramificação.

**Alternatives considered**: validar só depois de ler o onboarding. Economiza um pedido no caso
raro de "primeira abertura com sessão", mas serializa as etapas e complica o teste.

## R3. Destino como enum, não string

**Decision**: `SplashDestination { onboarding, home, login }` em
`splash/presentation/controller/`, com o caminho da rota em cada valor. O controller expõe
`SplashDestination? destination`, e a página faz `context.go(destination.path)`.

**Rationale**: o Princípio V proíbe identificadores de estado como literais no fluxo de
controle. Os testes comparam valores do enum, não strings. O restante do app continua usando os
caminhos literais do go_router (padrão atual); padronizar rotas é escopo da F0.9.

**Alternatives considered**: manter `String? destinationRoute` (estado atual). Funciona, mas os
testes ficariam acoplados ao texto das rotas.

## R4. Dependência splash → onboarding

**Status**: aplicada em 2026-10-04 (aprovada pelo usuário no planejamento).

**Decision**: o splash continua usando `CheckOnboardingSeenUseCase`, já registrado no GetIt pelo
`OnboardingModule`, mas passa a importá-lo pelo barrel público `onboarding.dart` (que passa a
exportar esse usecase), e não pelo caminho interno `onboarding/domain/usecases/...`.

**Rationale**: o Princípio I proíbe importar a **implementação interna** de outro módulo e pede o
consumo via GetIt. A instância já vem do GetIt; só o tipo precisa ser visível, e o barrel é a API
pública do módulo (mesmo padrão previsto para o `NotificationBellButton` no plano do produto).
Ambos os módulos são da Trilha A.

**Alternatives considered**:
- Mover a leitura da marcação para um serviço do `common`: mexe em `common/` (Fase 0) por um
  único consumidor.
- Duplicar o repositório do onboarding no splash: viola o DRY.

## R5. Tempo mínimo injetável nos testes

**Decision**: `SplashController` recebe `minimumDisplayDuration` opcional no construtor (padrão
2 s, a constante atual). Os testes da tabela de decisão passam `Duration.zero`. O teste de
paralelismo roda em `testWidgets`, cujo relógio falso controla o `Future.delayed` do controller
(`tester.pump(Duration)`), e libera a validação por um `Completer`: com o mínimo ainda correndo e
a validação já liberada, o destino continua `null`; com o mínimo vencido e a validação pendente,
também; só com os dois resolvidos o destino aparece. Nenhuma espera real.

**Rationale**: os testes ficam rápidos e determinísticos (Princípio III), sem adicionar
`fake_async` como dependência direta.

**Alternatives considered**: `Future.delayed` real de 2 s nos testes, que deixaria a suíte lenta.

## R6. Frase de apoio no splash

**Decision**: nova chave `splash_tagline` ("Sua segurança em primeiro lugar" / "Your safety comes
first") em `AppStrings` e nos dois JSONs, exibida abaixo do nome com o estilo de texto pequeno e
opacidade reduzida, como no wireframe. Um teste de chaves (no padrão do
`i18n_keys_test.dart` da feature 003) cobre os prefixos `splash_` e `onboarding_`.

**Rationale**: FR-011 e Princípio IV (sem texto fixo em widget).

## R7. O onboarding fica como está

**Decision**: nenhuma mudança de comportamento no `OnboardingController` nem na
`OnboardingPage`. Só testes: controller (avançar, deslizar, terminar, pular, falha ao gravar) e
um widget test da página (rótulo do botão no último slide, "Pular" e "Começar" levam a `/login`).

**Rationale**: o código já atende ao RF-002/RN-004 (FR-009, FR-010). Escopo enxuto pedido pelo
usuário.

**Observação sobre a cor do 3º slide**: o wireframe usa `#607698` e o app usa
`AppColors.textMutedForeground` (`#596475`). Diferença pequena, mantida para não criar um token
novo por um único uso (registrado em Assumptions da spec).
