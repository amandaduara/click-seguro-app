# SafeNews — Especificação de Produto

**Projeto**: Click Seguro (TCC) — Aplicativo **SafeNews**

**Versão**: 2.0.0

**Criado em**: 2026-09-07

**Status**: Rascunho (Draft)

**Alinhado a**: [constitution.md](constitution.md) v1.1.0. Este documento descreve O QUE o
sistema faz. O COMO (arquitetura, stack, camadas) é regido pela constituição e detalhado em
[plan.md](plan.md). A fonte visual é o wireframe do Lovable (divisão em trilhas A/B/C, reproduzida
em [tasks.md](tasks.md)).

---

## 1. Visão do Produto e Problema

### 1.1 Problema

Golpes digitais (falso parente no WhatsApp, falsa central do banco, Pix, links de phishing) e
notícias falsas atingem com mais força o público **idoso**, que tem menos familiaridade com o
ambiente digital e mais dificuldade de leitura em telas pequenas. Quando esse usuário é
abordado, faltam três coisas:

- informação confiável e fácil de consumir sobre os golpes e as notícias do momento;
- treino prático para reconhecer uma abordagem suspeita antes de cair nela;
- um caminho rápido para pedir ajuda (polícia, banco, um familiar) quando algo acontece.

### 1.2 Proposta de valor do SafeNews

O SafeNews é um aplicativo Flutter, pensado para o público idoso, que reúne três frentes num
único lugar:

- **Informar:** feed de notícias por categoria, com selo de veracidade, Reels para consumo
  rápido e notificações de alertas.
- **Educar:** trilha de atividades em módulos, com lições curtas, leitura em voz alta e
  exercícios práticos (quiz, verdadeiro/falso, checklist, cenário, ordenação).
- **Socorrer:** central de ajuda com contatos oficiais e contatos pessoais de confiança, com
  ligação em um toque.

Tudo isso com **acessibilidade de primeira classe**: fonte ampliável, alto contraste e leitura
em voz alta.

### 1.3 Fora de escopo (v1)

- **Checagem colaborativa de notícias (v2):** denúncia de notícia pelo leitor, papel de
  Validador, fila de checagem e histórico auditável de vereditos. Na v1 o selo de veracidade
  vem pronto da API e o app só o exibe (ver §8, Evoluções futuras).
- Notificações push (a v1 tem apenas a lista de notificações dentro do app).
- Rede social entre usuários (comentários, seguir, ranking público).
- Produção de conteúdo dentro do app (notícias, módulos e lições vêm da API).
- Painel de administração.

---

## 2. Personas e Casos de Uso

### 2.1 Persona principal — Usuário idoso cadastrado

Pessoa de 60 anos ou mais, usa o celular para WhatsApp e banco, tem receio de golpes e prefere
textos grandes e explicações simples.

**Objetivos:** entender os golpes do momento, treinar para reconhecê-los, acompanhar o próprio
progresso e ter a quem recorrer rapidamente.

### 2.2 Persona secundária — Visitante

Qualquer pessoa que abre o app sem criar conta (inclusive um familiar testando o app para
indicar a alguém). Pode ler e praticar, mas não guarda nada entre sessões.

### 2.3 Casos de uso

| ID | Persona | Caso de uso | Trilha |
|------|-----------|--------------|--------|
| UC-01 | Todos | Ver o splash e o onboarding na primeira abertura | A1 |
| UC-02 | Todos | Criar conta, entrar, recuperar senha ou seguir como visitante | A2 |
| UC-03 | Todos | Navegar pelo feed por categoria e buscar notícias | A3 |
| UC-04 | Todos | Consumir notícias em formato Reels | A4 |
| UC-05 | Todos | Ler (ou ouvir) uma notícia completa, compartilhar e ir para atividades relacionadas | A5 |
| UC-06 | Cadastrado | Salvar notícias e curtir Reels | A3–A5 |
| UC-07 | Cadastrado | Ver e marcar notificações como lidas | A6 |
| UC-08 | Todos | Acompanhar o painel de atividades e abrir um módulo | B1 |
| UC-09 | Todos | Ler (ou ouvir) as lições de um módulo | B2 |
| UC-10 | Todos | Responder os exercícios e receber feedback | B3 |
| UC-11 | Todos | Concluir um módulo (visitante é convidado a criar conta) | B4 |
| UC-12 | Todos | Ligar para um contato oficial ou pessoal pela central de ajuda | B6 |
| UC-13 | Todos | Cadastrar contatos pessoais de confiança com foto | B6 |
| UC-14 | Cadastrado | Ver perfil, estatísticas e conquistas; editar dados | B7 |
| UC-15 | Todos | Ajustar configurações e sair da conta | B8 |
| UC-16 | Todos | Ajustar tamanho de fonte, alto contraste e leitura em voz alta | B9 |

