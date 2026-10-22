# Feature Specification: Resposta e feedback das atividades

**Feature Branch**: `018-resposta-feedback-atividades`

**Created**: 2026-10-22

**Status**: Draft

**Input**: User description: "B3 Atividades: resposta e feedback (RF-025 a RF-028, RN-005) — tarefa B3 da Trilha B em .specify/memory/tasks.md. Na tela de perguntas da B2, a pessoa escolhe uma alternativa, confirma num rodapé fixo e vê um painel de feedback (acertou ou errou, alternativa correta destacada e explicação). A correção é do serviço. Responder marca a lição como respondida e libera 'Próxima'. Com conta, depois de responder o progresso do módulo é recarregado; o visitante tem a resposta gravada no registro da sessão (GuestProgressStore.recordAnswer, B1). Alternativa recusada pelo serviço (EDUCATIONAL_INVALID_OPTION) recarrega o módulo. A tela de conclusão e o aviso de login no fim são da B4."

**Rastreabilidade**: tarefa B3 do [tasks do produto](../../.specify/memory/tasks.md) · RF-025,
RF-026, RF-027, RF-028, RF-040, RN-005, RN-006 (2.3.0), RNF-003, RNF-004 e RNF-006 da
[especificação do produto](../../.specify/memory/specification.md) · seção "Atividades" do
[contrato da API](../../.specify/memory/api-contract.md) 1.0.10 · registro do visitante da
[feature 015](../015-painel-atividades/spec.md) · tela de perguntas da
[feature 017](../017-perguntas-atividades/spec.md) · leitura em voz alta das features
[007](../007-servicos-plataforma-voz/spec.md) e [014](../014-acessibilidade/spec.md).

## Contexto

A B2 entregou o caminho pelas perguntas, mas as alternativas ainda são só para ler e "Próxima"
fica parada na primeira pergunta não respondida. Esta feature fecha o ciclo de cada pergunta:
**escolher, confirmar e entender o resultado**. A correção é feita pelo serviço, que devolve se a
pessoa acertou, qual era a alternativa correta e uma explicação. A explicação é a parte
educativa: é ela que ensina por que aquele golpe é golpe.

O público é, em boa parte, idoso: escolher deve ser um toque claro num cartão grande, confirmar é
um passo separado (para evitar toque acidental), e o resultado precisa ser entendido sem depender
só de cor.

Fica **fora**: a tela de conclusão do módulo, compartilhar a conquista e o aviso de login do
visitante no fim do módulo (B4).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Escolher e confirmar a resposta (Priority: P1)

Na pergunta atual, a pessoa toca numa alternativa, que fica marcada. No rodapé fixo, o botão
"Confirmar resposta" fica ativo; ao tocar, a resposta vai para correção.

**Why this priority**: sem responder não há atividade (RF-025, RF-026); é também o que libera o
avanço que a B2 deixou travado.

**Independent Test**: com o serviço falso, abrir um módulo, tocar numa alternativa, conferir a
marcação e o botão ativo, confirmar e conferir que a alternativa escolhida foi a enviada.

**Acceptance Scenarios**:

1. **Given** uma pergunta aberta sem alternativa escolhida, **When** a pessoa olha o rodapé,
   **Then** "Confirmar resposta" está desativado (e anunciado assim pelo leitor de tela).
2. **Given** uma pergunta aberta, **When** a pessoa toca numa alternativa, **Then** ela fica
   marcada de forma visível (não só por cor) e "Confirmar resposta" fica ativo.
3. **Given** uma alternativa marcada, **When** a pessoa toca em outra, **Then** a marcação passa
   para a nova; só uma fica marcada.
4. **Given** uma alternativa marcada, **When** a pessoa toca em "Confirmar resposta", **Then** o
   botão mostra que está enviando, as alternativas não podem mais ser trocadas e a resposta é
   enviada uma única vez, mesmo com toques repetidos.
5. **Given** as alternativas na ordem enviada pelo serviço, **When** a pessoa escolhe e confirma,
   **Then** a ordem não muda em nenhum momento (RF-027).

---

### User Story 2 - Ver se acertou, a correta e a explicação (Priority: P1)

Depois de confirmar, sobe um painel de feedback: "Você acertou!" ou "Não foi dessa vez", a
alternativa correta destacada e a explicação da lição. Do painel, a pessoa segue para a próxima
pergunta.

