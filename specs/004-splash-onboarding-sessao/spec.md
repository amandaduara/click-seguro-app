# Feature Specification: Splash com sessão e onboarding

**Feature Branch**: `004-splash-onboarding-sessao`

**Created**: 2026-10-04

**Status**: Draft

**Input**: User description: "A1 Splash + onboarding (RF-001, RF-002, RN-004): testes e ajuste do SplashController (onboarding não visto → /onboarding; sessão authenticated/guest → /home; senão /login), ValidateStoredSessionUseCase em lib/modules/splash/domain/usecases/ delegando ao SessionValidationService (feature 002), executado em paralelo com o tempo mínimo do splash (conta desativada → /login), testes do OnboardingController e conferência de textos/slides com o wireframe. Observação do usuário: o onboarding e o splash já existem, então o escopo deve ser enxuto (ajustes, testes e a validação da sessão)."

**Rastreabilidade**: tarefa A1 · RF-001, RF-002, RN-004, CB-003, CB-014 da
[especificação do produto](../../.specify/memory/specification.md) v2.1.0 · usa a sessão e a
validação na abertura das features [001](../001-sessao-persistente-visitante/spec.md) e
[002](../002-apiclient-renovacao-sessao/spec.md) (FR-008) · visual:
`wireframe/src/components/screens/OnboardingScreen.tsx`.

## Contexto: o que já existe

O splash e o onboarding já estão no app: a tela de abertura com o escudo e o nome "SafeNews", o
tempo mínimo de exibição, os 3 slides com indicador, "Continuar"/"Começar"/"Pular" e a marcação
local de "onboarding visto" (RN-004). Os textos dos slides já batem com o wireframe.

O que falta é:

1. **O splash ignora a sessão.** Quem já viu o onboarding sempre cai no login, mesmo estando
   conectado ou tendo entrado como visitante. Isso obriga a pessoa a entrar de novo a cada
   abertura e contradiz a sessão persistente (RF-007, feature 001).
2. **A conta não é conferida na abertura.** A feature 002 criou a verificação da conta salva,
   mas ninguém a chama ainda (CB-014: conta desativada → login).
3. **Faltam testes** do splash com a sessão e do onboarding.
4. **Pequenas diferenças do wireframe** no splash (frase de apoio abaixo do nome).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Reabrir o app já conectado (Priority: P1)

Uma pessoa que entrou com a conta (ou como visitante) fecha o app e o abre mais tarde. Ela vê o
splash por um instante e cai direto na área principal, sem passar pelo login de novo.

**Why this priority**: é o maior incômodo atual. O público é idoso: pedir e-mail e senha a cada
abertura afasta o usuário, e a sessão persistente já foi construída nas features 001 e 002, só
não é aproveitada na abertura.

**Independent Test**: entrar com uma conta de teste, fechar o app por completo e reabrir: o app
vai à área principal. Repetir entrando como visitante: também vai à área principal, como
visitante. Sair da conta, fechar e reabrir: vai ao login.

**Acceptance Scenarios**:

1. **Given** o onboarding já foi visto e há uma sessão conectada salva, **When** o app é aberto,
   **Then** depois do splash a pessoa vai à área principal, conectada.
2. **Given** o onboarding já foi visto e a pessoa estava como visitante, **When** o app é aberto,
   **Then** depois do splash ela vai à área principal, como visitante.
3. **Given** o onboarding já foi visto e não há sessão salva (nunca entrou, ou saiu da conta),
   **When** o app é aberto, **Then** depois do splash ela vai ao login.
4. **Given** qualquer um dos casos acima, **When** a pessoa usa o botão "voltar" do aparelho na
   tela de destino, **Then** o splash não reaparece (ele não fica no histórico de navegação).

---

### User Story 2 - Conta conferida na abertura (Priority: P1)

Quando a pessoa abre o app conectada, o app confere com o serviço, durante o splash, se a conta
ainda vale. Se a conta foi desativada ou a sessão não pode mais ser renovada, a pessoa vai ao
login em vez de entrar numa área principal que não funcionaria.