---

## 3. Requisitos Funcionais (RFs)

### 3.1 Entrada no app (A1)

- **RF-001**: O sistema MUST exibir um splash ao abrir o app enquanto a sessão e as preferências
  são restauradas.
- **RF-002**: O sistema MUST exibir o onboarding (3 slides com indicador de página, botões
  "Continuar"/"Começar" e "Pular") **apenas na primeira abertura** do aparelho (RN-004).

### 3.2 Autenticação e sessão (A2)

- **RF-003**: O sistema MUST permitir cadastro com nome, e-mail e senha.
- **RF-004**: O sistema MUST permitir login com e-mail e senha, alternando com o cadastro na
  mesma tela, com opção de mostrar/ocultar a senha.
- **RF-005**: O sistema MUST permitir **entrar como visitante**, sem conta (RN-003).
- **RF-006**: O sistema MUST oferecer recuperação de senha pelo e-mail cadastrado.
- **RF-007**: A sessão MUST sobreviver ao fechamento do app e MUST ter estado observável
  (`UserSessionStatus`: `authenticated`, `unauthenticated`, `guest`).
- **RF-008**: O sistema MUST permitir sair da conta, limpando token e dados de sessão.

### 3.3 Notícias (A3, A4, A5)

- **RF-009**: O feed MUST exibir saudação com o nome do usuário (ou genérica para visitante),
  filtros por categoria, um carrossel horizontal de Reels e a lista de notícias.
- **RF-010**: O feed MUST ser paginado, ordenado da mais recente para a mais antiga.
- **RF-011**: O sistema MUST permitir buscar notícias por texto, com estado vazio explicativo.
- **RF-012**: Todo card e todo detalhe de notícia MUST exibir o selo de veracidade
  (`VeracityStatus`: `verified`, `unverified`, `underReview`, `fake`), vindo da API (RN-002).
- **RF-013**: A tela de Reels MUST exibir uma notícia por vez em tela cheia (imagem, título,
  resumo), com navegação vertical por gesto de arrastar e também por botões, e ações de
  curtir, salvar e abrir a fonte.
- **RF-014**: O detalhe da notícia MUST exibir título, imagem, texto completo, fonte, data e
  autor (quando houver).
- **RF-015**: O detalhe MUST oferecer **leitura em voz alta** do conteúdo, com controle de
  velocidade (lenta, normal, rápida).
- **RF-016**: O detalhe MUST permitir compartilhar a notícia pelo menu nativo do aparelho.
- **RF-017**: O detalhe MUST permitir abrir a fonte original no navegador externo.
- **RF-018**: O detalhe MUST exibir um bloco de **atividades relacionadas** que leva ao módulo
  correspondente na trilha de atividades.
- **RF-019**: O usuário cadastrado MUST poder **salvar** (favoritar) notícias e **curtir** Reels.

### 3.4 Notificações (A6)

- **RF-020**: O sistema MUST listar as notificações do usuário agrupadas por data ("Hoje",
  "Ontem", "Anteriores").
- **RF-021**: O topo do app MUST exibir um contador de notificações não lidas.
- **RF-022**: O usuário MUST poder marcar uma notificação como lida (ao abri-la) e marcar todas
  como lidas.

### 3.5 Atividades educativas (B1, B2, B3, B4)

- **RF-023**: O painel de atividades MUST exibir o progresso geral, a grade de módulos e o
  status de cada módulo (não iniciado, em andamento, concluído).
- **RF-024**: Cada módulo MUST ter lições apresentadas passo a passo, com avanço e retorno,
  leitura em voz alta e marcação individual de lição lida.
- **RF-025**: Cada módulo MUST ter exercícios dos tipos: múltipla escolha, verdadeiro/falso,
  checklist, cenário (situação simulada com escolha de atitude) e ordenação de passos.
- **RF-026**: Os exercícios MUST ter um rodapé fixo com o botão de confirmar resposta e um
  painel deslizante de feedback (acerto ou erro, com explicação).
- **RF-027**: As alternativas de múltipla escolha e cenário MUST ser embaralhadas a cada
  tentativa.
- **RF-028**: O sistema MUST calcular e guardar a pontuação por módulo (RN-005).
- **RF-029**: Ao final do módulo o sistema MUST exibir uma tela de conclusão com a pontuação e a
  opção de compartilhar a conquista.
- **RF-030**: O visitante MUST ver um aviso convidando a criar conta para salvar o progresso
  (RN-006).

### 3.6 Central de ajuda (B6)

- **RF-031**: A central MUST ter duas abas: "Oficiais" (polícia, bancos, Procon, canais
  anti-golpe) e "Meus contatos".