**Why this priority**: o feedback com explicação é o que ensina (RF-026); sem ele, responder não
tem valor educativo.

**Independent Test**: com o serviço falso respondendo acerto e depois erro, conferir o título do
painel, o destaque da correta (e da escolhida, no erro), a explicação e o botão de seguir.

**Acceptance Scenarios**:

1. **Given** a pessoa confirmou a alternativa correta, **When** o serviço responde, **Then** o
   painel diz que acertou, com ícone e texto (não só cor), a alternativa escolhida aparece como
   correta e a explicação é mostrada.
2. **Given** a pessoa confirmou uma alternativa errada, **When** o serviço responde, **Then** o
   painel diz que errou, a alternativa escolhida aparece como errada, a correta aparece destacada
   como correta e a explicação é mostrada.
3. **Given** o serviço não envia explicação para a lição, **When** o painel aparece, **Then** ele
   mostra só o resultado e a correta, sem espaço vazio nem texto de erro.
4. **Given** o painel aberto numa pergunta que não é a última, **When** a pessoa toca em
   "Próxima pergunta", **Then** o painel fecha e a próxima pergunta aparece, sem alternativa
   marcada.
5. **Given** o painel aberto na última pergunta do módulo, **When** a pessoa toca no botão do
   painel, **Then** segue para o fim do módulo (que a B4 vai entregar; até lá, volta ao painel de
   atividades com o progresso atualizado).
6. **Given** o painel aberto, **When** a pessoa o fecha sem seguir (gesto ou voltar do aparelho),
   **Then** continua na mesma pergunta, que agora aparece como respondida, com o resultado
   visível nas alternativas, e "Próxima" fica ativo.
7. **Given** a pessoa respondeu (certo ou errado), **When** olha o indicador de progresso do
   módulo, **Then** a pergunta aparece como concluída (uma lição conta como concluída ao ser
   respondida, certa ou errada, RN-006).

---

### User Story 3 - A pontuação e o progresso acompanham as respostas (Priority: P2)

A cada resposta, a pontuação do módulo é atualizada: para quem tem conta, é a calculada pelo
serviço; para o visitante, a calculada pelo app do mesmo jeito, só nesta sessão. Voltar ao painel
mostra o módulo com o progresso novo.

**Why this priority**: RF-028 e RN-005 exigem a pontuação do serviço; a B4 vai mostrá-la na
conclusão e o painel (B1) precisa refletir as respostas. Vem depois de responder porque depende
dele.

**Independent Test**: com o serviço falso, responder como conta e conferir que o progresso do
módulo foi buscado de novo e a pontuação mostrada é a do serviço; como visitante, responder e
conferir que a resposta foi gravada no registro da sessão (com o acerto) e que o painel mostra o
módulo em andamento.

**Acceptance Scenarios**:

1. **Given** uma pessoa com conta, **When** ela responde uma pergunta, **Then** o app busca de novo
   o progresso do módulo no serviço e passa a mostrar a pontuação que o serviço calculou
   ("X de Y acertos").
2. **Given** um visitante, **When** ele responde uma pergunta, **Then** a resposta (alternativa
   escolhida e se acertou) fica gravada no registro da sessão, substituindo uma resposta anterior
   à mesma lição, e a pontuação mostrada é acertos na resposta mais recente / total de lições
   (RN-005).
3. **Given** a pessoa respondeu perguntas de um módulo, **When** volta ao painel de atividades,
   **Then** o módulo aparece com as lições concluídas e o status atualizados.
4. **Given** ainda não há nenhuma resposta no módulo (o serviço devolve total 0), **When** a tela
   mostra a pontuação, **Then** não aparece "0 de 0".
5. **Given** a resposta foi corrigida mas a nova busca do progresso falhou, **When** o painel de
   feedback aparece, **Then** o resultado e a explicação aparecem normalmente e a pontuação
   continua a última conhecida, sem mensagem de erro.

---

### User Story 4 - Responder de novo uma pergunta já respondida (Priority: P2)

Ao voltar a uma pergunta já respondida (nesta visita ou antes), a pessoa pode responder de novo;
a resposta nova é a que passa a valer na pontuação.

**Why this priority**: a pontuação considera a resposta **mais recente** de cada lição (RN-005);
quem errou e voltou para revisar precisa poder melhorar. É secundário ao primeiro ciclo de
resposta.

