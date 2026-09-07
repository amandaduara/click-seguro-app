<!--
SYNC IMPACT REPORT
==================
Version change: 1.0.0 (Spec Kit genérico/specify-cli) → 1.0.0 (Click Seguro) → 1.0.1
Bump rationale (1.0.0 Click Seguro): Substituição completa do conteúdo herdado do
  template do Spec Kit por uma constituição própria do projeto Click Seguro (TCC),
  derivada da stack e dos padrões já presentes no código-fonte (GetIt, Dio,
  Provider/ChangeNotifier, ModuleInterface, ApiException/ExceptionApiClient).
  Reinicia como 1.0.0 por ser a primeira ratificação específica deste projeto.
Bump rationale (1.0.1): PATCH — nenhum princípio mudou de sentido. Registra a
  resolução dos dois itens de dívida técnica apontados no Diagnóstico: (1)
  `BaseApiClient`/`ExceptionApiClient`/`MethodApiClient` (código morto, sem
  consumidores) foram removidos e `ApiClient`/`ApiException` foi confirmado como
  padrão canônico único, com `ApiClient` e `UserSessionService` agora registrados
  no `GetIt` via `CommonModule`; (2) `.env` foi adicionado ao `.gitignore`
  (arquivo nunca chegou a ser commitado, logo nenhum segredo foi comprometido).
  Referências de exemplo aos tipos removidos foram trocadas por exemplos ainda
  presentes no código (`UserSessionStatus`).

Princípios definidos:
  I.   Clean Architecture & Modularização Obrigatória
  II.  SOLID, DRY e KISS
  III. Test-Driven Development (TDD) (NÃO NEGOCIÁVEL)
  IV.  Stack Tecnológica Oficial e Injeção de Dependência
  V.   Tratamento de Erros Tipado e Sem Strings Mágicas

Seções adicionadas:
  - Padrões de Código e Convenções de Nomenclatura
  - Regras Globais de Segurança e Qualidade
  - Diagnóstico do Estado Atual do Repositório
  - Governança

Follow-up TODOs: nenhum.
-->

# Click Seguro — Constituição do Projeto

O Click Seguro é uma aplicação Flutter multiplataforma desenvolvida como Trabalho de
Conclusão de Curso (TCC). Este documento define as leis de engenharia inegociáveis do
projeto, seguindo os princípios de Spec-Driven Development (SDD). Toda especificação,
plano ou tarefa gerada pelo Spec Kit — e todo código submetido por qualquer
colaborador ou agente de IA — MUST estar em conformidade com este documento. Em caso
de conflito entre esta constituição e qualquer outra convenção, documento ou hábito
anterior do repositório, esta constituição prevalece.

## Visão Geral

O código deve ser tratado como um artefato acadêmico e profissional simultaneamente:
correto, testável e sustentável por uma única pessoa ao longo de todo o ciclo do TCC.
Não é permitido sacrificar arquitetura, testes ou segurança em nome de prazo. Onde
houver conflito entre "funciona agora" e "está certo", a solução correta MUST
prevalecer.

## Princípios Fundamentais

### I. Clean Architecture & Modularização Obrigatória

O projeto MUST ser organizado em módulos de funcionalidade (feature modules), cada
um isolado sob `lib/modules/<nome_do_modulo>/`, e em camadas que não se misturam.

- **Um módulo por funcionalidade de negócio.** Cada módulo MUST implementar
  `ModuleInterface` (`providers(GetIt injector)` e `registerServices(GetIt injector)`)
  e ser registrado através do `ModuleManager`. É proibido registrar serviços ou
  providers fora desse contrato.
- **Camadas obrigatórias por módulo:** `ui/` (widgets e controllers de apresentação),
  uma camada de domínio/regra de negócio quando aplicável, e uma camada de dados
  (clientes de API, repositórios, serviços). Um controller de UI MUST NOT instanciar
  `Dio`, `ApiClient` ou qualquer classe de infraestrutura diretamente — a dependência
  MUST ser injetada via `GetIt`.
- **`lib/core/` é exclusivo para elementos verdadeiramente transversais** (tema,
  i18n, widgets de design system, spacing). Regra de negócio de um módulo específico
  MUST NOT ser colocada em `core/`.
- **Dependência de módulo para módulo é proibida por importação direta de
  implementação.** Um módulo que precisa de uma capacidade de outro MUST consumi-la
  através de um serviço registrado no `GetIt` (ex.: `UserSessionService`), nunca
  importando arquivos internos de outro módulo.