- **RF-032**: Todo contato MUST ter ação de **ligar em um toque**.
- **RF-033**: O usuário MUST poder cadastrar, editar e remover contatos pessoais (nome,
  telefone, parentesco opcional e foto circular da galeria ou câmera).
- **RF-034**: Os contatos pessoais e as fotos MUST ser salvos **somente no aparelho** (RN-007)
  e MUST continuar disponíveis após fechar o app.

### 3.7 Perfil (B7)

- **RF-035**: O perfil MUST exibir cartão do usuário (nome, foto, selo de nível),
  estatísticas (módulos concluídos, notícias salvas, pontuação), conquistas e atalhos.
- **RF-036**: O usuário MUST poder editar seus dados (nome) e trocar a foto de perfil.

### 3.8 Configurações (B8)

- **RF-037**: As configurações MUST listar as seções Conta ("Dados pessoais"), Notificações,
  Segurança ("Alterar senha") e Acessibilidade, e a ação de sair da conta. Toda linha MUST
  levar a uma tela funcional (nenhuma linha "morta").

### 3.9 Acessibilidade (B9)

- **RF-038**: O usuário MUST poder escolher o tamanho da fonte do app (pelo menos 3 níveis
  acima do padrão), aplicado em todas as telas.
- **RF-039**: O usuário MUST poder ativar um tema de **alto contraste**.
- **RF-040**: O usuário MUST poder ativar a **leitura automática em voz alta** do conteúdo
  principal ao abrir o detalhe de uma notícia ou uma lição.
- **RF-041**: As preferências de acessibilidade MUST ser salvas no aparelho e aplicadas já no
  splash da próxima abertura.

---

## 4. Requisitos Não-Funcionais (RNFs)

- **RNF-001 (Desempenho)**: O feed inicial MUST aparecer em até 2 s em 4G/Wi-Fi típico (cache ou
  resposta da API). A paginação MUST carregar sem travar a rolagem.
- **RNF-002 (Offline)**: O último feed carregado, as notícias salvas e a central de ajuda
  (contatos oficiais e pessoais) MUST funcionar sem internet. Ações que exigem rede MUST ficar
  desabilitadas com aviso claro.
- **RNF-003 (Usabilidade para idosos)**: Alvos de toque MUST ter no mínimo 48×48 dp, o texto base
  MUST ter no mínimo 16 sp, os textos MUST usar linguagem simples e toda ação destrutiva
  (remover contato, sair) MUST pedir confirmação.
- **RNF-004 (Acessibilidade)**: Todo elemento interativo MUST ter rótulo semântico para
  TalkBack/VoiceOver, o contraste MUST atender WCAG 2.1 AA (e AAA no tema de alto contraste) e o
  app MUST respeitar também a escala de fonte do sistema operacional.
- **RNF-005 (Consumo da API)**: Toda comunicação HTTP MUST passar pelo `ApiClient` único. A busca
  MUST usar debounce e cancelar a requisição anterior.
- **RNF-006 (Internacionalização)**: Todo texto visível MUST vir de `easy_localization`
  (pt-BR obrigatório; en-US mantido em paralelo).
- **RNF-007 (Segurança de sessão)**: O token MUST ficar em armazenamento criptografado do
  aparelho e MUST NOT aparecer em logs.
- **RNF-008 (Privacidade / LGPD)**: Contatos pessoais e fotos de contato MUST NOT ser enviados a
  nenhum servidor.

---

## 5. Regras de Negócio

- **RN-001 (Senha e e-mail)**: O cadastro só é enviado se o e-mail tiver formato válido e a senha
  tiver no mínimo 8 caracteres, com ao menos uma letra e um número. A validação MUST acontecer
  antes de qualquer chamada de rede.
- **RN-002 (Veracidade é da API)**: O app nunca altera o `VeracityStatus` de uma notícia. Valor
  desconhecido vindo da API MUST ser tratado como `unverified`.
- **RN-003 (Limites do visitante)**: O visitante pode ler notícias, ver Reels, fazer atividades e
  usar a central de ajuda. Salvar notícia, curtir, notificações, perfil e editar dados exigem
  conta: ao tentar, o app MUST mostrar um convite para entrar ou se cadastrar, **sem** chamar a
  API.
- **RN-004 (Onboarding único)**: Depois de concluído ou pulado, o onboarding MUST NOT voltar a
  aparecer naquele aparelho (flag local).
- **RN-005 (Conclusão e pontuação)**: Um módulo está concluído quando todas as lições foram
  marcadas como lidas e todos os exercícios foram respondidos. A pontuação é
  `acertos na primeira tentativa / total de exercícios`, e vale a melhor pontuação obtida.
- **RN-006 (Progresso do visitante)**: O progresso do visitante vale só para a sessão atual.
  Ao concluir um módulo como visitante, o app MUST exibir o aviso de login (RF-030) antes da
  tela de conclusão.
