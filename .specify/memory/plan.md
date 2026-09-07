# SafeNews — Plano Técnico de Arquitetura

**Projeto**: Click Seguro (TCC) — Aplicativo **SafeNews**

**Versão**: 1.0.0

**Criado em**: 2026-09-07

**Status**: Rascunho (Draft)

**Alinhado a**: [constitution.md](constitution.md) v1.0.1 (o COMO deste documento MUST
obedecer aos princípios lá definidos) e [specification.md](specification.md) v1.0.0 (todo
elemento técnico aqui existe para satisfazer um RF/RNF/RN/CB específico — as referências
`RF-XXX`/`RNF-XXX`/`RN-XXX`/`CB-XXX` ao longo do texto apontam para lá).

## Nota de alinhamento com o código atual

Este plano parte do estado real do repositório após a consolidação já realizada:
`BaseApiClient`, `ExceptionApiClient` e `MethodApiClient` foram removidos por serem código
duplicado sem consumidores (ver Diagnóstico da constituição). O único cliente HTTP e a única
exceção de API do projeto são `ApiClient`/`ApiException`
(`lib/modules/common/api_client/api_client.dart`). Todo o detalhamento abaixo usa esse padrão
como base e o estende — não ressuscita o padrão removido.

Este plano também propõe duas dependências novas, ambas justificadas conforme a Seção V da
constituição (nenhuma solução equivalente existe na stack atual):

- **`flutter_secure_storage`** — necessária para resolver a lacuna já registrada em RNF-007
  (token hoje só existe em memória, não sobrevive a reinício do app).
- **`shared_preferences`** — necessária para o cache local de feed/favoritos (RNF-002). Já é
  puxada transitivamente (via `easy_localization`), mas deve passar a constar como dependência
  direta no `pubspec.yaml` por ser usada explicitamente pelo app, não apenas por uma
  dependência transitiva.

Nenhuma outra dependência nova é necessária: o modo offline é resolvido de forma reativa
(cai no cache quando uma chamada falha por conexão), sem exigir um pacote de detecção
proativa de conectividade — mais simples (KISS) e suficiente para os RNFs definidos.

---

## 1. Estrutura de Pastas e Módulos

### 1.1 Visão geral (Clean Architecture + feature-based DI)

```
lib/
├── core/                          # Transversal puro (Seção I da constituição)
│   ├── i18n/
│   ├── theme/
│   └── widgets/                   # SafeButton, SafeCard, SafeTextField, SafeBadge...
│
├── modules/
│   ├── common/                    # Infraestrutura compartilhada (já existente)
│   │   ├── api_client/
│   │   │   └── api_client.dart    # ApiClient + ApiException (canônico único)
│   │   ├── config/
│   │   │   └── environment_config.dart
│   │   ├── services/
│   │   │   ├── user_session_service.dart
│   │   │   ├── secure_storage_service.dart      # NOVO — Fase 1
│   │   │   └── local_cache_service.dart         # NOVO — Fase 1 (shared_preferences)
│   │   ├── core/module/           # ModuleInterface, ModuleManager (já existente)
│   │   └── common_module.dart
│   │
│   ├── authentication/            # Fase 2
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   └── auth_remote_data_source.dart
│   │   │   ├── models/
│   │   │   │   └── user_model.dart
│   │   │   └── repositories/
│   │   │       └── auth_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   ├── user_entity.dart
│   │   │   │   └── user_role.dart               # enum
│   │   │   └── repositories/
│   │   │       └── auth_repository.dart          # contrato abstrato
│   │   ├── ui/
│   │   │   ├── controller/
│   │   │   │   └── authentication_controller.dart
│   │   │   └── pages/
│   │   │       ├── login_page.dart
│   │   │       ├── register_page.dart
│   │   │       └── forgot_password_page.dart
│   │   ├── authentication_module.dart
│   │   └── authentication.dart    # barrel
│   │
│   ├── news/                      # Fase 3
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   ├── news_remote_data_source.dart
│   │   │   │   └── news_local_data_source.dart
│   │   │   ├── models/
│   │   │   │   └── news_model.dart
│   │   │   └── repositories/
│   │   │       └── news_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   ├── news_entity.dart
│   │   │   │   └── veracity_status.dart          # enum (RF-014)
│   │   │   └── repositories/
│   │   │       └── news_repository.dart
│   │   ├── ui/
│   │   │   ├── controller/
│   │   │   │   ├── feed_controller.dart
│   │   │   │   └── news_detail_controller.dart
│   │   │   └── pages/
│   │   │       ├── feed_page.dart
│   │   │       └── news_detail_page.dart
│   │   ├── news_module.dart
│   │   └── news.dart
│   │
│   └── fact_check/                # Fase 4
│       ├── data/
│       │   ├── datasources/
│       │   │   └── fact_check_remote_data_source.dart
│       │   ├── models/
│       │   │   └── fact_check_model.dart
│       │   └── repositories/
│       │       └── fact_check_repository_impl.dart
│       ├── domain/
│       │   ├── entities/
│       │   │   ├── report_entity.dart
│       │   │   ├── report_reason.dart            # enum (RF-015)
│       │   │   └── verdict_entity.dart
│       │   └── repositories/
│       │       └── fact_check_repository.dart
│       ├── ui/
│       │   ├── controller/
│       │   │   ├── report_controller.dart        # leitor denuncia
│       │   │   └── validation_queue_controller.dart # validador revisa
│       │   └── pages/
│       │       ├── report_news_page.dart
│       │       └── validation_queue_page.dart
│       ├── fact_check_module.dart
│       └── fact_check.dart
│
└── main.dart
```