**Racional:** o padrão de módulos já presente no repositório (`ModuleInterface`,
`ModuleManager`, `CommonModule`, `AuthenticationModule`) é o que permite que o
projeto cresça por funcionalidade sem que camadas de UI, domínio e dados se
contaminem — condição necessária para que o TCC seja avaliado como arquitetura
limpa e não como um único módulo monolítico disfarçado de vários arquivos.

### II. SOLID, DRY e KISS

Todo código novo MUST respeitar os cinco princípios SOLID, o princípio DRY (Don't
Repeat Yourself) e o princípio KISS (Keep It Simple, Stupid), nesta ordem de
prioridade quando houver conflito entre eles.

- **Responsabilidade única.** Uma classe MUST ter um único motivo para mudar. Um
  `Controller` trata apenas de estado de apresentação; um `Service` trata apenas de
  uma capacidade de negócio; um `ApiClient` trata apenas de comunicação HTTP.
- **Interfaces sobre implementações.** Serviços expostos via `GetIt` SHOULD ser
  registrados por um tipo abstrato (interface ou classe abstrata) quando houver mais
  de uma implementação possível (ex.: ambiente de teste vs. produção), permitindo
  substituição sem alterar o consumidor (Dependency Inversion).
- **Duplicação é proibida.** É proibido copiar e colar um bloco de lógica de
  validação, formatação, mapeamento de erro ou chamada HTTP em mais de um lugar. A
  lógica repetida MUST ser extraída para um método, classe utilitária ou serviço
  compartilhado em `common/`.
- **Simplicidade é um requisito, não uma preferência.** É proibido introduzir
  abstrações, camadas, generics ou padrões de projeto (Factory, Strategy, etc.) para
  um caso de uso hipotético ainda não existente. Resolva o problema atual da forma
  mais direta possível; refatore quando o segundo caso de uso real aparecer.

**Racional:** em um projeto de TCC mantido por um desenvolvedor solo, complexidade
acidental é o maior risco ao cronograma. SOLID/DRY/KISS aqui não são adornos
acadêmicos — são o que mantém o código revisável e defensável perante a banca.

### III. Test-Driven Development (TDD) (NÃO NEGOCIÁVEL)

Nenhuma unidade de lógica de negócio MUST ser considerada concluída sem teste
automatizado correspondente.

- **Ciclo Red-Green-Refactor.** Para toda nova regra de negócio, controller ou
  serviço, o teste MUST ser escrito antes ou junto da implementação, cobrindo pelo
  menos: caminho feliz, um caminho de erro e um caso de borda relevante.
- **Cobertura mínima obrigatória:** toda classe em `services/`, todo `Controller` e
  todo mapeamento de exceção (`ApiException`) MUST possuir teste em `test/`,
  espelhando o caminho do arquivo em `lib/`.
- **Testes MUST ser determinísticos e offline.** Nenhum teste pode depender de
  chamada de rede real. Toda chamada HTTP MUST ser simulada (mock/fake do `Dio` ou
  do `ApiClient`); dependências de `GetIt` MUST ser resetadas e reconfiguradas por
  teste (`setUp`/`tearDown`), nunca compartilhadas entre testes.
- **Widget tests para UI crítica.** Fluxos de UI com lógica condicional (ex.: tela
  de autenticação) MUST ter ao menos um widget test cobrindo o estado de erro e o
  estado de sucesso.
- **CI é um portão, não uma sugestão.** Um Pull Request com testes quebrando ou sem
  teste para uma regra de negócio nova MUST NOT ser mesclado.

**Racional:** TDD é o critério mais objetivo e mais facilmente demonstrável perante
a banca de que o software funciona conforme especificado — e é a proteção mínima
contra regressão em um projeto sem equipe de QA dedicada.

### IV. Stack Tecnológica Oficial e Injeção de Dependência

A stack tecnológica abaixo é a única oficialmente suportada. Introduzir uma
biblioteca concorrente para o mesmo propósito é proibido sem emenda a esta
constituição.

- **Linguagem/Framework:** Flutter + Dart, seguindo a versão do SDK travada em
  `pubspec.yaml` (`environment.sdk`).
- **Requisições HTTP:** `Dio` é o único cliente HTTP permitido, sempre encapsulado
  por uma camada de `ApiClient` própria do projeto — código de tela ou de serviço
  MUST NOT chamar `Dio` diretamente.
