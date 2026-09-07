# SafeNews — Especificação de Produto

**Projeto**: Click Seguro (TCC) — Aplicativo **SafeNews**

**Versão**: 1.0.0

**Criado em**: 2026-09-07

**Status**: Rascunho (Draft)

**Alinhado a**: [constitution.md](constitution.md) v1.0.1 — este documento descreve O QUE o
sistema faz; o COMO (arquitetura, stack, camadas) é regido pela constituição e detalhado nos
planos técnicos (`plan.md`) gerados a partir daqui.

---

## 1. Visão do Produto e Problema

### 1.1 Problema

A desinformação ("fake news") se propaga mais rápido do que a verificação factual,
principalmente em redes sociais e aplicativos de mensagens. O usuário comum não tem, no
momento em que lê uma notícia, nenhum sinal confiável e imediato sobre:

- se a fonte da notícia é reconhecidamente confiável;
- se o conteúdo já foi checado por alguém com autoridade para validá-lo;
- para onde reportar uma notícia suspeita e o que acontece depois disso.

Isso cria um ambiente onde a decisão de "acreditar ou não" fica inteiramente a cargo do
usuário leigo, sem ferramenta de apoio.

### 1.2 Proposta de valor do SafeNews

O SafeNews é um aplicativo móvel/multiplataforma (Flutter) que concentra consumo de notícias
e checagem de veracidade em um único fluxo:

- entrega um **feed de notícias categorizado**, com indicação visual imediata do status de
  veracidade de cada item;
- permite que o leitor **denuncie** uma notícia que considera suspeita, com motivo
  estruturado (não texto livre);
- permite que um **validador** (usuário com papel de checagem) analise denúncias e atribua um
  status de veracidade auditável;
- funciona de forma **resiliente a conexões ruins ou ausentes**, mantendo o último feed
  consultado disponível em modo offline.

O valor central é reduzir a distância entre "ler uma notícia" e "saber se pode confiar nela",
sem exigir que o usuário saia do aplicativo para checar em outro lugar.

### 1.3 Fora de escopo (v1)

- Rede social entre usuários (comentários públicos, seguir outros usuários, curtidas).
- Geração de notícias ou conteúdo original pelo próprio SafeNews (o app consome/agrega e
  valida, não produz jornalismo).
- Moderação por inteligência artificial automatizada da veracidade (a decisão de veracidade é
  humana, feita pelo validador — IA como apoio é uma evolução futura, não um requisito da v1).

---

## 2. Personas de Usuário e Casos de Uso Principais

### 2.1 Persona — Leitor de Notícias

Usuário final comum, que abre o app para se manter informado e quer decidir rapidamente se
uma notícia é confiável antes de compartilhá-la.

**Objetivos primários:**
- Consumir um feed de notícias relevante e categorizado.
- Identificar, de forma visual e imediata, o quão confiável é cada notícia.
- Denunciar uma notícia que parece falsa ou enganosa.
- Ler notícias já abertas anteriormente mesmo sem internet.

### 2.2 Persona — Validador (Fact-Checker)

Usuário com papel elevado de confiança (jornalista, moderador ou voluntário treinado),
responsável por revisar denúncias e decidir o status de veracidade de uma notícia.

**Objetivos primários:**
- Visualizar uma fila de notícias denunciadas/pendentes de checagem, priorizada.
- Analisar a notícia, suas fontes e o motivo da denúncia.
- Registrar uma decisão de veracidade com justificativa, criando um histórico auditável.
- Ter certeza de que sua decisão é refletida imediatamente para todos os leitores.

### 2.3 Casos de Uso Principais

| ID | Persona | Caso de uso |
|------|-----------|--------------|
| UC-01 | Leitor | Criar conta e autenticar-se no aplicativo |
| UC-02 | Leitor | Navegar pelo feed de notícias por categoria |
| UC-03 | Leitor | Buscar uma notícia por palavra-chave |
| UC-04 | Leitor | Visualizar o detalhe de uma notícia, incluindo selo de veracidade e fonte |
| UC-05 | Leitor | Denunciar uma notícia com um motivo estruturado |
| UC-06 | Leitor | Favoritar uma notícia para leitura posterior/offline |
| UC-07 | Validador | Consultar a fila de notícias pendentes de checagem |
| UC-08 | Validador | Atribuir um status de veracidade a uma notícia, com justificativa |
| UC-09 | Leitor/Validador | Encerrar a sessão (logout) com segurança |