**Independent Test**: com uma lição já respondida, voltar a ela, escolher outra alternativa,
confirmar e conferir que o resultado novo aparece e a pontuação reflete a resposta nova.

**Acceptance Scenarios**:

1. **Given** uma pergunta respondida antes desta visita (o serviço só informa que foi respondida),
   **When** ela aparece, **Then** aparece como concluída, sem alternativa marcada, e a pessoa pode
   escolher e confirmar de novo; "Próxima" continua ativo.
2. **Given** uma pergunta respondida nesta visita, **When** a pessoa volta a ela, **Then** vê o
   resultado da última resposta nas alternativas (escolhida e correta) e um botão "Responder de
   novo" que limpa a marcação para nova escolha.
3. **Given** a pessoa respondeu de novo, **When** o serviço corrige, **Then** o feedback e a
   pontuação passam a refletir a resposta nova, para conta e para visitante.

---

### User Story 5 - Ouvir o resultado e a explicação (Priority: P3)

No painel de feedback, a pessoa pode ouvir o resultado, a alternativa correta e a explicação. Com
a leitura automática ligada, isso é lido sozinho quando o painel aparece.

**Why this priority**: RF-040 pede leitura automática do conteúdo; a explicação costuma ser o
texto mais longo da atividade. Depende do painel existir.

**Independent Test**: com o leitor de voz falso, abrir o painel e tocar em "Ouvir"; com a leitura
automática ligada, confirmar uma resposta e conferir que a leitura do feedback começou sozinha.

**Acceptance Scenarios**:

1. **Given** o painel de feedback aberto, **When** a pessoa toca em "Ouvir", **Then** o app lê o
   resultado, a alternativa correta e a explicação, na velocidade da Acessibilidade.
2. **Given** a leitura automática ligada, **When** o painel aparece, **Then** a leitura do
   feedback começa sozinha, uma vez, depois de parar a leitura da pergunta que estiver em
   andamento.
3. **Given** a leitura do feedback em andamento, **When** a pessoa segue para a próxima pergunta
   ou fecha o painel, **Then** a leitura do feedback para (e a próxima pergunta é lida sozinha,
   se a leitura automática estiver ligada, como na B2).
4. **Given** o aparelho sem voz no idioma do app, **When** o painel aparece, **Then** "Ouvir" não
   aparece e nada é lido, sem erro.

---

### User Story 6 - Erros ao enviar a resposta (Priority: P2)

Sem internet, com o serviço demorando ou recusando a alternativa, a pessoa entende o que houve e
não perde a escolha.

**Why this priority**: o servidor gratuito leva até ~40 s para acordar e as atividades não
funcionam sem internet (RNF-002); o contrato prevê a recusa de alternativa
(`EDUCATIONAL_INVALID_OPTION`), que acontece quando o módulo mudou no serviço.

**Independent Test**: com o serviço falso falhando, atrasado, recusando a alternativa e dizendo
que a lição não existe, conferir cada reação.

**Acceptance Scenarios**:

1. **Given** sem internet ou erro do serviço, **When** a pessoa confirma, **Then** aparece uma
   mensagem de que não foi possível enviar, a alternativa continua marcada e "Confirmar resposta"
   volta a funcionar para tentar de novo; a lição **não** é marcada como respondida.
2. **Given** o serviço demora, **When** a pessoa confirma, **Then** o botão mostra que está
   enviando e, depois de alguns segundos, aparece o aviso de que o serviço está acordando.
3. **Given** o serviço recusa a alternativa como inválida, **When** a pessoa confirma, **Then**
   aparece uma mensagem de que a pergunta foi atualizada e o módulo é recarregado, voltando à
   primeira pergunta não respondida.