- **Service Locator / Injeção de Dependência:** `GetIt` é o único mecanismo de DI.
  Toda dependência injetável (serviço, repositório, cliente de API) MUST ser
  registrada em `registerServices` do módulo correspondente, nunca instanciada com
  `new`/construtor direto dentro de um controller ou widget.
- **Gerenciamento de estado:** `Provider` + `ChangeNotifier` é a solução
  oficialmente adotada (via `SingleChildWidget` retornado em `providers()` de cada
  módulo). Um `Controller` de UI MUST estender `ChangeNotifier` e expor estado
  através de getters — é proibido expor `ChangeNotifier` mutável publicamente ou
  chamar `notifyListeners()` fora da própria classe. Migração para outra solução de
  estado (ex.: Bloc/Cubit) exige emenda formal a esta constituição antes de
  iniciada, e MUST NOT ser feita parcialmente (mistura das duas soluções no mesmo
  módulo é proibida).
- **Configuração de ambiente:** toda configuração sensível a ambiente (URL de API,
  flags de debug, ambiente atual) MUST passar por `EnvironmentConfig`, usando
  `String.fromEnvironment` / `bool.fromEnvironment` / `--dart-define`. É proibido
  ler variáveis de ambiente diretamente fora dessa classe.
- **Internacionalização:** `easy_localization` é a única solução de i18n; strings
  visíveis ao usuário MUST NOT ser hardcoded em widgets.

**Racional:** travar a stack evita que o projeto acumule duas soluções concorrentes
para o mesmo problema (risco já materializado uma vez — ver item 1 do Diagnóstico
abaixo) e garante que qualquer parte do código seja legível por quem conhece apenas
esta constituição.

### V. Tratamento de Erros Tipado e Sem Strings Mágicas

Toda falha MUST ser representada por um tipo, nunca por uma `String` solta, um
`dynamic` ou um código numérico não nomeado.

- **Exceções tipadas obrigatórias.** Toda falha originada de uma chamada HTTP MUST
  ser convertida para `ApiException` antes de sair da camada de dados (dentro de
  `ApiClient._safeRequest`). É proibido deixar vazar `DioException` ou qualquer
  exceção de biblioteca externa para a camada de UI ou de domínio.
- **Um único padrão canônico.** `ApiClient`/`ApiException`
  (`lib/modules/common/api_client/api_client.dart`) é o único cliente HTTP e o
  único tipo de exceção de API do projeto. É proibido introduzir um segundo
  cliente HTTP, uma segunda hierarquia de exceção, ou qualquer variante paralela
  para o mesmo propósito.
- **Proibição de strings mágicas.** Códigos de erro, chaves de mensagem e
  identificadores de estado MUST ser representados por `enum` ou constante
  nomeada (seguindo o exemplo de `UserSessionStatus`), nunca por literais de
  string comparados diretamente no fluxo de controle (`if (error == "algumacoisa")`
  é proibido).
- **Mapeamento centralizado.** A decisão do que fazer com um código de erro (ex.:
  401/403 → logout automático via `UserSessionService`) MUST viver em um único
  ponto centralizado da camada de dados, nunca duplicada em cada tela que consome a
  API.
- **Mensagens de erro para o usuário MUST ser desacopladas da mensagem técnica.** A
  UI MUST exibir uma mensagem amigável mapeada a partir do tipo/código da exceção,
  nunca a `message` bruta vinda da API sem validação.

**Racional:** erros não tipados e strings mágicas são a causa mais comum de bugs
silenciosos em Dart, porque o compilador não pode ajudar a pegar um typo em uma
string de erro — um `enum` ou uma classe de exceção, sim.

## Padrões de Código e Convenções de Nomenclatura

- **Arquivos:** `snake_case.dart`. O nome do arquivo MUST refletir o papel da
  classe principal via sufixo: `_module.dart` (módulo), `_controller.dart`
  (controller de UI), `_service.dart` (serviço de negócio/infra), `_client.dart`
  (cliente de API), `_config.dart` (configuração).
- **Classes e enums:** `UpperCamelCase`. O nome da classe MUST terminar com o mesmo
  sufixo semântico do arquivo (`AuthenticationController`, `UserSessionService`,
  `ApiClient`, `EnvironmentConfig`).
- **Métodos, variáveis e parâmetros:** `lowerCamelCase`. Nomes MUST ser
  descritivos e em português ou inglês de forma consistente dentro do mesmo
  arquivo — é proibido misturar os dois idiomas no mesmo identificador.