---

## 3. Requisitos Funcionais (RFs)

### 3.1 Autenticação e Gestão de Perfil

- **RF-001**: O sistema MUST permitir cadastro de novo usuário com e-mail, senha e nome
  completo.
- **RF-002**: O sistema MUST permitir login via e-mail e senha, retornando um token de sessão
  a ser mantido pelo `UserSessionService`.
- **RF-003**: O sistema MUST manter um estado de sessão explícito e observável
  (`UserSessionStatus.authenticated` / `unauthenticated`), refletido imediatamente na UI (ex.:
  navegação bloqueia telas autenticadas quando `unauthenticated`).
- **RF-004**: O sistema MUST permitir logout explícito, que MUST limpar token, identificador
  de usuário e reverter o status de sessão para `unauthenticated`.
- **RF-005**: O sistema MUST permitir que o usuário edite dados básicos do próprio perfil
  (nome, categorias de interesse).
- **RF-006**: O sistema MUST oferecer fluxo de recuperação de senha ("esqueci minha senha")
  via e-mail cadastrado.
- **RF-007**: O sistema MUST diferenciar o papel do usuário (Leitor vs. Validador) e MUST
  restringir funcionalidades de validação (RF-016) exclusivamente ao papel Validador.

### 3.2 Feed e Consumo de Notícias

- **RF-008**: O sistema MUST exibir um feed paginado de notícias, ordenado por data de
  publicação (mais recente primeiro) por padrão.
- **RF-009**: O sistema MUST permitir filtrar o feed por categoria (ex.: política, saúde,
  economia, tecnologia).
- **RF-010**: O sistema MUST permitir busca textual por título ou palavra-chave dentro do
  feed.
- **RF-011**: O sistema MUST exibir uma tela de detalhe da notícia contendo: título, corpo/
  resumo, veículo/fonte original, data de publicação e autor (quando disponível).
- **RF-012**: O sistema MUST exibir, tanto no card do feed quanto no detalhe, o selo de
  veracidade atual da notícia (ver RF-014).
- **RF-013**: O sistema MUST permitir favoritar/salvar uma notícia para consulta posterior,
  inclusive offline (ver RNF-002).

### 3.3 Validação e Confiabilidade

- **RF-014**: O sistema MUST associar a cada notícia um status de veracidade pertencente a um
  conjunto fechado e nomeado (`VeracityStatus`): `verified` (verificada), `unverified` (não
  verificada — padrão), `underReview` (em análise) e `false` (falsa). É proibido representar
  esse status como string livre (alinhado à Seção V da constituição).
- **RF-015**: O sistema MUST permitir que um Leitor denuncie uma notícia, exigindo a seleção
  de um motivo estruturado (`ReportReason`: ex. `misleadingTitle`, `fabricatedContent`,
  `outOfContext`, `unreliableSource`, `other`) — nunca um campo de texto livre isolado como
  único motivo.
- **RF-016**: O sistema MUST permitir que um Validador liste notícias pendentes/denunciadas e
  registre uma decisão de veracidade, com justificativa textual obrigatória.
- **RF-017**: O sistema MUST manter histórico auditável de mudanças de status de veracidade de
  uma notícia (quem decidiu, quando, status anterior e novo).
- **RF-018**: O sistema MUST exibir, no detalhe da notícia, as fontes/checagens associadas
  quando existentes (ex.: links de referência usados na decisão do validador).

---

## 4. Requisitos Não-Funcionais (RNFs)

- **RNF-001 (Desempenho)**: O feed inicial MUST ser exibido (dado cache ou resposta de API já
  recebida) em até 2 segundos em condição de rede 4G/Wi-Fi típica; a paginação subsequente
  MUST carregar a próxima página sem bloquear a rolagem da lista já carregada.
