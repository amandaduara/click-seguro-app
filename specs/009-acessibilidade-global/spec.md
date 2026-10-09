# Feature Specification: Acessibilidade global

**Feature Branch**: `009-acessibilidade-global`

**Created**: 2026-10-08

**Status**: Draft

**Input**: User description: "F0.6 Acessibilidade global (RF-038 a RF-041, infraestrutura). Módulo settings: AccessibilityPreferences (entity: tamanho da fonte, alto contraste, leitura automática), AccessibilityRepository local sobre LocalCacheService, usecases get/save, AccessibilityController, com testes. AccessibilityPreferencesNotifier em common, atualizado pelo controller. AppTheme.highContrast e ligação no ClickSeguroApp (tema + textScaler). Carregar as preferências no _setup() do main.dart. A tela de Acessibilidade (B9) fica fora: aqui só a infraestrutura."

**Rastreabilidade**: tarefa F0.6 do [tasks do produto](../../.specify/memory/tasks.md) · RF-038 a
RF-041 e RNF-003/RNF-004 da [especificação do produto](../../.specify/memory/specification.md)
v2.2.0 · [plano do produto](../../.specify/memory/plan.md) §3.2 e §3.4 · velocidade de leitura
deixada para cá pela [feature 007](../007-servicos-plataforma-voz/spec.md) (Assumptions).

## Contexto

O público do SafeNews é, em boa parte, idoso. Ele precisa de letra maior, de cores mais fortes e
de ouvir o conteúdo sem ter de tocar em "Ouvir" toda vez. Esta feature entrega a **base** dessas
três preferências: guardá-las no aparelho, aplicá-las ao app inteiro já na abertura e deixar o
valor em vigor disponível para as telas de conteúdo. **Não há tela nova**: a tela de
Acessibilidade, onde a pessoa escolhe as opções, é a tarefa B9 e usa o que esta feature entrega.

As "pessoas" das histórias abaixo são quem usa o app; os cenários descrevem o efeito das
preferências, que nos testes e na validação são trocadas sem a tela da B9.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Letra maior em todo o app (Priority: P1)

Uma pessoa com vista cansada escolhe uma letra maior. Todas as telas passam a usar esse tamanho na
hora, sem reiniciar o app, e somado ao aumento de letra que ela já tenha ligado no celular.

**Why this priority**: é a necessidade mais comum do público idoso (RF-038) e afeta todas as
telas; sem ela o app fica difícil de ler.

**Independent Test**: trocar o tamanho da fonte pelo controller num teste de widget e conferir que
um texto qualquer do app fica maior; repetir com a escala do sistema aumentada.

**Acceptance Scenarios**:

1. **Given** o tamanho "padrão", **When** a pessoa escolhe um dos níveis maiores, **Then** o texto
   de todas as telas cresce na proporção do nível, sem reiniciar o app.
2. **Given** o celular já está com letra aumentada nas configurações do sistema, **When** a pessoa
   escolhe um nível maior no app, **Then** os dois aumentos se somam (o app respeita a escala do
   sistema, RNF-004).
3. **Given** um nível maior escolhido, **When** a pessoa volta ao "padrão", **Then** o texto volta
   ao tamanho de antes.

---

### User Story 2 - Preferências lembradas na próxima abertura (Priority: P1)

A pessoa fecha o app e abre no dia seguinte. A letra, o contraste e a leitura automática já estão
como ela deixou, desde a primeira tela (splash), sem piscar no tamanho ou na cor padrão.

**Why this priority**: sem guardar, a pessoa teria de reconfigurar tudo a cada abertura (RF-041);
para o público-alvo isso equivale a não ter o recurso.

**Independent Test**: salvar preferências num armazenamento falso, montar o app de novo a partir
dele e conferir que a primeira tela já sai com tema e tamanho escolhidos.

**Acceptance Scenarios**:

1. **Given** preferências salvas, **When** o app abre, **Then** elas são carregadas antes da
   primeira tela e o splash já aparece com elas.