4. **Given** o serviço informa que a lição ou o módulo não existe mais, **When** a pessoa confirma,
   **Then** o módulo é recarregado (e, se não houver mais atividades, aparece o estado "módulo sem
   atividades" da B2).
5. **Given** a pessoa sai da tela enquanto a resposta está sendo enviada, **When** o serviço
   responde, **Then** nada aparece nem quebra; para o visitante, a resposta corrigida ainda é
   gravada no registro da sessão.

---

### Edge Cases

- **Visitante**: responde como quem tem conta; o serviço corrige sem salvar e o app grava no
  registro da sessão (RN-006). Se ele criar conta sem fechar o app, as respostas vão para a conta
  nova (comportamento da B1, que esta feature só alimenta).
- **Sessão expira** durante o envio: a resposta segue como sem conta (o serviço corrige); a
  pessoa vê o feedback normalmente.
- **Letra no nível máximo / alto contraste** (B9): alternativas marcadas, correta e errada
  continuam distinguíveis por ícone e texto, não só por cor; o painel rola se a explicação for
  longa; o rodapé fixo não cobre a última alternativa.
- **Explicação longa**: o painel rola; o botão de seguir continua alcançável.
- **Toques rápidos** em "Confirmar resposta" ou "Próxima pergunta": um envio e um avanço por vez.
- **Leitor de tela** (TalkBack): cada alternativa anuncia se está marcada; depois da correção,
  anuncia "correta" ou "sua resposta, errada"; o painel anuncia o resultado ao aparecer.
- **Idioma em inglês**: textos do app em inglês; alternativas e explicação vêm do serviço em
  português e não são traduzidas.
- **Correta que não está entre as alternativas mostradas** (dado inconsistente do serviço): o
  painel mostra o resultado e a explicação sem destacar nenhuma alternativa como correta, sem
  erro.
- **Leitura da pergunta em andamento** ao confirmar: para antes do feedback aparecer.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Na pergunta atual, a pessoa MUST poder escolher uma única alternativa com um toque;
  a escolhida fica marcada de forma visível e anunciada, não só por cor.
- **FR-002**: A tela MUST ter um rodapé fixo com "Confirmar resposta", ativo só com uma
  alternativa marcada (RF-026).
- **FR-003**: Confirmar MUST enviar a alternativa escolhida para correção pelo serviço, uma vez por
  toque válido, e bloquear trocas enquanto envia.
- **FR-004**: As alternativas MUST manter a ordem em que o serviço as enviou durante escolha,
  envio e feedback (RF-027).
- **FR-005**: Depois da correção, a tela MUST mostrar um painel de feedback com: resultado
  (acertou/errou, com ícone e texto), a alternativa correta destacada, a escolhida marcada como
  errada quando for o caso, e a explicação quando o serviço a enviar (RF-026).
- **FR-006**: Responder (certo ou errado) MUST marcar a lição como respondida, atualizar o
  indicador de progresso do módulo e liberar "Próxima" (RN-006; clarificação de 2026-10-21 da B2).
- **FR-007**: O painel MUST oferecer seguir para a próxima pergunta; na última pergunta, seguir
  para o fim do módulo (até a B4, voltar ao painel de atividades).
- **FR-008**: Fechar o painel sem seguir MUST manter a pessoa na mesma pergunta, com o resultado
  visível nas alternativas.
- **FR-009**: Para quem tem conta, depois de cada resposta corrigida o app MUST buscar de novo o
  progresso do módulo no serviço e usar a pontuação dele (RF-028, RN-005). Falha nessa busca MUST
  NOT esconder o resultado já recebido.
- **FR-010**: Para o visitante, cada resposta corrigida MUST ser gravada no registro da sessão
  (alternativa escolhida e se acertou), substituindo a anterior da mesma lição; a pontuação é
  acertos na resposta mais recente / total de lições do módulo (RN-005, RN-006).
- **FR-011**: A tela MUST mostrar a pontuação atual do módulo depois que houver ao menos uma
  resposta, e MUST NOT mostrar "0 de 0".
- **FR-012**: A pessoa MUST poder responder de novo uma pergunta já respondida; a resposta nova
  substitui a anterior na pontuação (RN-005).
- **FR-013**: Sem internet ou erro do serviço ao enviar, a tela MUST mostrar uma mensagem, manter a
  alternativa marcada e permitir tentar de novo, sem marcar a lição como respondida.
- **FR-014**: Envio demorado MUST mostrar que está enviando e, depois de alguns segundos, o aviso
  de serviço acordando (como na carga do módulo).
- **FR-015**: Alternativa recusada pelo serviço, ou lição/módulo que não existe mais, MUST
  recarregar o módulo com uma mensagem de que a pergunta foi atualizada.
- **FR-016**: O painel de feedback MUST oferecer "Ouvir" (resultado, correta e explicação) na
  velocidade da Acessibilidade, e, com a leitura automática ligada, ler sozinho uma vez ao
  aparecer (RF-040). Sem voz no idioma do app, nada disso aparece nem acontece.
- **FR-017**: A leitura em andamento (da pergunta ou do feedback) MUST parar ao confirmar, ao
  seguir para outra pergunta, ao fechar o painel e ao sair da tela.
- **FR-018**: A explicação MUST NOT aparecer antes da correção (mantém o FR-016 da B2).
- **FR-019**: A tela MUST seguir o padrão de acessibilidade do app (RNF-003/RNF-004): alvos ≥ 48
  dp, texto base ≥ 16 sp, letra e alto contraste da B9, e anúncios de marcada, correta, errada e
  do resultado.
- **FR-020**: Os textos do app na tela MUST estar em português e inglês (RNF-006); alternativas e
  explicação vêm do serviço como estão.
- **FR-021**: O visitante MUST conseguir responder sem conta.

### Key Entities

- **Resultado da resposta**: se acertou, qual é a alternativa correta e a explicação (opcional),
  como devolvidos pelo serviço.
- **Resposta do visitante** (registro da sessão, B1): módulo, lição, alternativa escolhida e,
  agora, se acertou, para calcular a pontuação do visitante.
- **Progresso do módulo**: lições concluídas, pontuação e total da pontuação, e se o módulo está
  concluído. Para quem tem conta vem do serviço; para o visitante, calculado do registro da
  sessão.
- **Estado da pergunta na tela**: alternativa marcada, enviando, resultado recebido (para mostrar
  de novo ao voltar a ela na mesma visita).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Com o serviço acordado, o painel de feedback aparece em até 2 segundos depois de
  confirmar.
- **SC-002**: A pessoa responde todas as perguntas de um módulo de ponta a ponta só com toques em
  alternativa, "Confirmar resposta" e "Próxima pergunta", sem ficar presa em nenhuma.
- **SC-003**: Em 100% das respostas o painel mostra o resultado, a correta destacada e a
  explicação quando existir; nenhuma explicação aparece antes da correção.
- **SC-004**: A pontuação mostrada para quem tem conta é sempre igual à do serviço depois da
  última resposta; para o visitante, igual ao cálculo da RN-005 sobre as respostas da sessão.
- **SC-005**: Nenhuma falha de envio marca a lição como respondida nem perde a alternativa
  escolhida.
- **SC-006**: Com a letra no nível máximo e o alto contraste, alternativas, rodapé e painel ficam
  legíveis e tocáveis no aparelho, e correta/errada são distinguíveis sem cor.
- **SC-007**: Ao voltar ao painel de atividades, o módulo mostra as lições respondidas na visita.

## Assumptions

- **Formato dos dados**: contrato 1.0.10, conferido no servidor real em 2026-10-19. A resposta
  devolve `isCorrect`, `correctOptionId` e `explanation` (opcional). Sem conta, o serviço corrige
  mas não salva. Uma lição conta como concluída ao ser respondida, certa ou errada; a pontuação do
  serviço considera a resposta mais recente; `totalScore` vem 0 até a primeira resposta.
- **Explicação vem da resposta**: o detalhe do módulo também traz a explicação, mas a mostrada é a
  devolvida pela correção, para não depender de dado que a tela da B2 descarta.
- **Resposta anterior não é conhecida**: o serviço só diz que a lição foi respondida, não qual
  alternativa a pessoa escolheu. Por isso, uma pergunta respondida antes desta visita aparece
  sem marcação (User Story 4); o resultado só é lembrado para respostas feitas na visita atual.
- **Sem nova tentativa automática no mesmo painel**: como o feedback revela a correta, o painel
  leva à próxima pergunta; responder de novo é possível voltando à pergunta (User Story 4).
- **Registro do visitante**: o registro da sessão da B1 (`GuestProgressStore`) passa a guardar
  também se a resposta estava certa, para a pontuação do visitante; a transferência para a conta
  nova continua enviando só a alternativa escolhida.
- **Fim do módulo**: até a B4 existir, seguir da última pergunta volta ao painel de atividades; a
  B4 troca esse destino pela tela de conclusão (e pelo aviso de login, para o visitante).
- **Leitura em voz alta**: reaproveita o motor de voz, a velocidade e o botão "Ouvir" das features
  007, 010, 014 e 017; a voz segue o idioma do app.
- **Sem offline**: responder exige internet, como o resto das atividades (RNF-002 não as inclui).
- **Fora desta feature**: tela de conclusão, compartilhar conquista e aviso de login do visitante
  (B4).