- **Enums:** o tipo MUST ser nomeado no singular ou como substantivo do domínio
  (`UserSessionStatus`), e cada valor MUST ser `lowerCamelCase` sem abreviações
  obscuras.
- **Arquivos de ambiente (`EnvironmentConfig`):** toda constante MUST ser
  `static const`, tipada explicitamente (`String`, `bool`, `int`), e MUST ter um
  `defaultValue` seguro (nunca uma credencial real como default).
- **Barrel files** (`common.dart`, `authentication.dart`, `ui.dart`) MUST apenas
  reexportar arquivos do próprio módulo/pasta — é proibido colocar lógica neles.
- **Imports** MUST usar o prefixo do pacote (`package:click_seguro_app/...`) para
  arquivos fora da pasta atual, nunca `../../../` mais de dois níveis.

## Regras Globais de Segurança e Qualidade

- **É proibido expor senha, token, chave de API ou segredo em código-fonte,**
  incluindo em testes, comentários, valores default de `EnvironmentConfig` ou
  arquivos de configuração versionados.
- **`.env` e qualquer arquivo de segredo MUST constar no `.gitignore`** e MUST NOT
  ser commitado. Se um segredo for commitado por engano, ele MUST ser considerado
  comprometido e rotacionado, não apenas removido do commit seguinte.
- **Tipagem forte é obrigatória.** É proibido usar `dynamic` em assinatura pública
  de método, retorno de serviço ou modelo de dados, exceto na fronteira estrita de
  desserialização JSON (`fromJson`), onde o valor MUST ser convertido para um tipo
  forte antes de sair do método.
- **`late` e `!` (null-assertion) exigem justificativa.** Seu uso só é permitido
  quando a não-nulidade é garantida por um invariante do próprio fluxo (ex.:
  resposta HTTP já validada dentro de `ApiClient._safeRequest`); uso especulativo
  para "silenciar o compilador" é proibido.
- **Camada de UI MUST NOT depender de infraestrutura.** Widgets e telas MUST NOT
  importar `dio`, `get_it` (exceto para obter uma instância de serviço/controller já
  registrado) ou qualquer pacote de acesso a dados diretamente. Toda comunicação com
  dados MUST passar por um `Controller` ou `Service` injetado.
- **Toda dependência nova em `pubspec.yaml`** MUST ser justificada por não haver
  solução equivalente já presente na stack oficial (Seção IV), e MUST ter sua
  versão fixada de forma explícita.

## Diagnóstico do Estado Atual do Repositório

Esta seção registra desvios encontrados no código e seu status de resolução, para
manter histórico do que já foi endereçado e evitar que reapareçam como precedente:

1. ~~Duplicidade de cliente HTTP/exceção~~ — **Resolvido em 2026-09-07.**
   `base_api_client.dart`, `method_api_client.dart` e
   `exceptions/exception_api_client.dart` (código sem consumidores) foram
   removidos. `ApiClient`/`ApiException` é o padrão canônico único (Seção V) e
   passou a ser registrado no `GetIt` via `CommonModule.registerServices`, junto
   de `UserSessionService` (que também não estava registrado).
2. ~~`.env` fora do `.gitignore`~~ — **Resolvido em 2026-09-07.** `.env` e
   `.env.*` foram adicionados ao `.gitignore` do pacote Flutter. O arquivo nunca
   havia sido commitado, portanto nenhuma credencial foi exposta no histórico do
   Git.

## Governança

- **Autoridade.** Esta constituição substitui qualquer convenção ad-hoc em
  conflito. A seção `## Constitution Check` dos templates de plano do Spec Kit
  MUST ser avaliada contra os Princípios I–V, e `/speckit.analyze` MUST tratar
  conflito com um MUST como CRÍTICO.
- **Emendas.** Alterar este documento exige registrar a mudança no Sync Impact
  Report no topo do arquivo e justificar o racional da mudança.
- **Política de versionamento (SemVer para governança).** MAJOR = remoção ou
  redefinição incompatível de um princípio; MINOR = novo princípio ou seção
  adicionada; PATCH = clarificação sem mudança semântica.
- **Revisão de conformidade.** Toda tarefa gerada via Spec Kit (`/speckit.plan`,
  `/speckit.tasks`) MUST ser verificada contra estes princípios antes de ser
  considerada concluída. Complexidade adicionada ou qualquer desvio MUST ser
  justificado explicitamente na tarefa ou no plano.

**Versão**: 1.0.1 | **Ratificada em**: 2026-09-07 | **Última alteração**: 2026-09-07