2. **Given** nada salvo (primeira abertura), **When** o app abre, **Then** valem os padrões:
   letra padrão, contraste normal, leitura automática desligada, velocidade normal.
3. **Given** o registro salvo está corrompido ou tem valores desconhecidos, **When** o app abre,
   **Then** os valores inválidos caem no padrão e o app abre normalmente.
4. **Given** a pessoa sai da conta ou entra como visitante, **When** volta ao app, **Then** as
   preferências continuam as mesmas (são do aparelho, não da conta).

---

### User Story 3 - Alto contraste (Priority: P2)

Uma pessoa com baixa visão liga o alto contraste. Fundo, texto, botões e bordas passam a ter
contraste máximo em todas as telas, na hora.

**Why this priority**: necessário para parte do público (RF-039), mas menos comum que a letra
maior.

**Independent Test**: ligar o alto contraste pelo controller num teste de widget e conferir que o
tema em uso é o de alto contraste; medir o contraste das cores principais do tema.

**Acceptance Scenarios**:

1. **Given** contraste normal, **When** a pessoa liga o alto contraste, **Then** todas as telas
   passam a usar o tema de alto contraste, sem reiniciar o app.
2. **Given** o tema de alto contraste, **When** se mede texto principal sobre o fundo, **Then** a
   razão atende WCAG 2.1 AAA (pelo menos 7:1), e elementos de interface (bordas, ícones) pelo
   menos 3:1.
3. **Given** alto contraste ligado, **When** a pessoa desliga, **Then** o tema normal volta.

---

### User Story 4 - Leitura automática e velocidade da voz disponíveis para as telas (Priority: P3)

A pessoa liga a leitura automática e escolhe a velocidade da voz. As telas de notícia (A5) e de
pergunta (B2) consultam essas preferências para começar a ler sozinhas, na velocidade escolhida.

**Why this priority**: o efeito visível só aparece com A5 e B2; aqui basta deixar o valor guardado
e disponível (RF-040).

**Independent Test**: trocar a leitura automática e a velocidade pelo controller e conferir que o
valor disponível para os outros módulos muda e que o leitor em voz alta passa a usar a velocidade
guardada.

**Acceptance Scenarios**:

1. **Given** a leitura automática desligada, **When** a pessoa liga, **Then** qualquer módulo que
   consultar o valor em vigor vê "ligada", sem depender do módulo de configurações.
2. **Given** a pessoa escolhe a velocidade "lenta", **When** uma leitura em voz alta começa em
   qualquer tela, **Then** ela usa "lenta"; e a escolha vale também na próxima abertura.

---

### Edge Cases

- **Falha ao salvar** (armazenamento do aparelho indisponível): a mudança vale enquanto o app
  estiver aberto e a tela não trava; na próxima abertura vale o último valor salvo com sucesso.
- **Falha ao ler na abertura**: o app abre com os padrões, sem mensagem de erro.
- **Registro antigo ou parcial** (por exemplo, sem a velocidade): o que falta cai no padrão; o
  resto é mantido.
- **Letra muito grande** (nível máximo do app × escala alta do sistema): o texto cresce, mas a
  escala total é limitada a um teto para não quebrar as telas (ver FR-004).
- **Mudanças rápidas seguidas**: o valor final aplicado e salvo é o último escolhido.
- **Telas abertas durante a mudança**: atualizam na hora, sem precisar sair e voltar.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: O app MUST manter quatro preferências de acessibilidade: tamanho da fonte, alto
  contraste, leitura automática e velocidade da leitura em voz alta.
- **FR-002**: O tamanho da fonte MUST ter quatro níveis: padrão (100%) e três maiores (115%, 130%
  e 150%) (RF-038).
- **FR-003**: O nível escolhido MUST ser aplicado a todo texto do app e multiplicado pela escala de
  fonte do sistema operacional (RNF-004).
- **FR-004**: A escala total (sistema × app) MUST ser limitada a 200%, para que as telas continuem
  utilizáveis.