`test/` MUST espelhar exatamente essa árvore (Seção III da constituição), ex.:
`test/modules/news/domain/repositories/news_repository_impl_test.dart`.

### 1.2 Regra de dependência entre módulos

- `news` e `fact_check` **não se importam por implementação**. `fact_check` depende apenas do
  contrato `NewsRepository` (interface do domínio de `news`), resolvido via `GetIt`, para
  aplicar o novo `VeracityStatus` após um veredito (RF-016/RF-017). Isso satisfaz a regra da
  constituição de que módulos só se comunicam por serviço registrado no `GetIt`, nunca por
  import direto de arquivo interno de outro módulo.
- `authentication` expõe apenas `AuthRepository`/`UserSessionService`; nenhum outro módulo
  importa arquivos internos de `authentication`.
- `common` não depende de nenhum módulo de feature — é a única direção de dependência
  permitida (features → common, nunca o inverso).

### 1.3 Injeção de dependência modular (GetIt)

Ordem de registro em `main.dart` (`_setup()`), que já existe e será estendida:

```dart
await moduleManager.registerModules([
  CommonModule(),          // infraestrutura: ApiClient, UserSessionService, storages
  AuthenticationModule(),  // depende de common
  NewsModule(),            // depende de common
  FactCheckModule(),       // depende de common + NewsRepository (news)
]);
```

Convenção de registro dentro de cada `registerServices(GetIt injector)`:

| Tipo de dependência | Método GetIt | Exemplo |
|---|---|---|
| Serviço/infra sem estado por tela (singleton de app) | `registerLazySingleton` | `ApiClient`, `UserSessionService`, repositórios |
| Data source (stateless, uma instância basta) | `registerLazySingleton` | `NewsRemoteDataSource` |
| Controller que precisa de parâmetro na construção (ex.: id da notícia) | `registerFactoryParam` | `NewsDetailController` |
| Controller sem parâmetro, mas com estado por tela (nova instância a cada abertura) | `registerFactory` | `ReportController` |

Cada `Repository` MUST ser registrado pelo tipo abstrato do domínio, nunca pela implementação
concreta (Seção II da constituição — Dependency Inversion):

```dart
injector.registerLazySingleton<NewsRepository>(
  () => NewsRepositoryImpl(
    remote: injector<NewsRemoteDataSource>(),
    local: injector<NewsLocalDataSource>(),
  ),
);
```

Controllers de página (Provider) resolvem sua dependência via `GetIt` no `create:`, nunca
instanciando repositório/serviço diretamente na árvore de widgets:

```dart
ChangeNotifierProvider(
  create: (_) => GetIt.instance<NewsDetailController>(param1: newsId),
)
```

---

## 2. Camada de Infraestrutura de Rede e Sessão

### 2.1 Cliente HTTP — `ApiClient`

`ApiClient` (único cliente HTTP do projeto) permanece com a assinatura atual — `get/post/put/
delete`, `requiresAuth`, `_makeOptions`, `_safeRequest` — e recebe duas extensões necessárias
para os módulos de feature:

- **Suporte a `CancelToken`** em `get`/parâmetros de busca, para atender RNF-005 (cancelar
  requisição de busca obsoleta ao digitar):
  ```dart
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    bool requiresAuth = true,
    CancelToken? cancelToken,
  })
  ```
- **Mapeamento de erro permanece 100% centralizado em `_safeRequest`** — nenhum
  repositório/data source MUST capturar `DioException` diretamente; todos recebem apenas
  `ApiException` (Seção V da constituição, CB-002/CB-004/CB-005 da especificação).

### 2.2 Configuração de ambiente — `EnvironmentConfig`

Mantém os três campos já existentes (`apiBaseUrl`, `environment`, `debugMode`), lidos via
`--dart-define` em tempo de build:

```bash
flutter run \
  --dart-define=API_URL=https://api.safenews.dev \
  --dart-define=ENVIRONMENT=development \
  --dart-define=DEBUG_MODE=true
```

O arquivo `.env` (já protegido no `.gitignore`) passa a ter papel exclusivamente
**documental/local** — não é lido em runtime por nenhum pacote (evita adicionar
`flutter_dotenv` como dependência nova sem necessidade real, Seção V). Recomenda-se manter um
`.env.example` versionado apenas com os nomes das chaves esperadas (`API_URL=`,
`ENVIRONMENT=`, `DEBUG_MODE=`), para documentar o contrato sem expor valor algum.

### 2.3 Sessão de usuário — `UserSessionService`

Mantém a API pública já existente (`token`, `userId`, `sessionStatus`
`ValueNotifier<UserSessionStatus>`, `saveSession`, `logout`, `isAuthenticated`) e ganha
persistência (resolve a lacuna de RNF-007):

```dart
class UserSessionService {
  UserSessionService(this._secureStorage);
  final SecureStorageService _secureStorage;

  String? token;
  String? userId;
  final sessionStatus = ValueNotifier<UserSessionStatus>(UserSessionStatus.unauthenticated);

  Future<void> restoreSession() async {
    final storedToken = await _secureStorage.readToken();
    if (storedToken != null && storedToken.isNotEmpty) {
      token = storedToken;
      sessionStatus.value = UserSessionStatus.authenticated;
    }
  }

  Future<void> saveSession({required String newToken, String? newUserId}) async {
    token = newToken;
    userId = newUserId;
    await _secureStorage.writeToken(newToken);
    sessionStatus.value = UserSessionStatus.authenticated;
  }

  Future<void> logout() async {
    token = null;
    userId = null;
    await _secureStorage.clear();
    sessionStatus.value = UserSessionStatus.unauthenticated;
  }

  bool get isAuthenticated => token != null;
}
```

`restoreSession()` MUST ser chamado em `_setup()` (`main.dart`), antes de `runApp`, para que o
app já abra no estado de sessão correto (RF-003).

Um widget raiz `AuthGate` (em `core/widgets/`) MUST escutar
`sessionStatus` via `ValueListenableBuilder` e decidir entre a navegação autenticada e a de
login — é o mecanismo concreto que cumpre RN-005 (sessão governa navegação) em um único
ponto, em vez de cada página checar `isAuthenticated` isoladamente.

### 2.4 Mapeamento de erros e logs

- `ApiException` continua sendo o único tipo de exceção de API (Seção V da constituição,
  já sem `ExceptionApiClient`).
- `LogInterceptor`, já condicionado a `EnvironmentConfig.debugMode`, é o único mecanismo de
  log de requisição/resposta — nenhum módulo de feature MUST adicionar seu próprio log de
  rede.
- Um pequeno `ApiExceptionMessageMapper` (função pura em `common/api_client/`) traduz
  `ApiException.statusCode`/`message` para uma mensagem amigável de UI, cobrindo CB-003
  (401 → "Sua sessão expirou, faça login novamente.") e CB-004 (5xx → mensagem genérica),
  para que nenhuma tela precise decidir isso individualmente.

---

## 3. Modelagem de Dados e Contratos

### 3.1 Entidades de domínio (puras, sem JSON)

- **`UserEntity`**: `id`, `name`, `email`, `role` (`UserRole.reader | UserRole.validator`).
- **`NewsEntity`**: `id`, `title`, `summary`, `body`, `sourceName`, `sourceUrl`,
  `publishedAt`, `category`, `veracityStatus` (`VeracityStatus`), `isFavorite`.
- **`VeracityStatus`** (enum): `unverified` (default — RN-002), `underReview`, `verified`,
  `false`.
