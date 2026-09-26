# SafeNews — Plano Técnico de Arquitetura

**Projeto**: Click Seguro (TCC) — Aplicativo **SafeNews**

**Versão**: 1.1.0

**Criado em**: 2026-09-07

**Status**: Rascunho (Draft)

**Alinhado a**: [constitution.md](constitution.md) v1.1.0 (o COMO deste documento MUST
obedecer aos princípios lá definidos) e [specification.md](specification.md) v1.0.1 (todo
elemento técnico aqui existe para satisfazer um RF/RNF/RN/CB específico — as referências
`RF-XXX`/`RNF-XXX`/`RN-XXX`/`CB-XXX` ao longo do texto apontam para lá).

## Nota de alinhamento com o código atual

Este plano parte do estado real do repositório após a consolidação já realizada:
`BaseApiClient`, `ExceptionApiClient` e `MethodApiClient` foram removidos por serem código
duplicado sem consumidores (ver Diagnóstico da constituição). O único cliente HTTP e a única
exceção de API do projeto são `ApiClient`/`ApiException`
(`lib/modules/common/api_client/api_client.dart`). Todo o detalhamento abaixo usa esse padrão
como base e o estende — não ressuscita o padrão removido.

**Atualização v1.1.0 (2026-09-26)** — camada de dados padronizada a partir do guia
`click_seguro_app/ENDPOINT_INTEGRATION_CONTEXT.md`:

- Repositories e usecases retornam **`Either<Failure, T>`** (fpdart), como já faz o módulo
  `onboarding`. `ApiException` fica restrita à camada `data/`.
- `ApiException` agora tem `type` (`ApiErrorType`), `statusCode` anulável e `errorCode`
  (campo `error` da API). A convenção `statusCode == 0` para "sem conexão" foi abolida.
- O `ApiClient` continua sendo um singleton do `GetIt`, **injetado por construtor** nos
  datasources (composição — datasources não herdam dele).
- Camada de UI chama-se **`presentation/`** em todos os módulos.
- Entre controller e repository existe sempre um **usecase** (o controller nunca vê o
  repository).

Este plano também propõe dependências, justificadas conforme a Seção IV da constituição
(nenhuma solução equivalente existe na stack atual):

- **`flutter_secure_storage`** (nova) — necessária para resolver a lacuna já registrada em
  RNF-007 (token hoje só existe em memória, não sobrevive a reinício do app).
- **`shared_preferences`** — necessária para o cache local de feed/favoritos (RNF-002). Já
  consta como dependência direta no `pubspec.yaml` (usada pelo `onboarding`).

Nenhuma outra dependência nova é necessária: o modo offline é resolvido de forma reativa
(cai no cache quando uma chamada falha por conexão), sem exigir um pacote de detecção
proativa de conectividade — mais simples (KISS) e suficiente para os RNFs definidos.

---

## 1. Estrutura de Pastas e Módulos

### 1.1 Visão geral (Clean Architecture + feature-based DI)