**Why this priority**: sem essa conferência, a US1 levaria pessoas com conta desativada a uma
área principal quebrada. CB-014 e CB-003 ("se a recusa acontecer na abertura do app, vai direto
ao login") exigem esse comportamento.

**Independent Test**: com uma sessão salva de uma conta desativada (ou com credenciais que o
serviço recusa), abrir o app: vai ao login. Com a internet desligada e uma sessão válida salva,
abrir o app: vai à área principal normalmente, sem espera longa.

**Acceptance Scenarios**:

1. **Given** há uma sessão conectada salva e o serviço confirma a conta, **When** o app é aberto,
   **Then** a pessoa vai à área principal e o nome e o e-mail guardados ficam atualizados com os
   do serviço.
2. **Given** há uma sessão conectada salva e o serviço informa que a conta não existe mais ou
   recusa a renovação da credencial, **When** o app é aberto, **Then** a sessão é encerrada e a
   pessoa vai ao login.
3. **Given** há uma sessão conectada salva e o aparelho está sem internet, ou o serviço está com
   erro ou demora a responder, **When** o app é aberto, **Then** a sessão é mantida e a pessoa
   vai à área principal assim que o prazo da conferência acaba.
4. **Given** a pessoa está como visitante ou sem sessão, **When** o app é aberto, **Then** nenhuma
   conferência com o serviço é feita e o splash dura só o tempo mínimo.
5. **Given** a conferência termina antes do tempo mínimo do splash, **When** o app é aberto,
   **Then** o splash continua até o tempo mínimo; se a conferência demora mais, o splash espera
   por ela até o prazo máximo. Os dois correm ao mesmo tempo, não um depois do outro.

---

### User Story 3 - Primeira abertura com onboarding (Priority: P2)

Na primeira abertura do aparelho, depois do splash, a pessoa vê os 3 slides de apresentação. Ela
avança com "Continuar", termina com "Começar" ou sai a qualquer momento com "Pular", e vai ao
login. O onboarding não volta a aparecer naquele aparelho.

**Why this priority**: o fluxo já funciona; esta história garante, com testes, que ele continua
certo e fiel ao wireframe depois dos ajustes do splash.

**Independent Test**: com o app recém-instalado, abrir: aparece o onboarding. Avançar até o fim
e tocar em "Começar": vai ao login. Fechar e reabrir: o onboarding não aparece. Repetir a
instalação usando "Pular" no primeiro slide: mesmo resultado.

**Acceptance Scenarios**:

1. **Given** o onboarding nunca foi visto no aparelho, **When** o app é aberto, **Then** depois
   do splash aparece o primeiro slide, mesmo que exista uma sessão salva.
2. **Given** a pessoa está no 1º ou 2º slide, **When** toca em "Continuar", **Then** vai ao
   próximo slide e o indicador de página acompanha.
3. **Given** a pessoa desliza o slide com o dedo, **When** o slide muda, **Then** o indicador e
   o botão ("Continuar" ou "Começar") acompanham o slide exibido.
4. **Given** a pessoa está no último slide, **When** toca em "Começar", **Then** o onboarding é
   marcado como visto e ela vai ao login.
5. **Given** a pessoa está em qualquer slide, **When** toca em "Pular", **Then** o onboarding é
   marcado como visto e ela vai ao login.
6. **Given** não foi possível guardar a marcação de "visto", **When** a pessoa termina ou pula,
   **Then** ela vai ao login mesmo assim (a falha não a prende no onboarding).

---

### Edge Cases

- **Falha ao ler a marcação de "onboarding visto"**: tratada como "não visto"; a pessoa vê o
  onboarding de novo em vez de ficar presa no splash.
- **Sessão salva corrompida ou ilegível**: já tratada pela feature 001 (vira "sem sessão"); o
  splash leva ao login.
- **Conta conferida, mas a resposta do serviço vem incompleta**: a sessão é mantida sem alterar
  nome e e-mail (comportamento da feature 002); a pessoa vai à área principal.
- **Credencial expirada que é renovada durante a conferência**: a renovação acontece sem a
  pessoa perceber; se for recusada, vale o cenário de conta recusada (vai ao login).
- **Serviço "dormindo" (demora para acordar)**: a conferência desiste no prazo máximo e a pessoa
  entra com a sessão mantida; o splash nunca espera o serviço acordar.
- **App enviado para segundo plano durante o splash**: ao voltar, o destino é aplicado
  normalmente, sem navegação duplicada.
- **Primeira abertura com sessão salva** (por exemplo, dados restaurados de backup): o onboarding
  tem prioridade; ao terminar, a pessoa vai ao login, como no wireframe.

## Requirements *(mandatory)*

### Functional Requirements

**Destino do splash**

- **FR-001**: O splash MUST decidir o destino nesta ordem: onboarding não visto → onboarding;
  senão, sessão conectada válida ou visitante → área principal; senão → login.
- **FR-002**: O destino MUST ser decidido só depois que o tempo mínimo de exibição do splash
  terminar **e** a conferência da conta (FR-004) terminar, as duas correndo ao mesmo tempo.
- **FR-003**: A navegação para o destino MUST substituir o splash, de modo que "voltar" não o
  mostre de novo.

**Conferência da conta na abertura**

- **FR-004**: Quando há sessão conectada salva, o splash MUST pedir a conferência da conta ao
  serviço, reaproveitando a verificação criada na feature 002 (FR-008 de lá), sem duplicar suas
  regras.
- **FR-005**: Se a conferência encerrar a sessão (conta inexistente ou renovação recusada), o
  destino MUST ser o login (CB-003, CB-014).
- **FR-006**: Sem internet, erro do serviço, resposta inválida ou prazo esgotado, a sessão MUST
  ser mantida e o destino MUST ser a área principal.
- **FR-007**: Para visitante ou sem sessão, nenhuma conferência MUST ser feita.
- **FR-008**: Uma falha inesperada na conferência MUST NOT travar o splash; o destino é decidido
  pelo estado da sessão naquele momento.

**Onboarding**

- **FR-009**: O onboarding MUST manter o comportamento atual: 3 slides com indicador de página,
  "Continuar" nos dois primeiros, "Começar" no último, "Pular" em todos, e ida ao login ao
  terminar ou pular (RF-002).
- **FR-010**: Concluir ou pular MUST marcar o onboarding como visto no aparelho, e ele MUST NOT
  aparecer de novo (RN-004). Falha ao gravar a marcação MUST NOT impedir a ida ao login.

**Fidelidade ao wireframe**

- **FR-011**: O splash MUST exibir, abaixo do nome do app, a frase de apoio "Sua segurança em
  primeiro lugar", traduzida em pt-BR e en-US.
- **FR-012**: Os títulos, textos, ícones e rótulos dos botões dos slides MUST corresponder aos do
  wireframe (já correspondem hoje; a conferência fica registrada nos testes).

**Testes**

- **FR-013**: A decisão de destino do splash MUST ter testes automatizados cobrindo cada
  combinação: onboarding não visto; visto + conectada confirmada; visto + conectada recusada;
  visto + conectada sem rede ou com prazo esgotado; visto + visitante; visto + sem sessão; falha
  na leitura do onboarding.
- **FR-014**: O controle do onboarding MUST ter testes automatizados cobrindo avançar, deslizar,
  terminar, pular e falha ao gravar a marcação.

### Key Entities

- **Marcação de onboarding visto**: indicador local, por aparelho, de que o onboarding foi
  concluído ou pulado (já existe).
- **Sessão salva**: estado da sessão restaurado ao abrir o app (conectada, visitante ou sem
  sessão), com nome e e-mail da pessoa quando conectada (features 001 e 002).
- **Destino do splash**: uma de três telas (onboarding, área principal, login), resultado da
  combinação dos dois itens acima e da conferência da conta.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Quem já entrou (com conta ou como visitante) chega à área principal em 100% das
  reaberturas do app, sem digitar nada, enquanto a conta for válida.
- **SC-002**: Uma sessão de conta desativada ou recusada leva ao login em 100% das aberturas.
- **SC-003**: O splash nunca fica na tela por mais de 4 segundos, mesmo sem internet ou com o
  serviço demorando a responder; para visitante ou sem sessão, dura o tempo mínimo
  (2 segundos).
- **SC-004**: O onboarding aparece só na primeira abertura do aparelho: em 0% das aberturas
  seguintes depois de concluído ou pulado.
- **SC-005**: Todas as combinações listadas em FR-013 e FR-014 passam nos testes automatizados,
  e a análise estática e a suíte de testes do projeto continuam limpas.

## Assumptions

- **Área principal provisória**: a tela de destino "área principal" é a rota já existente usada
  pelo login (feature 003). O shell com as 4 abas é da tarefa F0.9; quando ele chegar, só o
  conteúdo dessa rota muda, não a decisão do splash.
- **Tempo mínimo e prazo da conferência**: mantidos como estão hoje (2 segundos de splash; 3
  segundos de prazo da conferência, definido na feature 002). O wireframe usa 1,4 s, mas é
  referência visual, não de tempo.
- **Restauração da sessão**: a sessão salva já é lida antes do splash aparecer (feature 001); o
  splash só a consulta e pede a conferência.
- **Pós-onboarding vai ao login**: mesmo no caso raro de existir sessão salva na primeira
  abertura, o onboarding termina no login, como no wireframe e no comportamento atual.
- **Cores e animação**: a cor de fundo do 3º ícone segue o token do design system já usado
  (próximo, mas não idêntico, ao `#607698` do wireframe), e a pulsação do escudo do wireframe
  fica fora de escopo, para não introduzir animação contínua na tela de abertura do público
  idoso.
- **Sem mensagem de "sessão expirada" no splash**: quando a conferência encerra a sessão na
  abertura, a pessoa vai direto ao login (CB-003). Mostrar um aviso no login fica fora do
  escopo: a tela de login não exibe esse aviso hoje.
- **Dependências**: features 001 (sessão persistente), 002 (conferência da conta na abertura) e
  003 (login e área principal provisória), todas concluídas.