- **`ReportEntity`**: `id`, `newsId`, `reportedBy`, `reason` (`ReportReason`), `createdAt`.
- **`ReportReason`** (enum): `misleadingTitle`, `fabricatedContent`, `outOfContext`,
  `unreliableSource`, `other`.
- **`VerdictEntity`**: `newsId`, `decidedBy`, `previousStatus`, `newStatus`, `justification`,
  `decidedAt` — é o registro que sustenta o histórico auditável de RF-017.

Entidades MUST NOT ter `fromJson`/`toJson` — são o contrato interno do domínio, ignoram
formato de transporte (separação pedida explicitamente na estrutura por camadas).

### 3.2 Models (camada de dados, conversão JSON)

Cada `Model` estende ou envolve sua `Entity` correspondente e concentra toda a
serialização:

```dart
class NewsModel extends NewsEntity {
  NewsModel({
    required super.id,
    required super.title,
    required super.summary,
    required super.body,
    required super.sourceName,
    required super.sourceUrl,
    required super.publishedAt,
    required super.category,
    required super.veracityStatus,
    required super.isFavorite,
  });

  factory NewsModel.fromJson(Map<String, dynamic> json) => NewsModel(
        id: json['id'] as String,
        title: json['title'] as String,
        summary: json['summary'] as String,
        body: json['body'] as String,
        sourceName: json['sourceName'] as String,
        sourceUrl: json['sourceUrl'] as String,
        publishedAt: DateTime.parse(json['publishedAt'] as String),
        category: json['category'] as String,
        veracityStatus: VeracityStatus.values.byName(json['veracityStatus'] as String),
        isFavorite: json['isFavorite'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'summary': summary,
        'body': body,
        'sourceName': sourceName,
        'sourceUrl': sourceUrl,
        'publishedAt': publishedAt.toIso8601String(),
        'category': category,
        'veracityStatus': veracityStatus.name,
        'isFavorite': isFavorite,
      };
}
```

O mesmo padrão vale para `UserModel` e `FactCheckModel`/`ReportModel`/`VerdictModel`. A
conversão de JSON malformado em `ApiException` (CB-005) MUST acontecer no Data Source, nunca
no Repository nem no Controller — se `NewsModel.fromJson` lançar `TypeError`/
`FormatException`, o `RemoteDataSource` MUST capturar e relançar como `ApiException`.

### 3.3 Contratos abstratos — Repositórios e Data Sources

Cada feature define seu contrato de repositório no domínio e duas implementações de fonte de
dados na camada de dados:

```dart
// domain/repositories/news_repository.dart
abstract class NewsRepository {
  Future<List<NewsEntity>> getFeed({required int page, String? category});
  Future<NewsEntity> getById(String id);
  Future<List<NewsEntity>> search(String query, {CancelToken? cancelToken});
  Future<void> toggleFavorite(String id);
  Future<List<NewsEntity>> getFavorites();
  Future<void> applyVerdict(String newsId, VeracityStatus newStatus); // usado por fact_check
}

// data/datasources/news_remote_data_source.dart
abstract class NewsRemoteDataSource {
  Future<List<NewsModel>> fetchFeed({required int page, String? category});
  Future<NewsModel> fetchById(String id);
  Future<List<NewsModel>> search(String query, {CancelToken? cancelToken});
}

// data/datasources/news_local_data_source.dart
abstract class NewsLocalDataSource {
  Future<void> cacheFeed(List<NewsModel> news);
  Future<List<NewsModel>> getCachedFeed();
  Future<void> setFavorite(String id, bool value);
  Future<List<NewsModel>> getFavorites();
}
```

`NewsRepositoryImpl` orquestra as duas fontes e concentra a regra de fallback offline
(RNF-002/CB-001): tenta `remote`, e só recorre a `local` quando `remote` lançar `ApiException`
originada de falha de conexão (`statusCode == 0`, conforme já convencionado em
`ApiClient._safeRequest`).

`AuthRepository` e `FactCheckRepository` seguem a mesma forma (contrato no domínio +
implementação que combina `RemoteDataSource` com `ApiClient` por baixo).

---

## 4. Gerenciamento de Estado na Apresentação

### 4.1 Decisão confirmada: Provider + ChangeNotifier