```
lib/
├── core/                          # Transversal puro (Seção I da constituição)
│   ├── errors/                    # Failure + ConnectionFailure, UnauthorizedFailure,
│   │                              # ServerFailure, CacheFailure (já existente)
│   ├── i18n/
│   ├── routing/
│   ├── theme/
│   └── widgets/                   # SafeButton, SafeCard, SafeTextField, SafeBadge...
│
├── modules/
│   ├── common/                    # Infraestrutura compartilhada (já existente)
│   │   ├── api_client/
│   │   │   ├── api_client.dart          # ApiClient + ApiException + ApiErrorType
│   │   │   └── api_failure_mapper.dart  # ApiException.toFailure() (mapeamento padrão)
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
│   │   │   │   ├── auth_remote_data_source.dart       # contrato
│   │   │   │   └── auth_remote_data_source_impl.dart  # sobre ApiClient
│   │   │   ├── models/
│   │   │   │   └── user_model.dart
│   │   │   └── repositories/
│   │   │       └── auth_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   ├── user_entity.dart
│   │   │   │   └── user_role.dart               # enum
│   │   │   ├── repositories/
│   │   │   │   └── auth_repository.dart          # contrato abstrato
│   │   │   └── usecases/
│   │   │       ├── login_usecase.dart
│   │   │       ├── register_usecase.dart
│   │   │       └── request_password_reset_usecase.dart
│   │   ├── presentation/
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
│   │   │   │   ├── news_remote_data_source.dart       # + _impl.dart
│   │   │   │   └── news_local_data_source.dart        # + _impl.dart
│   │   │   ├── models/
│   │   │   │   └── news_model.dart
│   │   │   └── repositories/
│   │   │       └── news_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   ├── news_entity.dart
│   │   │   │   └── veracity_status.dart          # enum (RF-014)
│   │   │   ├── repositories/
│   │   │   │   └── news_repository.dart
│   │   │   └── usecases/
│   │   │       ├── get_news_feed_usecase.dart    # ordenação RF-008
│   │   │       ├── get_news_detail_usecase.dart
│   │   │       ├── search_news_usecase.dart
│   │   │       └── toggle_favorite_usecase.dart
│   │   ├── presentation/
│   │   │   ├── controller/
│   │   │   │   ├── feed_controller.dart
│   │   │   │   └── news_detail_controller.dart
│   │   │   ├── extensions/
│   │   │   │   └── news_presentation_extension.dart  # selo, data formatada
│   │   │   ├── pages/
│   │   │   │   ├── feed_page.dart
│   │   │   │   └── news_detail_page.dart
│   │   │   └── widgets/
│   │   │       └── news_card_widget.dart
│   │   ├── news_module.dart
│   │   └── news.dart
│   │
│   └── fact_check/                # Fase 4
│       ├── data/
│       │   ├── datasources/
│       │   │   └── fact_check_remote_data_source.dart # + _impl.dart
│       │   ├── models/
│       │   │   └── fact_check_model.dart
│       │   └── repositories/
│       │       └── fact_check_repository_impl.dart
│       ├── domain/
│       │   ├── entities/
│       │   │   ├── report_entity.dart
│       │   │   ├── report_reason.dart            # enum (RF-015)
│       │   │   └── verdict_entity.dart
│       │   ├── failures/
│       │   │   └── fact_check_failures.dart      # ex.: ReportAlreadyExistsFailure (RN-003)
│       │   ├── repositories/
│       │   │   └── fact_check_repository.dart
│       │   └── usecases/
│       │       ├── report_news_usecase.dart
│       │       ├── get_validation_queue_usecase.dart  # priorização RN-006
│       │       └── submit_verdict_usecase.dart
│       ├── presentation/
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
`test/modules/news/data/repositories/news_repository_impl_test.dart`.

O passo a passo de cada camada (model → datasource → repository → usecase → controller →
extension → página → module), com exemplos de código e testes, está em
[`ENDPOINT_INTEGRATION_CONTEXT.md`](../../click_seguro_app/ENDPOINT_INTEGRATION_CONTEXT.md).
Este plano define **o que** criar em cada fase; o guia define **como** cada peça é escrita.

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
| Data source (stateless, uma instância basta), pelo contrato | `registerLazySingleton` | `NewsRemoteDataSource` → `NewsRemoteDataSourceImpl(injector<ApiClient>())` |
| Usecase (stateless), pela classe concreta | `registerLazySingleton` | `GetNewsFeedUseCase` |
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

Controllers de página (Provider) recebem **usecases** (nunca repositories) e resolvem sua
dependência via `GetIt` no `create:`, nunca instanciando nada diretamente na árvore de widgets:

```dart
ChangeNotifierProvider(
  create: (_) => GetIt.instance<NewsDetailController>(param1: newsId),
)
```

---

## 2. Camada de Infraestrutura de Rede e Sessão

### 2.1 Cliente HTTP — `ApiClient`

`ApiClient` (único cliente HTTP do projeto) mantém a assinatura atual — `get/post/put/
delete`, `requiresAuth`, `_makeOptions`, `_safeRequest` — e é injetado pelo construtor em cada
`*RemoteDataSourceImpl`.

**Já implementado (v1.1.0):**

- `ApiException` classificada por `ApiErrorType`: `connection`, `timeout` (connect/send/receive),
  `cancelled`, `unauthorized` (401, com `UserSessionService.logout()` automático), `client`
  (demais 4xx), `server` (5xx), `invalidResponse`, `unknown`. Carrega também `statusCode`
  (anulável) e `errorCode` (campo `error` do corpo). `message` é técnica e não vai para a UI.
- Corpo de erro não-JSON (ex.: HTML de proxy) não quebra mais o mapeamento.
- `response.toModel(...)` / `toModelList(...)` convertem `TypeError`/`FormatException` de parse
  em `ApiException(type: invalidResponse)` — isso cumpre CB-005 sem `try/catch` em cada
  datasource.
- `ApiException.toFailure()` (`api_failure_mapper.dart`) faz o mapeamento padrão para
  `ConnectionFailure` / `UnauthorizedFailure` / `ServerFailure`.
- Testes em `test/modules/common/api_client/`, com `FakeHttpClientAdapter` reutilizável pelos
  testes de datasource.

**Pendente:**

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
  Um cancelamento chega como `ApiErrorType.cancelled`, que o repository de busca MUST ignorar
  (não é erro para o usuário).
- **Mapeamento de erro permanece 100% centralizado em `_safeRequest`** — nenhum
  repositório/data source MUST capturar `DioException` diretamente; datasources deixam
  `ApiException` subir e repositories a convertem em `Left(Failure)` (Seção V da
  constituição, CB-002/CB-004/CB-005 da especificação).

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
  já sem `ExceptionApiClient`), e só existe dentro de `data/`.
- `LogInterceptor`, já condicionado a `EnvironmentConfig.debugMode`, é o único mecanismo de
  log de requisição/resposta — nenhum módulo de feature MUST adicionar seu próprio log de
  rede.
- A mensagem amigável vem da `Failure`, não da exceção. `ApiException.toFailure()`
  (`common/api_client/api_failure_mapper.dart`) é o mapeamento padrão, e cada `Failure` carrega
  uma chave de `AppStrings`:

  | `ApiErrorType` | `Failure` | Chave | Requisito |
  |---|---|---|---|
  | `connection`, `timeout` | `ConnectionFailure` | `error_connection` | CB-002 |
  | `unauthorized` | `UnauthorizedFailure` | `error_session_expired` | CB-003 |
  | `server`, `client`, `invalidResponse`, `unknown`, `cancelled` | `ServerFailure` | `error_generic` | CB-004, CB-005 |

  Casos que a UI precisa distinguir (ex.: 409 em denúncia → `ReportAlreadyExistsFailure`,
  RN-003) são tratados no repository da feature **antes** do fallback `toFailure()`. Isso
  substitui o `ApiExceptionMessageMapper` previsto na v1.0.x.

---

## 3. Modelagem de Dados e Contratos

### 3.1 Entidades de domínio (puras, sem JSON)

- **`UserEntity`**: `id`, `name`, `email`, `role` (`UserRole.reader | UserRole.validator`).
- **`NewsEntity`**: `id`, `title`, `summary`, `body`, `sourceName`, `sourceUrl`,
  `publishedAt`, `category`, `veracityStatus` (`VeracityStatus`), `isFavorite`.
- **`VeracityStatus`** (enum): `unverified` (default — RN-002), `underReview`, `verified`,
  `fake`. Parse com `fromJson` tolerante: valor desconhecido cai em `unverified`.
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
        veracityStatus: VeracityStatus.fromJson(json['veracityStatus'] as String?),
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
conversão de JSON malformado (CB-005) já acontece em `response.toModel`/`toModelList`, que
transformam `TypeError`/`FormatException` em `ApiException(type: invalidResponse)`. O datasource
MUST usar essas extensões em vez de chamar `fromJson` sobre `response.data` diretamente.

### 3.3 Contratos abstratos — Repositórios e Data Sources

Cada feature define seu contrato de repositório no domínio e as fontes de dados na camada de
dados. O contrato do repository **sempre** devolve `Either<Failure, T>` e **nunca** lança; o
contrato do datasource devolve Models e lança `ApiException`:

```dart
// domain/repositories/news_repository.dart
abstract class NewsRepository {
  Future<Either<Failure, List<NewsEntity>>> getFeed({required int page, String? category});
  Future<Either<Failure, NewsEntity>> getById(String id);
  Future<Either<Failure, List<NewsEntity>>> search(String query);
  Future<Either<Failure, Unit>> toggleFavorite(String id);
  Future<Either<Failure, List<NewsEntity>>> getFavorites();
  Future<Either<Failure, Unit>> applyVerdict(String newsId, VeracityStatus newStatus); // fact_check
}