- **FR-005**: O app MUST ter um tema de alto contraste com texto principal em razão ≥ 7:1 sobre o
  fundo (WCAG AAA) e elementos de interface ≥ 3:1, mantendo alvos de toque ≥ 48 dp e texto base ≥
  16 sp (RNF-003) (RF-039).
- **FR-006**: Mudar qualquer preferência MUST ter efeito imediato em todas as telas abertas, sem
  reiniciar o app.
- **FR-007**: As preferências MUST ser salvas no aparelho a cada mudança e carregadas antes da
  primeira tela da próxima abertura (RF-041).
- **FR-008**: Na ausência de valor salvo, ou com valor ilegível, MUST valer o padrão de cada
  preferência: fonte padrão, contraste normal, leitura automática desligada, velocidade normal.
  Valores ilegíveis afetam só a preferência em questão.
- **FR-009**: Falhas de leitura ou gravação das preferências MUST NOT impedir o app de abrir nem
  travar a tela; ao falhar a gravação, a mudança vale até o app fechar.
- **FR-010**: As preferências MUST pertencer ao aparelho: sair da conta, entrar como visitante ou
  trocar de conta MUST NOT alterá-las.
- **FR-011**: O valor em vigor da leitura automática e da velocidade MUST ficar disponível para os
  módulos de conteúdo (notícias e atividades) sem que eles dependam do módulo de configurações.
- **FR-012**: A leitura em voz alta MUST usar a velocidade guardada nas preferências; mudar a
  velocidade MUST valer a partir da próxima leitura.
- **FR-013**: Esta feature MUST NOT criar tela nova; a escolha das opções pela pessoa é a tarefa
  B9.

### Key Entities

- **Preferências de acessibilidade**: tamanho da fonte (um dos quatro níveis), alto contraste
  (sim/não), leitura automática (sim/não) e velocidade da leitura (lenta, normal ou rápida, as
  mesmas da feature 007). Uma por aparelho, sem vínculo com a conta.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Em 100% das aberturas com preferências salvas, a primeira tela já aparece com o
  tamanho e o tema escolhidos, sem mostrar antes o padrão.
- **SC-002**: Uma mudança de preferência aparece em todas as telas abertas em menos de 1 segundo.
- **SC-003**: No tema de alto contraste, todas as combinações de texto principal sobre fundo
  medem pelo menos 7:1.
- **SC-004**: No nível máximo de fonte do app, as telas existentes (splash, login, início, Reels,
  abas) continuam usáveis no aparelho: nenhum texto cortado sem possibilidade de rolar e nenhum
  botão inacessível.
- **SC-005**: Com o armazenamento corrompido ou indisponível, o app abre em 100% das vezes.

## Assumptions

- **Níveis e velocidades**: os níveis 100/115/130/150% vêm do plano do produto (§3.2). As
  velocidades lenta/normal/rápida já existem desde a feature 007; aqui só passam a ser guardadas.
- **Teto de 200%**: escolhido para que o maior nível do app (150%) ainda some com uma escala
  moderada do sistema sem quebrar as telas; acima disso a escala do sistema é limitada.
- **Idioma**: guardar o idioma do app (RF-042) não faz parte das preferências de acessibilidade;
  o pacote de tradução já guarda a escolha (B8).
- **Leitura automática**: esta feature só guarda e expõe o valor. Começar a ler sozinho ao abrir
  uma notícia ou pergunta é de A5 e B2.
- **Tela de Acessibilidade**: fica para B9; até lá, a rota `/settings/accessibility` continua com
  o placeholder da feature 005, e a validação no aparelho troca as preferências por um meio de
  desenvolvimento.
- **Dependências**: o armazenamento local (`LocalCacheService`, feature 001), o leitor em voz alta
  (feature 007) e o módulo `settings` com rota placeholder (feature 005) já existem. `common/`,
  `main.dart` e o tema ainda são da Fase 0, então esta feature pode mexer neles.