Por força da Seção IV da constituição, a solução de estado é **Provider + ChangeNotifier**,
não Bloc/Cubit. Cada `Controller` de feature expõe os estados de carregamento/sucesso/erro
como campos simples e diretos — sem um tipo de estado genérico intermediário — mantendo a
implementação a mais direta possível (KISS):

```dart
class FeedController extends ChangeNotifier {
  FeedController(this._repository);
  final NewsRepository _repository;

  bool isLoading = false;
  List<NewsEntity>? news;
  ApiException? error;

  Future<void> loadFeed({String? category}) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      news = await _repository.getFeed(page: 1, category: category);
    } on ApiException catch (e) {
      error = e;
    }
    isLoading = false;
    notifyListeners();
  }
}
```

Na UI, os três campos são checados diretamente (nesta ordem: erro, carregando, dado
presente/ausente):

```dart
if (controller.error != null) {
  ErrorBanner(message: controller.error!.message);
} else if (controller.isLoading) {
  const CircularProgressIndicator();
} else if (controller.news != null) {
  NewsFeedList(news: controller.news!);
} else {
  const SizedBox.shrink();
}
```

Cada `Controller` novo (Fases 2–4) segue exatamente esse formato — `isLoading`/`error`/campo
de dado nomeado pelo que ele representa (`user`, `news`, `reportSentSuccessfully` etc.) —, sem
introduzir uma abstração de estado compartilhada entre features.

### 4.2 Estado de autenticação reativo

`UserSessionService.sessionStatus` (`ValueNotifier<UserSessionStatus>`) continua sendo a
única fonte de verdade sobre sessão — é global e mais simples que um `ChangeNotifier` dedicado
para esse único valor. `AuthGate` (Seção 2.3) é o único widget que reage a ele para decisão de
navegação; `AuthenticationController` (login/registro) usa os mesmos campos simples
(`isLoading`/`error`/`user`) para seus próprios estados de formulário, e só chama
`UserSessionService.saveSession` quando o login tem sucesso — as duas reatividades
(`ValueNotifier` de sessão vs. `ChangeNotifier` de operação) coexistem por design, cada uma no
nível que lhe cabe (global vs. por-tela).

---

## 5. Fases de Desenvolvimento (Milestones)

Cada fase só é considerada concluída quando (a) o código correspondente existe, (b) há teste
automatizado cobrindo o caminho feliz e ao menos um caminho de erro (Seção III da
constituição), e (c) `flutter analyze` não introduz novo erro/warning.

### Fase 1 — Setup da Infraestrutura Base

- Adicionar `flutter_secure_storage` e `shared_preferences` ao `pubspec.yaml` (dependências
  justificadas na nota de alinhamento no topo deste documento).
- Criar `SecureStorageService` (`common/services/secure_storage_service.dart`) e
  `LocalCacheService` (`common/services/local_cache_service.dart`), ambos registrados em
  `CommonModule.registerServices`.
- Estender `UserSessionService` com `restoreSession()`/persistência (Seção 2.3).
- Estender `ApiClient` com suporte a `CancelToken` (Seção 2.1).
- Criar `AuthGate` em `core/widgets/`.
- Chamar `UserSessionService.restoreSession()` em `main.dart` antes de `runApp`.
- Testes: `SecureStorageService`, `LocalCacheService`, `UserSessionService` (incluindo
  restauração de sessão), extensão de `CancelToken` no `ApiClient`.

### Fase 2 — Módulo de Autenticação e Sessão

- Criar `UserEntity`, `UserRole`, `UserModel` (fromJson/toJson).
- Criar `AuthRepository` (contrato) + `AuthRepositoryImpl` + `AuthRemoteDataSource`.
- Implementar `AuthenticationController` (campos `isLoading`/`error`/`user`) para login,
  registro e recuperação de senha (RF-001, RF-002, RF-006).
- Criar `LoginPage`, `RegisterPage`, `ForgotPasswordPage` com validação de formulário alinhada
  a RN-001.
- Registrar tudo em `AuthenticationModule.registerServices`.
- Testes: `AuthRepositoryImpl` (mock de `AuthRemoteDataSource`), `AuthenticationController`
  (estados idle/loading/success/error), validação de formulário (RN-001).

### Fase 3 — Módulo de Feed e Detalhamento de Notícias

- Criar `NewsEntity`, `VeracityStatus`, `NewsModel`.
- Criar `NewsRepository` (contrato) + `NewsRepositoryImpl` + `NewsRemoteDataSource` +
  `NewsLocalDataSource`, incluindo a lógica de fallback offline (RNF-002/CB-001).