- **RNF-002 (Offline-first / cache local)**: O sistema MUST persistir localmente o último
  feed obtido com sucesso e as notícias favoritadas, permitindo leitura completa sem conexão.
  Ações que exigem rede (denunciar, favoritar-sincronizar, checar) MUST ser desabilitadas ou
  enfileiradas com aviso claro quando o dispositivo estiver offline.
- **RNF-003 (Usabilidade)**: A navegação entre feed → detalhe → denúncia MUST ser possível em
  no máximo 3 toques a partir da tela inicial. O app MUST suportar tema claro e escuro através
  do `app_theme` já existente no `core/`.
- **RNF-004 (Acessibilidade)**: Todo elemento interativo MUST possuir rótulo semântico
  (`Semantics`/`label`) compatível com leitores de tela; contraste de cor MUST atender no
  mínimo o nível AA do WCAG 2.1; o app MUST respeitar a escala de fonte do sistema
  operacional.
- **RNF-005 (Consumo eficiente da API via Dio)**: Toda comunicação HTTP MUST passar pelo
  `ApiClient` único (Seção V da constituição), reaproveitando a mesma instância de `Dio`
  (timeout de conexão/recebimento configurado, hoje 10s). Buscas textuais (RF-010) MUST usar
  debounce e `CancelToken` para cancelar requisições obsoletas antes de disparar uma nova.
- **RNF-006 (Internacionalização)**: Toda string visível ao usuário MUST vir de
  `easy_localization`, sem literais hardcoded na UI (alinhado à Seção IV da constituição).
- **RNF-007 (Segurança de sessão)**: O token de sessão MUST NOT ser exposto em logs, mesmo em
  modo debug. Enquanto a persistência segura entre reinicializações do app (ex.: armazenamento
  criptografado local) não estiver implementada, isso MUST ser tratado como lacuna conhecida e
  registrado no plano técnico correspondente — não como comportamento aceito silenciosamente.

---

## 5. Regras de Negócio e Critérios de Aceite

- **RN-001 (Validação de e-mail/senha)**: Um cadastro (RF-001) só é aceito se o e-mail tiver
  formato válido e a senha tiver no mínimo 8 caracteres, contendo ao menos uma letra e um
  número. Falha nessa validação MUST bloquear o envio antes de qualquer chamada de rede.
- **RN-002 (Veracidade nunca nasce "verificada")**: Toda notícia nova entra no sistema com
  `VeracityStatus.unverified` por padrão. Somente uma ação explícita de um Validador (RF-016)
  MUST poder alterar esse status.
- **RN-003 (Denúncia é idempotente por usuário)**: Um mesmo usuário Leitor MUST NOT conseguir
  registrar mais de uma denúncia ativa para a mesma notícia; uma segunda tentativa MUST ser
  rejeitada com mensagem informativa, não com erro genérico.
- **RN-004 (Autorização por papel)**: Toda ação de validação (RF-016) requisitada por um
  usuário cujo papel não seja Validador MUST ser rejeitada antes de qualquer efeito colateral,
  com mensagem clara de permissão insuficiente.
- **RN-005 (Sessão governa navegação)**: Sempre que `UserSessionStatus == unauthenticated`,
  qualquer tentativa de acessar uma funcionalidade que exija autenticação (favoritar, denunciar,
  editar perfil, fila de validação) MUST redirecionar para a tela de login antes de qualquer
  chamada de API.
- **RN-006 (Fila priorizada por volume de denúncias)**: Uma notícia cujo número de denúncias
  ativas ultrapassar um limiar configurável MUST ser promovida automaticamente para o topo da
  fila de checagem do Validador (RF-016), sem exigir ação manual de priorização.

**Critério de aceite geral**: uma User Story dos Casos de Uso (Seção 2.3) só é considerada
aceita quando (a) o critério RN correspondente é validado por teste automatizado (TDD, Seção
III da constituição) e (b) o comportamento de erro associado (Seção 6) também está coberto.

---

## 6. Casos de Borda e Fluxos de Exceção