// data/datasources/news_remote_data_source.dart
abstract class NewsRemoteDataSource {
  Future<List<NewsModel>> fetchFeed({required int page, String? category});
  Future<NewsModel> fetchById(String id);
  /// Cancela a busca anterior ainda em andamento (RNF-005). O `CancelToken` é detalhe do
  /// Dio e fica guardado dentro do `NewsRemoteDataSourceImpl` — não aparece no domínio.
  Future<List<NewsModel>> search(String query);
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
com `type` `connection` ou `timeout`. Se o cache também estiver vazio, devolve
`Left(ConnectionFailure())`.

```dart
@override
Future<Either<Failure, List<NewsEntity>>> getFeed({required int page, String? category}) async {
  try {
    final news = await _remote.fetchFeed(page: page, category: category);
    if (page == 1 && category == null) await _local.cacheFeed(news);
    _lastFetchWasFromCache = false;
    return Right(news);
  } on ApiException catch (e) {
    final isOffline = e.type == ApiErrorType.connection || e.type == ApiErrorType.timeout;
    if (!isOffline) return Left(e.toFailure());
    final cached = await _local.getCachedFeed();
    if (cached.isEmpty) return const Left(ConnectionFailure());
    _lastFetchWasFromCache = true;
    return Right(cached);
  } catch (_) {
    return const Left(ServerFailure());
  }
}
```

`AuthRepository` e `FactCheckRepository` seguem a mesma forma (contrato no domínio com
`Either` + implementação sobre um `RemoteDataSource`, que recebe o `ApiClient` pelo construtor).

### 3.4 Usecases

Entre o controller e o repository existe sempre um usecase (um por arquivo, `call(...)`,
repository injetado pelo construtor — mesmo formato de `CheckOnboardingSeenUseCase`). É no
usecase que ficam as regras de negócio da especificação que não dependem de I/O:

| Usecase | Regra |
|---|---|
| `GetNewsFeedUseCase` | ordenação por data desc (RF-008) |
| `RegisterUseCase` | validação de e-mail/senha antes da rede (RN-001) |
| `ReportNewsUseCase` | bloqueio de denúncia duplicada já conhecida (RN-003/CB-006) |
| `GetValidationQueueUseCase` | priorização por volume de denúncias (RN-006) |
| `SubmitVerdictUseCase` | justificativa obrigatória + guard de `UserRole.validator` (RF-016/RN-004) |

Quando não há regra, o usecase só delega ao repository.

---

## 4. Gerenciamento de Estado na Apresentação

### 4.1 Decisão confirmada: Provider + ChangeNotifier

Por força da Seção IV da constituição, a solução de estado é **Provider + ChangeNotifier**,
não Bloc/Cubit. Cada `Controller` de feature expõe os estados de carregamento/sucesso/erro
como campos simples e diretos — sem um tipo de estado genérico intermediário — mantendo a
implementação a mais direta possível (KISS):

```dart
class FeedController extends ChangeNotifier {
  FeedController(this._getNewsFeedUseCase);
  final GetNewsFeedUseCase _getNewsFeedUseCase;

  List<NewsEntity> _news = [];
  List<NewsEntity> get news => List.unmodifiable(_news);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Failure? _failure;
  Failure? get failure => _failure;

  Future<void> loadFeed({String? category}) async {
    _isLoading = true;
    _failure = null;
    notifyListeners();

    final result = await _getNewsFeedUseCase(page: 1, category: category);
    result.fold(
      (failure) {
        _news = [];
        _failure = failure;
      },
      (news) => _news = news,
    );

    _isLoading = false;
    notifyListeners();
  }
}
```

Na UI, os campos são checados diretamente (nesta ordem: carregando, erro, vazio, dados). A
mensagem vem da `Failure` traduzida, nunca de `ApiException`:

```dart
if (controller.isLoading) {
  const CircularProgressIndicator();
} else if (controller.failure != null) {
  ErrorBanner(message: controller.failure!.message.tr());
} else if (controller.news.isEmpty) {
  EmptyState(message: AppStrings.newsEmptyFeed.tr());
} else {
  NewsFeedList(news: controller.news);
}
```

Cada `Controller` novo (Fases 2–4) segue exatamente esse formato — `isLoading`/`failure`/campo
de dado nomeado pelo que ele representa (`user`, `news`, `reportSentSuccessfully` etc.), todos
somente leitura —, sem introduzir uma abstração de estado compartilhada entre features.

### 4.2 Estado de autenticação reativo

`UserSessionService.sessionStatus` (`ValueNotifier<UserSessionStatus>`) continua sendo a
única fonte de verdade sobre sessão — é global e mais simples que um `ChangeNotifier` dedicado
para esse único valor. `AuthGate` (Seção 2.3) é o único widget que reage a ele para decisão de
navegação; `AuthenticationController` (login/registro) usa os mesmos campos simples
(`isLoading`/`failure`/`user`) para seus próprios estados de formulário e fala só com
`LoginUseCase`/`RegisterUseCase`. Quem chama `UserSessionService.saveSession` no login bem-sucedido
é o `AuthRepositoryImpl` (camada de dados), antes de devolver `Right(user)` — as duas reatividades
(`ValueNotifier` de sessão vs. `ChangeNotifier` de operação) coexistem por design, cada uma no
nível que lhe cabe (global vs. por-tela).

---

## 5. Fases de Desenvolvimento (Milestones)

Cada fase só é considerada concluída quando (a) o código correspondente existe, (b) há teste
automatizado cobrindo o caminho feliz e ao menos um caminho de erro (Seção III da
constituição), e (c) `flutter analyze` não introduz novo erro/warning.

### Fase 1 — Setup da Infraestrutura Base

- ✅ Padronizar a camada de erro HTTP: `ApiErrorType`, `errorCode`, parse seguro, `Failure`
  genéricas e `ApiException.toFailure()` (Seção 2.1/2.4) — concluído em 2026-09-26.
- Adicionar `flutter_secure_storage` ao `pubspec.yaml` (`shared_preferences` já está lá;
  justificativa na nota de alinhamento no topo deste documento).
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
- Criar `AuthRepository` (contrato com `Either<Failure, T>`) + `AuthRepositoryImpl` +
  `AuthRemoteDataSource` (+ `_impl`, recebendo `ApiClient`).
- Criar `LoginUseCase`, `RegisterUseCase` (validação RN-001) e `RequestPasswordResetUseCase`.
- Implementar `AuthenticationController` (campos `isLoading`/`failure`/`user`) para login,
  registro e recuperação de senha (RF-001, RF-002, RF-006).
- Criar `LoginPage`, `RegisterPage`, `ForgotPasswordPage` com validação de formulário alinhada
  a RN-001.
- Registrar tudo em `AuthenticationModule.registerServices`.
- Testes: `UserModel`, `AuthRemoteDataSourceImpl` (`FakeHttpClientAdapter`), `AuthRepositoryImpl`
  (fake de `AuthRemoteDataSource`, cada `ApiException` → `Failure`), usecases, `AuthenticationController`
  (estados idle/loading/success/error), validação de formulário (RN-001).

### Fase 3 — Módulo de Feed e Detalhamento de Notícias

- Criar `NewsEntity`, `VeracityStatus`, `NewsModel`.
- Criar `NewsRepository` (contrato com `Either<Failure, T>`) + `NewsRepositoryImpl` +
  `NewsRemoteDataSource` + `NewsLocalDataSource`, incluindo a lógica de fallback offline
  (RNF-002/CB-001).
- Criar `GetNewsFeedUseCase` (ordenação RF-008), `GetNewsDetailUseCase`, `SearchNewsUseCase` e
  `ToggleFavoriteUseCase`.
- Criar `NewsPresentationExtension` (rótulo do selo de veracidade, data formatada).
- Implementar `FeedController` (feed paginado + filtro de categoria + busca com debounce;
  o cancelamento via `CancelToken` fica no datasource, RF-008/RF-009/RF-010) e `NewsDetailController` (RF-011/RF-012).
- Implementar `FeedPage` (lista, filtro, busca, estado vazio CB-007, fim de paginação CB-008)
  e `NewsDetailPage` (selo de veracidade, favoritar — RF-013).
- Registrar tudo em `NewsModule.registerServices`.
- Testes: `NewsRepositoryImpl` (incluindo fallback para cache local quando `remote` falha por
  conexão), `FeedController` (paginação, filtro, busca cancelável), `NewsDetailController`.

### Fase 4 — Módulo de Validação / Checagem de Fatos (Fact-Checking)

- Criar `ReportEntity`, `ReportReason`, `VerdictEntity`, `FactCheckModel`s correspondentes.
- Criar `FactCheckRepository` (contrato) + `FactCheckRepositoryImpl` +
  `FactCheckRemoteDataSource`, dependendo de `NewsRepository` (via `GetIt`) para aplicar o
  novo `VeracityStatus` após um veredito (RF-016/RF-017). 409 na denúncia vira
  `ReportAlreadyExistsFailure` (RN-003).
- Criar `ReportNewsUseCase`, `GetValidationQueueUseCase` (priorização RN-006) e
  `SubmitVerdictUseCase` (justificativa obrigatória, guard de papel).
- Implementar `ReportController` (RF-015, com bloqueio de denúncia duplicada — RN-003/CB-006)
  e `ValidationQueueController` (fila priorizada por volume de denúncias — RN-006; RF-016).
- Implementar `ReportNewsPage` e `ValidationQueuePage`, esta última com checagem de papel
  (`UserRole.validator`) bloqueando acesso antes de qualquer chamada de API (RN-004/CB-009).
- Registrar tudo em `FactCheckModule.registerServices`.
- Testes: `FactCheckRepositoryImpl`, `ReportController` (idempotência de denúncia),
  `ValidationQueueController` (priorização e registro de veredito com histórico).

### Fase 5 — Tratamento Global de Erros, Estado Offline e Refinamento de Interface

- Conferir que todo controller expõe `failure` e que toda página exibe `failure.message.tr()`
  (o mapeamento `ApiException` → `Failure` já existe desde a Fase 1, Seção 2.4).
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
| `ReportReason` (enum) + checagem de duplicidade no `ReportNewsUseCase` + `ReportAlreadyExistsFailure` | RF-015, RN-003, CB-006 |
| `VerdictEntity` (histórico) | RF-017 |
| `SubmitVerdictUseCase`/`ValidationQueuePage` com guard de `UserRole` | RF-007, RN-004, CB-009 |
| `ApiErrorType` + `ApiException.toFailure()` + `Failure` genéricas | CB-002, CB-003, CB-004 |
| `toModel`/`toModelList` convertendo erro de parse em `invalidResponse` | CB-005 |
| `GetNewsFeedUseCase` (ordenação) | RF-008 |
| `RegisterUseCase` (validação antes da rede) | RN-001 |

---

## Governança deste documento

Este plano é o insumo direto para a geração de `tasks.md`: cada bullet das Fases 1–5 MUST
virar uma ou mais tarefas rastreáveis, na ordem apresentada (uma fase não inicia antes de a
anterior ter seus testes verdes). Qualquer desvio arquitetural encontrado durante a
implementação (ex.: um contrato de repositório precisar de um método a mais) MUST atualizar
este documento antes de a tarefa correspondente ser marcada concluída — o plano não pode ficar
desatualizado em relação ao código real.

**Versão**: 1.1.0 | **Criado em**: 2026-09-07 | **Última alteração**: 2026-09-26