- Implementar `FeedController` (feed paginado + filtro de categoria + busca com debounce e
  `CancelToken`, RF-008/RF-009/RF-010) e `NewsDetailController` (RF-011/RF-012).
- Implementar `FeedPage` (lista, filtro, busca, estado vazio CB-007, fim de paginação CB-008)
  e `NewsDetailPage` (selo de veracidade, favoritar — RF-013).
- Registrar tudo em `NewsModule.registerServices`.
- Testes: `NewsRepositoryImpl` (incluindo fallback para cache local quando `remote` falha por
  conexão), `FeedController` (paginação, filtro, busca cancelável), `NewsDetailController`.

### Fase 4 — Módulo de Validação / Checagem de Fatos (Fact-Checking)

- Criar `ReportEntity`, `ReportReason`, `VerdictEntity`, `FactCheckModel`s correspondentes.
- Criar `FactCheckRepository` (contrato) + `FactCheckRepositoryImpl` +
  `FactCheckRemoteDataSource`, dependendo de `NewsRepository` (via `GetIt`) para aplicar o
  novo `VeracityStatus` após um veredito (RF-016/RF-017).
- Implementar `ReportController` (RF-015, com bloqueio de denúncia duplicada — RN-003/CB-006)
  e `ValidationQueueController` (fila priorizada por volume de denúncias — RN-006; RF-016).
- Implementar `ReportNewsPage` e `ValidationQueuePage`, esta última com checagem de papel
  (`UserRole.validator`) bloqueando acesso antes de qualquer chamada de API (RN-004/CB-009).
- Registrar tudo em `FactCheckModule.registerServices`.
- Testes: `FactCheckRepositoryImpl`, `ReportController` (idempotência de denúncia),
  `ValidationQueueController` (priorização e registro de veredito com histórico).

### Fase 5 — Tratamento Global de Erros, Estado Offline e Refinamento de Interface

- Implementar `ApiExceptionMessageMapper` (Seção 2.4) e adotá-lo em todo campo `error` já
  exposto pelos controllers existentes, padronizando mensagem por `statusCode`.
- Adicionar indicador visual de "modo offline" em `FeedPage` quando o `NewsRepositoryImpl`
  retornar dados de cache (CB-001).
- Revisão de acessibilidade (RNF-004): `Semantics`/rótulos em todos os elementos interativos
  criados nas Fases 2–4, checagem de contraste (AA) nos temas claro/escuro.
- Revisão final de i18n (RNF-006): nenhuma string hardcoded restante nas telas criadas.
- Auditoria cruzada final: cada RF/RNF/RN/CB da `specification.md` MUST ter ao menos um teste
  automatizado que o exercite; lacunas encontradas aqui viram tarefas de fechamento, não ficam
  documentadas apenas em prosa.

---

## Rastreabilidade

| Elemento técnico | Requisitos que satisfaz |
|---|---|
| `AuthGate` + `UserSessionService.sessionStatus` | RF-003, RF-004, RN-005, CB-003 |
| `ApiClient` + `CancelToken` | RNF-005 |
| `SecureStorageService` | RNF-007 |
| `NewsRepositoryImpl` (fallback remote→local) | RNF-002, CB-001 |
| `VeracityStatus` (enum, default `unverified`) | RF-014, RN-002 |
| `ReportReason` (enum) + checagem de duplicidade no `ReportController` | RF-015, RN-003, CB-006 |
| `VerdictEntity` (histórico) | RF-017 |
| `ValidationQueueController` com guard de `UserRole` | RF-007, RN-004, CB-009 |
| `ApiExceptionMessageMapper` | CB-002, CB-003, CB-004 |
| Data Source capturando erro de parsing | CB-005 |

---

## Governança deste documento

Este plano é o insumo direto para a geração de `tasks.md`: cada bullet das Fases 1–5 MUST
virar uma ou mais tarefas rastreáveis, na ordem apresentada (uma fase não inicia antes de a
anterior ter seus testes verdes). Qualquer desvio arquitetural encontrado durante a
implementação (ex.: um contrato de repositório precisar de um método a mais) MUST atualizar
este documento antes de a tarefa correspondente ser marcada concluída — o plano não pode ficar
desatualizado em relação ao código real.

**Versão**: 1.0.1 | **Criado em**: 2026-09-07 | **Última alteração**: 2026-09-07