- **CB-001 (Sem conexão ao abrir o app)**: Se não houver conexão e existir cache local
  (RNF-002), o sistema MUST exibir o feed em cache com um indicador visível de "modo offline"
  e MUST desabilitar ações que exigem rede.
- **CB-002 (Sem conexão durante uma ação de rede)**: Toda chamada que falhar por ausência de
  conexão MUST resultar em uma `ApiException` com mensagem amigável ("Sem conexão com a
  internet. Verifique sua rede.") — nunca uma exceção técnica (`DioException`,
  `SocketException`) exposta à UI.
- **CB-003 (Token expirado / 401)**: Qualquer resposta 401 MUST disparar logout automático via
  `UserSessionService.logout()`, seguido de redirecionamento para a tela de login com a
  mensagem "Sua sessão expirou, faça login novamente." O usuário MUST NOT permanecer em uma
  tela autenticada após um 401.
- **CB-004 (Erro inesperado do servidor, 5xx)**: Deve ser mapeado para `ApiException` com
  mensagem genérica amigável ("Não foi possível completar a ação. Tente novamente mais
  tarde."); detalhes técnicos (status code, corpo bruto) só MUST aparecer em log quando
  `EnvironmentConfig.debugMode` estiver ativo.
- **CB-005 (Resposta malformada / campo ausente)**: Falhas de parsing (`TypeError`,
  `FormatException`) ao converter a resposta em modelo tipado MUST ser capturadas na camada de
  dados e convertidas em `ApiException`; é proibido deixar uma exceção de parsing vazar até a
  UI sem tratamento (alinhado à Seção V da constituição).
- **CB-006 (Denúncia duplicada)**: Ao tentar denunciar uma notícia já denunciada pelo mesmo
  usuário (RN-003), o sistema MUST informar "Você já denunciou esta notícia" sem chamar a API
  novamente, quando o estado de denúncia do usuário já for conhecido localmente.
- **CB-007 (Busca sem resultados)**: Uma busca (RF-010) sem correspondências MUST exibir um
  estado vazio explicativo ("Nenhuma notícia encontrada para sua busca"), nunca uma tela em
  branco ou um erro.
- **CB-008 (Fim da paginação)**: Ao rolar além do último item do feed, o sistema MUST parar de
  disparar novas requisições de página e MUST NOT duplicar itens já exibidos.
- **CB-009 (Ação de Validador sem permissão)**: Uma tentativa de acesso à fila de validação
  (RF-016) por um usuário Leitor MUST ser bloqueada na própria navegação (RN-004), sem sequer
  chegar a fazer a chamada de rede correspondente.

---

## 7. Suposições e Dependências

- Assume-se que existirá um backend/API própria (fora do escopo deste documento) que fornece
  os endpoints de notícias, denúncia e validação consumidos via `ApiClient`.
- Assume-se conectividade instável, mas não ausência permanente de rede — o modo offline
  (RNF-002) cobre janelas de indisponibilidade, não uso 100% offline por tempo indeterminado.
- O papel de Administrador (gestão de usuários/validadores, banimento, configuração do limiar
  de RN-006) é considerado fora do escopo da v1 e tratado como evolução futura.
- A definição do mecanismo de persistência segura de token entre reinicializações (RNF-007)
  fica para o plano técnico (`plan.md`), não é decidida neste documento de negócio.

---

## Governança deste documento

Este documento descreve requisitos de **negócio e produto**; conflitos entre um RF/RNF/RN
aqui definido e uma regra técnica da [constitution.md](constitution.md) MUST ser resolvidos
sem violar a constituição — se um requisito de negócio exigir violar um princípio técnico
(ex.: um RF que só seria viável acoplando UI a `Dio` diretamente), o requisito MUST ser
redesenhado, não a constituição contornada. Alterações de escopo (novos RFs, mudança de
personas) exigem atualizar a versão deste documento e registrar a mudança em uma futura seção
de changelog.

**Versão**: 1.0.0 | **Criado em**: 2026-09-07 | **Última alteração**: 2026-09-07