- **RN-007 (Contatos locais)**: Contatos pessoais pertencem ao aparelho, não à conta: sair da
  conta MUST NOT apagar os contatos.
- **RN-008 (Nível do perfil)**: O selo de nível do perfil é derivado do número de módulos
  concluídos (faixas definidas pela API; ver [api-contract.md](api-contract.md)).

**Critério de aceite geral**: um caso de uso só é aceito quando a RN correspondente tem teste
automatizado (TDD, Seção III da constituição) e o comportamento de erro associado (§6) também
está coberto.

---

## 6. Casos de Borda e Fluxos de Exceção

- **CB-001 (Sem conexão ao abrir)**: Com cache disponível, o feed MUST abrir do cache com
  indicador de "modo offline". Sem cache, MUST mostrar estado de erro com "Tentar novamente".
- **CB-002 (Sem conexão durante ação)**: MUST resultar em `ConnectionFailure` com a mensagem
  "Sem conexão com a internet. Verifique sua rede."
- **CB-003 (Sessão expirada / 401)**: MUST encerrar a sessão (`UnauthorizedFailure`) e levar ao
  login com "Sua sessão expirou, faça login novamente."
- **CB-004 (Erro do servidor)**: 5xx e erros não tratados MUST virar `ServerFailure` com
  mensagem genérica. Detalhes técnicos só em log com `DEBUG_MODE`.
- **CB-005 (Resposta malformada)**: Falha de parse MUST virar `ServerFailure`, nunca travar a tela.
- **CB-006 (Busca sem resultado / filtro vazio)**: MUST exibir estado vazio explicativo.
- **CB-007 (Fim da paginação)**: MUST parar de pedir páginas e MUST NOT duplicar itens.
- **CB-008 (Voz indisponível)**: Se o aparelho não tiver mecanismo de voz, os botões de ouvir
  MUST ficar ocultos, sem erro.
- **CB-009 (Aparelho sem telefonia)**: Em tablet ou sem chip, "Ligar" MUST mostrar o número em
  destaque com opção de copiar.
- **CB-010 (Permissão de câmera/galeria negada)**: O contato MUST poder ser salvo sem foto, com
  avatar de iniciais, e o app MUST explicar como liberar a permissão.
- **CB-011 (Visitante em ação restrita)**: Ver RN-003: convite para entrar, sem chamada de rede.
- **CB-012 (Módulo sem exercícios ou lição vazia na API)**: O módulo MUST ser exibido com as
  partes disponíveis, sem travar o fluxo de conclusão.

---

## 7. Suposições e Dependências

- Existe uma **API própria** do projeto que fornece autenticação, notícias, Reels, favoritos,
  curtidas, notificações, módulos de atividades, progresso e perfil. O contrato esperado pelo
  app está em [api-contract.md](api-contract.md) e **precisa ser confirmado** com a API real
  antes de cada integração (Passo 0 do guia de integração).
- A lista de contatos oficiais é embarcada no app (assets) para funcionar offline em uma
  emergência (RNF-002).
- O onboarding e o splash já existem no código (módulos `splash` e `onboarding`), assim como o
  design system (`SafeButton`, `SafeCard`, `SafeTextField`, `SafeBadge`) e o style guide.

---

## 8. Evoluções futuras (v2)

Requisitos que existiam na v1.0.x desta especificação e foram adiados. Ficam registrados para
não serem perdidos:

- Denúncia de notícia pelo leitor, com motivo estruturado (`ReportReason`) e bloqueio de
  denúncia duplicada.
- Papel de Validador, fila de checagem priorizada pelo volume de denúncias e registro de
  veredito com justificativa obrigatória.
- Histórico auditável de mudanças de `VeracityStatus` e exibição das fontes da checagem.
- Notificações push.

---

## Governança deste documento

Este documento descreve requisitos de **negócio e produto**. Se um requisito exigir violar a
[constitution.md](constitution.md), o requisito MUST ser redesenhado. Mudanças de escopo exigem
nova versão e registro no changelog.

**Versão**: 2.0.0 | **Criado em**: 2026-09-07 | **Última alteração**: 2026-09-26

## Changelog

- **2.0.0 (2026-09-26)**: MAJOR, porque o escopo passou a seguir o wireframe do Lovable. Foco
  no público idoso e proteção contra golpes. Entram modo visitante, Reels, notificações,
  trilha de atividades com exercícios, central de ajuda, perfil, configurações e
  acessibilidade. Checagem colaborativa (denúncia, Validador, fila, histórico) foi movida para
  a v2 (§8). Todos os IDs de RF/RN/CB foram renumerados.
- **1.0.1 (2026-09-26)**: `VeracityStatus.false` renomeado para `fake`. CB-002/004/005 passaram
  a citar as `Failure`.
