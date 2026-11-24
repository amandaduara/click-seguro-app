# Contexto: integração de endpoints (Endpoint → Página) no Click Seguro

> **Como usar este arquivo**
> - Referencie no prompt ou no `CLAUDE.md` antes de pedir uma nova integração a um agente de IA.
> - Ele descreve como levar um endpoint REST até a tela, camada por camada, com o teste escrito
>   **antes** do código de produção (TDD, Seção III da [constituição](../.specify/memory/constitution.md)).
>
> Adaptado do padrão do app CPF Seguro para as decisões deste projeto:
> **`Either<Failure, T>`** no lugar de exceções de domínio, **`ApiClient` injetado por construtor**
> (composição, não herança) e camada de UI chamada **`presentation/`**.
>
> `{modulo}` = nome do módulo da feature (ex.: `news`). O pacote é `click_seguro_app`.

---

## 1. Stack e convenções

| Tema | Escolha |
|------|---------|
| Arquitetura | DDD + Clean Architecture **modular** (`lib/modules/{modulo}/{data,domain,presentation}`) |
| Estado | **Provider + ChangeNotifier** |
| Injeção de dependência | **get_it** (`registerLazySingleton`), dentro de `ModuleInterface.registerServices` |
| Navegação | **go_router** (`lib/core/routing/app_router.dart`) |
| HTTP | **dio**, encapsulado no `ApiClient` único (`lib/modules/common/api_client/api_client.dart`) |
| Erros | **fpdart** — repositories e usecases retornam `Either<Failure, T>` |
| i18n | **easy_localization**; chaves em `AppStrings` + `assets/translations/{pt-BR,en-US}.json` |
| Testes | `flutter_test` com **Fakes escritos à mão** (sem Mockito/mocktail) |

Princípios:

- **Domain não depende** de Flutter, Dio, easy_localization nem de UI.
- **Data** faz parse (models) e acesso à API (datasources); o **repository é o único ponto** que
  transforma `ApiException` em `Failure`.
- **Presentation** renderiza e orquestra estado (controllers); regras de exibição ficam em
  **extensions** da camada presentation.
- A URL base vem de `--dart-define=API_URL=...`, lida só em `EnvironmentConfig`. Ela já inclui
  `/api/v1` (ex.: `https://<host>/api/v1`); os datasources usam caminhos como `/app/news`.
  Contrato da API: `.specify/memory/api-contract.md` e `openapi.json`.

---

## 2. Fluxo de dados e regra de dependência

```
       ┌─────────────────────────── PRESENTATION ───────────────────────────┐
Página ─► Consumer<Controller> ─► controller.load()                          │
  ▲                                   │                                      │
  │  failure.message.tr()             ▼                                      │
  └────────── notifyListeners() ◄── Controller: result.fold(falha, sucesso)  │
       └──────────────────────────────┬──────────────────────────────────────┘
                                      ▼
       ┌───────────────────────────── DOMAIN ───────────────────────────────┐
       │ UseCase ─► Repository (contrato) ─► Future<Either<Failure, T>>     │
       │ Entities · Enums · Failures específicas da feature                 │
       └──────────────────────────────┬──────────────────────────────────────┘
                                      ▼  (implementação injetada via get_it)
       ┌────────────────────────────── DATA ────────────────────────────────┐
       │ RepositoryImpl ─try/catch─► Datasource ─► ApiClient (singleton)     │
       │  ApiException → Failure     response.toModel(Model.fromJson)        │
       └─────────────────────────────────────────────────────────────────────┘
```

- As dependências apontam sempre para o domínio: `presentation → domain ← data`.
- O datasource devolve **Models**; repository, usecase e controller expõem **Entities** (o Model
  *é* uma Entity por herança, então não há mapper).
- Caminho do erro: `DioException` → **`ApiException`** (no `ApiClient`, com `ApiErrorType`) →
  **`Left(Failure)`** (no repository) → `failure` (no controller) → `failure.message.tr()` (na página).
- **Datasource lança, repository nunca lança.** Nenhuma exceção passa do repository para cima.

---

## 3. Estrutura de pastas e nomenclatura

```
lib/modules/{modulo}/
├── {modulo}.dart                          # barrel público do módulo (module + páginas)
├── {modulo}_module.dart                   # DI (get_it) + providers (ChangeNotifierProvider)
├── data/
│   ├── datasources/
│   │   ├── {feature}_remote_data_source.dart       # abstract class {Feature}RemoteDataSource
│   │   └── {feature}_remote_data_source_impl.dart  # implementação sobre ApiClient
│   ├── models/{entity}_model.dart                  # class {Entity}Model extends {Entity}Entity
│   └── repositories/{feature}_repository_impl.dart # implements {Feature}Repository
├── domain/
│   ├── entities/{entity}_entity.dart               # dados + predicados de negócio
│   ├── enums/{nome}.dart                           # enums com fromJson tolerante (fallback)
│   ├── failures/{feature}_failures.dart            # (opcional) Failures específicas da feature
│   ├── repositories/{feature}_repository.dart      # abstract class {Feature}Repository
│   └── usecases/{acao}_{feature}_usecase.dart      # 1 caso de uso por arquivo
└── presentation/
    ├── controller/{feature}_controller.dart        # extends ChangeNotifier
    ├── extensions/{entity}_presentation_extension.dart
    ├── pages/{feature}_page.dart
    └── widgets/{item}_widget.dart                  # widgets "burros"

test/modules/{modulo}/                              # espelha lib/modules/{modulo}/
├── data/models/{entity}_model_test.dart
├── data/datasources/{feature}_remote_data_source_impl_test.dart
├── data/repositories/{feature}_repository_impl_test.dart
├── domain/usecases/{acao}_{feature}_usecase_test.dart
├── presentation/controller/{feature}_controller_test.dart
├── presentation/extensions/{entity}_presentation_extension_test.dart
└── fakes/                                          # Fakes compartilhados do módulo
```

`data/` e `domain/` só existem em módulos com regra de negócio ou acesso a dados (ver
`onboarding`). Um módulo de bootstrap, como `splash`, pode ter só `presentation/`.

---

## 4. Infraestrutura comum (já existe)

Não recrie nada disto; só use.

### 4.1 `ApiClient`, `ApiException` e `ApiErrorType`

`lib/modules/common/api_client/api_client.dart`, registrado como singleton no `CommonModule`.

```dart
final response = await apiClient.get('/app/news', queryParameters: {'page': 1});
final response = await apiClient.post('/auth/app/login', data: body, requiresAuth: false);
final response = await apiClient.patch('/users/me', data: {'name': name});
// put / delete seguem o mesmo formato. requiresAuth = true envia o Bearer da sessão.

// Busca que pode ser descartada (ex.: usuário digitou de novo): cancelar → ApiErrorType.cancelled
final response = await apiClient.get('/app/news', queryParameters: q, cancelToken: token);

// Upload (ex.: avatar): o ApiClient monta o FormData; o datasource só passa o arquivo
final response = await apiClient.postMultipart('/users/me/avatar',
    fieldName: 'avatar', filePath: path, contentType: 'image/jpeg');
```

- Qualquer falha HTTP sai como **`ApiException`**, com:
  - `type` (`ApiErrorType`): `connection`, `timeout`, `cancelled`, `unauthorized`, `client` (4xx),
    `server` (5xx), `invalidResponse`, `unknown`;
  - `statusCode` (`int?`), `errorCode` (campo **`code`** do corpo `{ "code": "...", "message": "..." }`,
    ex.: `USER_EMAIL_ALREADY_EXISTS`; `null` quando o corpo não segue esse formato, como no erro
    de validação do Zod) e `message` (**técnica**, só para log, nunca para o usuário).
- **401 e sessão** já são decididos dentro do `ApiClient`. Não trate isso de novo:
  - pedido com token recusado → renova a credencial (`/auth/app/refresh`) uma vez e repete o
    pedido; renovação recusada → `UserSessionService.expire()`;
  - `INVALID_CREDENTIALS` (senha errada no login ou na troca de senha) **nunca** mexe na sessão.
    Ele chega como `ApiErrorType.unauthorized`, então o repository MUST testar
    `e.errorCode == ApiErrorCodes.invalidCredentials` **antes** do `toFailure()` (senão vira
    `UnauthorizedFailure`);
  - 404 `USER_NOT_FOUND` (conta desativada) com token → `expire()`.

  Regras completas: `specs/002-apiclient-renovacao-sessao/contracts/api-client-and-session.md`.
- Códigos de negócio que o repository compara MUST ser constantes nomeadas (constituição V).
  Os do `common` ficam em `ApiErrorCodes`; os da feature, no próprio repository.
- Parse: `response.toModel(XModel.fromJson)` (objeto) e `response.toModelList(XModel.fromJson)`
  (array na raiz). Se o JSON não bater com o model (`TypeError`/`FormatException`), eles lançam
  `ApiException(type: ApiErrorType.invalidResponse)`, então o datasource não precisa de `try/catch`.

### 4.2 `Failure` e mapeamento padrão

`lib/core/errors/` (barrel `errors.dart`):

| Failure | Quando |
|---|---|
| `ConnectionFailure` | `ApiErrorType.connection` / `timeout` |
| `UnauthorizedFailure` | `ApiErrorType.unauthorized` (a sessão já foi encerrada) |
| `ServerFailure` | todo o resto (fallback genérico) |
| `CacheFailure` | falha em armazenamento local |

`Failure.message` é uma **chave de tradução** (`AppStrings.errorConnection` etc.). A página exibe
com `failure.message.tr()`.

O mapeamento padrão fica em `lib/modules/common/api_client/api_failure_mapper.dart`:

```dart
on ApiException catch (e) {
  return Left(e.toFailure());
}
```

### 4.3 Sistema de módulos

`ModuleInterface` (`registerServices` + `providers`) e `ModuleManager` em
`lib/modules/common/core/module/`. No `main.dart`, o `CommonModule()` é registrado **primeiro**,
então `injector<ApiClient>()` já está disponível em qualquer módulo de feature.

---

## 5. Passo a passo com TDD (de dentro para fora)

Ordem: **contrato → entity/model → datasource → repository → usecase → controller → extension →
widget/página → DI, rotas e traduções**.
Em cada passo: **Red** (teste falhando) → **Green** (mínimo para passar) → **Refactor**.

Exemplo: feature fictícia **"Notícias"** (módulo `news`), que lista o feed.

### Passo 0 — Documente o contrato do endpoint

```
GET /app/news?page=1&limit=20   (auth opcional)
200 → { "data": [ { "id": "n1", "title": "...", "source": "...",
                    "originalPublishedAt": "2026-09-01T10:00:00Z" } ],
        "meta": { "page": 1, "hasNextPage": true } }
403 → { "code": "FORBIDDEN", "message": "Access denied for this context" }
```

Liste **todos os status de erro** e o que o usuário deve ver em cada um. Essa lista vira a tabela
de mapeamento do repository (passo 4).

### Passo 1 — Domain: Entity + Enum

A entity guarda **dados + predicados de negócio**, sem formatação e sem texto de UI.

```dart
// domain/enums/veracity_status.dart
enum VeracityStatus {
  unverified,
  underReview,
  verified,
  fake;

  /// Nunca quebra com valor novo da API: cai em [unverified] (RN-002).
  static VeracityStatus fromJson(String? value) {
    return switch (value) {
      'UNDER_REVIEW' => VeracityStatus.underReview,
      'VERIFIED' => VeracityStatus.verified,
      'FAKE' => VeracityStatus.fake,
      _ => VeracityStatus.unverified,
    };
  }
}
```

```dart
// domain/entities/news_entity.dart
class NewsEntity {
  const NewsEntity({
    required this.id,
    required this.title,
    required this.veracityStatus,
    required this.publishedAt,
  });

  final String id;
  final String title;
  final VeracityStatus veracityStatus;
  final DateTime? publishedAt;

  bool get isFake => veracityStatus == VeracityStatus.fake;
}
```

### Passo 2 — Data: Model (teste primeiro)

**Teste (Red):**

```dart
// test/modules/news/data/models/news_model_test.dart
void main() {
  group('NewsModel.fromJson', () {
    test('faz o parse de um JSON completo', () {
      final model = NewsModel.fromJson({
        'id': 'n1',
        'title': 'Título',
        'veracityStatus': 'FAKE',
        'publishedAt': '2026-09-01T10:00:00Z',
      });

      expect(model, isA<NewsEntity>());
      expect(model.veracityStatus, VeracityStatus.fake);
      expect(model.publishedAt, DateTime.utc(2026, 9, 1, 10));
    });

    test('aplica fallback para opcionais e status desconhecido', () {
      final model = NewsModel.fromJson({'id': 'n1', 'veracityStatus': 'NOVO'});

      expect(model.title, '');
      expect(model.veracityStatus, VeracityStatus.unverified);
      expect(model.publishedAt, isNull);
    });
  });
}
```

**Implementação (Green):**

```dart
// data/models/news_model.dart
class NewsModel extends NewsEntity {
  const NewsModel({
    required super.id,
    required super.title,
    required super.veracityStatus,
    required super.publishedAt,
  });

  factory NewsModel.fromJson(Map<String, dynamic> json) {
    return NewsModel(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      veracityStatus: VeracityStatus.fromJson(json['veracityStatus'] as String?),
      publishedAt: DateTime.tryParse(json['publishedAt'] as String? ?? ''),
    );
  }
}
```

Regras para models:
- Sempre `extends {Entity}Entity` + `factory fromJson`. Crie `toJson` só quando o model vira body
  de request ou é salvo em cache local.
- Cast explícito (`as String`, `as String?`) e fallback para campos opcionais. Campo obrigatório
  ausente pode lançar `TypeError`, e o `toModel` converte isso em `invalidResponse`.
- Objetos aninhados: `ChildModel.fromJson(json['child'] as Map<String, dynamic>)`. Listas:
  `(json['items'] as List<dynamic>? ?? []).map(...).toList()`.
- Models só existem quando há **JSON externo**. Datasources locais podem devolver entities.

### Passo 3 — Data: Datasource (interface + impl)

```dart
// data/datasources/news_remote_data_source.dart
abstract class NewsRemoteDataSource {
  /// Lança [ApiException] em caso de falha.
  Future<List<NewsModel>> fetchFeed({required int page});
}
```

```dart
// data/datasources/news_remote_data_source_impl.dart
class NewsRemoteDataSourceImpl implements NewsRemoteDataSource {
  NewsRemoteDataSourceImpl(this._apiClient);

  final ApiClient _apiClient;

  static const String _feedEndpoint = '/news';

  @override
  Future<List<NewsModel>> fetchFeed({required int page}) async {
    final response = await _apiClient.get(
      _feedEndpoint,
      queryParameters: {'page': page},
    );
    // Array na raiz. Para envelope { "data": [...] }:
    // response.toModel((json) => (json['data'] as List).map(...).toList())
    return response.toModelList(NewsModel.fromJson);
  }
}
```

Regras para datasources:
- Recebem `ApiClient` pelo **construtor**. Nunca instanciam `Dio` nem herdam do client.
- Endpoints como `static const String _nomeEndpoint` no topo da classe.
- **Sem regra de negócio, sem `try/catch`, sem `Either`.** Só chamam, fazem o parse e deixam
  `ApiException` subir.

**Teste do datasource:** injete um `ApiClient` real com Dio fake. Use o
`FakeHttpClientAdapter` de `test/modules/common/api_client/fake_http_client_adapter.dart`:

```dart
final adapter = FakeHttpClientAdapter()..body = [{'id': 'n1'}];
final apiClient = ApiClient(dio: Dio(BaseOptions(baseUrl: 'https://api.test'))
  ..httpClientAdapter = adapter);
// registre um UserSessionService no GetIt no setUp; GetIt.instance.reset() no tearDown
final result = await NewsRemoteDataSourceImpl(apiClient).fetchFeed(page: 2);
expect(adapter.lastRequest!.uri.queryParameters['page'], '2');
```

### Passo 4 — Domain + Data: Repository (teste primeiro)

**Contrato (domain).** Retorna sempre `Either<Failure, Entity>`, nunca Model e nunca lança.

```dart
// domain/repositories/news_repository.dart
abstract class NewsRepository {
  Future<Either<Failure, List<NewsEntity>>> getFeed({required int page});
}
```

**Failures específicas (opcional).** Crie só quando a UI precisa **distinguir** o cenário. A
mensagem é uma chave de `AppStrings`.

```dart
// domain/failures/news_failures.dart
class NewsForbiddenFailure extends Failure {
  const NewsForbiddenFailure() : super(AppStrings.newsErrorForbidden);
}
```

**Fake do datasource + teste (Red):**

```dart
// test/modules/news/fakes/fake_news_remote_data_source.dart
class FakeNewsRemoteDataSource implements NewsRemoteDataSource {
  List<NewsModel> result = [];
  Object? error;
  int calls = 0;
  int? lastPage;

  @override
  Future<List<NewsModel>> fetchFeed({required int page}) async {
    calls++;
    lastPage = page;
    if (error != null) throw error!;
    return result;
  }
}
```

```dart
// test/modules/news/data/repositories/news_repository_impl_test.dart
void main() {
  late FakeNewsRemoteDataSource remote;
  late NewsRepositoryImpl repository;

  setUp(() {
    remote = FakeNewsRemoteDataSource();
    repository = NewsRepositoryImpl(remote);
  });

  ApiException apiError(ApiErrorType type, [int? status]) =>
      ApiException(type: type, statusCode: status, message: '');

  test('repassa a página e devolve Right com as entities', () async {
    remote.result = [
      const NewsModel(id: 'n1', title: 'T',
          veracityStatus: VeracityStatus.verified, publishedAt: null),
    ];

    final result = await repository.getFeed(page: 2);

    expect(remote.lastPage, 2);
    expect(result.getRight().toNullable()!.single.id, 'n1');
  });

  test('403 vira Left(NewsForbiddenFailure)', () async {
    remote.error = apiError(ApiErrorType.client, 403);
    final result = await repository.getFeed(page: 1);
    expect(result.getLeft().toNullable(), isA<NewsForbiddenFailure>());
  });

  test('sem conexão vira Left(ConnectionFailure)', () async {
    remote.error = apiError(ApiErrorType.connection);
    final result = await repository.getFeed(page: 1);
    expect(result.getLeft().toNullable(), isA<ConnectionFailure>());
  });

  test('erro inesperado vira Left(ServerFailure)', () async {
    remote.error = StateError('boom');
    final result = await repository.getFeed(page: 1);
    expect(result.getLeft().toNullable(), isA<ServerFailure>());
  });
}
```

**Implementação (Green):**

```dart
// data/repositories/news_repository_impl.dart
class NewsRepositoryImpl implements NewsRepository {
  NewsRepositoryImpl(this._remote);

  final NewsRemoteDataSource _remote;

  @override
  Future<Either<Failure, List<NewsEntity>>> getFeed({required int page}) async {
    try {
      return Right(await _remote.fetchFeed(page: page));
    } on ApiException catch (e) {
      return Left(_mapError(e));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  Failure _mapError(ApiException e) {
    if (e.statusCode == 403) return const NewsForbiddenFailure();
    return e.toFailure();
  }
}
```

Regras para repositories:
- É a **única** fonte de verdade de cada tipo de dado. Orquestra remoto + local quando houver os
  dois (ex.: fallback para cache quando `e.type == ApiErrorType.connection`).
- **Toda** exceção vira `Left(Failure)` aqui. Ordem: casos específicos da feature → `e.toFailure()`
  → `catch (_)` genérico → `ServerFailure`.
- Decisões por código de negócio usam `e.errorCode` comparado com **constante nomeada**, nunca com
  string literal solta (Seção V da constituição).
- Se o mapeamento se repete entre métodos, extraia um `_mapError(ApiException e)` privado.

### Passo 5 — Domain: UseCase (teste primeiro)

Um caso de uso por arquivo, com `call(...)`, recebendo o repository pelo construtor (mesmo formato
de `CheckOnboardingSeenUseCase`). **Regra de negócio fica aqui** (validação, ordenação, combinação
de repositories). Se não há regra, o usecase só delega. Mais de um argumento, ou argumento que
pode crescer, vira uma classe `Params`.

**Fake do repository + teste (Red):**

```dart
// test/modules/news/fakes/fake_news_repository.dart
class FakeNewsRepository implements NewsRepository {
  Either<Failure, List<NewsEntity>> result = const Right([]);
  int? lastPage;

  @override
  Future<Either<Failure, List<NewsEntity>>> getFeed({required int page}) async {
    lastPage = page;
    return result;
  }
}
```

```dart
// test/modules/news/domain/usecases/get_news_feed_usecase_test.dart
void main() {
  late FakeNewsRepository repository;
  late GetNewsFeedUseCase usecase;

  setUp(() {
    repository = FakeNewsRepository();
    usecase = GetNewsFeedUseCase(repository);
  });

  NewsEntity news(String id, DateTime? at) => NewsEntity(
      id: id, title: id, veracityStatus: VeracityStatus.verified, publishedAt: at);

  test('ordena da mais recente para a mais antiga (RF-010)', () async {
    repository.result = Right([
      news('old', DateTime(2026, 1, 1)),
      news('new', DateTime(2026, 3, 1)),
      news('no-date', null),
    ]);

    final result = await usecase(page: 1);

    expect(result.getRight().toNullable()!.map((n) => n.id),
        ['new', 'old', 'no-date']);
  });

  test('propaga o Left do repository', () async {
    repository.result = const Left(ConnectionFailure());
    final result = await usecase(page: 1);
    expect(result.getLeft().toNullable(), isA<ConnectionFailure>());
  });
}
```

**Implementação (Green):**

```dart
// domain/usecases/get_news_feed_usecase.dart
class GetNewsFeedUseCase {
  GetNewsFeedUseCase(this._repository);

  final NewsRepository _repository;

  Future<Either<Failure, List<NewsEntity>>> call({int page = 1}) async {
    final result = await _repository.getFeed(page: page);
    return result.map(
      (news) => [...news]..sort((a, b) {
          if (a.publishedAt == null) return 1;
          if (b.publishedAt == null) return -1;
          return b.publishedAt!.compareTo(a.publishedAt!);
        }),
    );
  }
}
```

### Passo 6 — Presentation: Controller (teste primeiro)

O controller recebe usecases pelo construtor, expõe estado **somente leitura** e chama
`notifyListeners()` ao entrar e ao sair de cada operação. Estado padrão:

- `isLoading`: carregamento inicial ou recarga.
- `failure`: `Failure?` do último carregamento.
- Dados expostos como `List.unmodifiable(...)`.

**Teste (Red).** Injete o **usecase real** com o **FakeRepository**. Assim não é preciso fakear o
usecase.

```dart
// test/modules/news/presentation/controller/feed_controller_test.dart
void main() {
  late FakeNewsRepository repository;
  late FeedController controller;

  setUp(() {
    repository = FakeNewsRepository();
    controller = FeedController(GetNewsFeedUseCase(repository));
  });

  test('load() alterna isLoading e preenche news', () async {
    repository.result = const Right([
      NewsEntity(id: 'n1', title: 'T',
          veracityStatus: VeracityStatus.verified, publishedAt: null),
    ]);
    final loading = <bool>[];
    controller.addListener(() => loading.add(controller.isLoading));

    await controller.load();

    expect(loading, [true, false]);
    expect(controller.news.single.id, 'n1');
    expect(controller.failure, isNull);
  });

  test('load() expõe a failure e limpa a lista', () async {
    repository.result = const Left(ServerFailure());

    await controller.load();

    expect(controller.news, isEmpty);
    expect(controller.failure, isA<ServerFailure>());
    expect(controller.isLoading, isFalse);
  });
}
```

**Implementação (Green):**

```dart
// presentation/controller/feed_controller.dart
class FeedController extends ChangeNotifier {
  FeedController(this._getNewsFeedUseCase);

  final GetNewsFeedUseCase _getNewsFeedUseCase;

  List<NewsEntity> _news = [];
  List<NewsEntity> get news => List.unmodifiable(_news);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Failure? _failure;
  Failure? get failure => _failure;

  Future<void> load() async {
    _isLoading = true;
    _failure = null;
    notifyListeners();

    final result = await _getNewsFeedUseCase();
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

Regras para controllers:
- Conversam **só com usecases**, nunca com repository, datasource ou `ApiClient`.
- Sem `BuildContext`, navegação ou widgets. Métodos de ação podem retornar `bool` ou a `Failure?`,
  e a página decide o que fazer (toast, navegação).
- Estado de tela (loading, filtros, paginação, seleção) fica aqui, e **não** na entity.
- Não há `try/catch`: o usecase já devolve `Either`.

### Passo 7 — Presentation: Extension de exibição (teste primeiro)

**Como exibir** (label, data formatada, visibilidade de selo) fica numa extension da camada
presentation, e não na entity.

| Fica na entity (domain) | Fica na extension (presentation) |
|---|---|
| `isFake`, campos, `copyWith` | `veracityLabel`, `formattedDate`, `showFakeBadge` |
| Predicados de negócio | Textos com `.tr()`, formatadores, fallbacks visuais |

```dart
// presentation/extensions/news_presentation_extension.dart
extension NewsPresentationExtension on NewsEntity {
  String get veracityLabel => switch (veracityStatus) {
        VeracityStatus.verified => AppStrings.newsVeracityVerified.tr(),
        VeracityStatus.underReview => AppStrings.newsVeracityUnderReview.tr(),
        VeracityStatus.fake => AppStrings.newsVeracityFake.tr(),
        VeracityStatus.unverified => AppStrings.newsVeracityUnverified.tr(),
      };

  String get formattedDate => publishedAt == null
      ? ''
      : '${publishedAt!.day.toString().padLeft(2, '0')}/'
          '${publishedAt!.month.toString().padLeft(2, '0')}/${publishedAt!.year}';

  bool get showFakeBadge => isFake;
}
```

Teste: sem `EasyLocalization` inicializado, `.tr()` devolve a própria chave. Compare pela chave
(`expect(news.veracityLabel, AppStrings.newsVeracityFake)`).

### Passo 8 — Presentation: Widget "burro" e Página

O **widget** recebe apenas valores prontos (strings e flags), sem entity e sem lógica.

```dart
// presentation/widgets/news_card_widget.dart
class NewsCardWidget extends StatelessWidget {
  const NewsCardWidget({
    super.key,
    required this.title,
    required this.subtitle,
    required this.veracityLabel,
    required this.showFakeBadge,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final String veracityLabel;
  final bool showFakeBadge;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SafeCard(/* ... usa SafeBadge quando showFakeBadge ... */);
  }
}
```

A **página** dispara o carregamento no primeiro frame, observa o controller com `Consumer` e trata
os estados **loading → erro (com "tentar novamente") → vazio → lista**. A ligação entity → widget
passa pela extension.

```dart
// presentation/pages/feed_page.dart
class _FeedPageState extends State<FeedPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FeedController>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Consumer<FeedController>(
          builder: (context, controller, _) {
            if (controller.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            final failure = controller.failure;
            if (failure != null) {
              return Column(children: [
                Text(failure.message.tr()),
                SafeButton(
                  label: AppStrings.commonTryAgain.tr(),
                  onPressed: controller.load,
                ),
              ]);
            }
            if (controller.news.isEmpty) {
              return Center(child: Text(AppStrings.newsEmptyFeed.tr()));
            }
            return ListView.builder(
              itemCount: controller.news.length,
              itemBuilder: (context, index) {
                final news = controller.news[index];
                return NewsCardWidget(
                  title: news.title,
                  subtitle: news.formattedDate,
                  veracityLabel: news.veracityLabel,
                  showFakeBadge: news.showFakeBadge,
                  onTap: () => context.push('/news/${news.id}'),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
```

Regras de presentation:
- `context.read<T>()` para disparar ações; `Consumer<T>`/`context.watch<T>()` para reconstruir.
- Feedback de ação (toast, bottom sheet, navegação) acontece na página, depois do `await` e da
  checagem de `mounted`.
- Todo texto visível passa por `.tr()`, com a chave em `AppStrings` e nos dois arquivos de tradução.
- Reaproveite os widgets do design system em `lib/core/widgets/` (`SafeButton`, `SafeCard`,
  `SafeBadge`, `SafeTextField`).

### Passo 9 — Wiring: Module (DI), rotas e traduções

```dart
// news_module.dart
class NewsModule implements ModuleInterface {
  @override
  FutureOr<void> registerServices(GetIt injector) {
    // Datasources
    injector.registerLazySingleton<NewsRemoteDataSource>(
      () => NewsRemoteDataSourceImpl(injector<ApiClient>()),
    );

    // Repositories
    injector.registerLazySingleton<NewsRepository>(
      () => NewsRepositoryImpl(injector<NewsRemoteDataSource>()),
    );

    // Usecases
    injector.registerLazySingleton<GetNewsFeedUseCase>(
      () => GetNewsFeedUseCase(injector<NewsRepository>()),
    );
  }

  @override
  List<SingleChildWidget> providers(GetIt injector) {
    return [
      ChangeNotifierProvider(
        create: (_) => FeedController(injector<GetNewsFeedUseCase>()),
      ),
    ];
  }
}
```

- Datasources e repositories registrados **pelo tipo abstrato**; usecases pela classe concreta.
- Adicione `NewsModule()` em `registerModules` no `main.dart`, **depois** de `CommonModule()`.
- Exporte o module e as páginas públicas no barrel `news.dart`.

**Rotas** em `lib/core/routing/app_router.dart`:

```dart
GoRoute(path: '/news', builder: (context, state) => const FeedPage()),
// Navegação: context.go('/news') ou context.push('/news/$id')
```

**Traduções:** chave constante em `AppStrings` e valor nos dois JSONs. As chaves são planas, em
`snake_case` e prefixadas pelo módulo:

```dart
// lib/core/i18n/app_strings.dart
static const String newsEmptyFeed = 'news_empty_feed';
static const String newsErrorForbidden = 'news_error_forbidden';
```

```json
// assets/translations/pt-BR.json
"news_empty_feed": "Nenhuma notícia encontrada",
"news_error_forbidden": "Você não tem permissão para ver estas notícias."
```

---

## 6. Anti-padrões (não fazer)

- ❌ Repository **lançando** exceção ou deixando `ApiException` escapar. Ele sempre devolve `Either`.
- ❌ Contrato de repository (domain) retornando `XModel`. Retorne `XEntity`.
- ❌ Datasource com `try/catch`, `Either` ou regra de negócio.
- ❌ Datasource herdando de `ApiClient` ou criando `Dio` próprio. Injete o `ApiClient`.
- ❌ Controller chamando datasource, repository ou `ApiClient` diretamente.
- ❌ Exibir `ApiException.message` para o usuário. Exiba `failure.message.tr()`.
- ❌ Comparar `statusCode == 0` para detectar falta de conexão. Use `ApiErrorType.connection`.
- ❌ Tratar 401 no repository ou na tela chamando `logout()`/`expire()` ou renovando o token. O
  `ApiClient` já faz isso (exceção: mapear `INVALID_CREDENTIALS` para a `Failure` da feature).
- ❌ Getters de apresentação (`.tr()`, formatação) dentro da entity.
- ❌ Widget de lista recebendo a entity e decidindo o que mostrar.
- ❌ Enum parseado com `values.byName(...)` sem fallback. Use `fromJson` tolerante.
- ❌ Textos hardcoded na UI ou em `Failure`. Use chaves de `AppStrings`.
- ❌ Mockito/mocktail. Use Fakes simples com contadores (`calls`, `lastX`) e resultado configurável.

---

## 7. Checklist de uma nova integração

- [ ] Contrato do endpoint documentado (request, resposta 2xx e todos os erros).
- [ ] Entity e enums com `fromJson` tolerante (domain).
- [ ] `{Entity}Model extends {Entity}Entity` + `fromJson`, **com teste**.
- [ ] `{Feature}RemoteDataSource` + `Impl` recebendo `ApiClient`, endpoints em `static const`.
- [ ] Failures específicas da feature (só se a UI precisar distinguir), com chave em `AppStrings`.
- [ ] Contrato `{Feature}Repository` com `Either<Failure, T>` + `Impl` mapeando cada erro, **com
      teste** via FakeDataSource.
- [ ] `{Acao}{Feature}UseCase` com a regra de negócio, **com teste** via FakeRepository.
- [ ] `{Feature}Controller extends ChangeNotifier` com `isLoading`/`failure`/dados imutáveis, **com
      teste** (usecase real + FakeRepository).
- [ ] Extension de exibição, **com teste**.
- [ ] Widget "burro" + página tratando loading, erro, vazio e dados.
- [ ] Registro no `{Modulo}Module` e módulo incluído no `main.dart`.
- [ ] Rota no `app_router.dart`.
- [ ] Chaves em `AppStrings`, `pt-BR.json` e `en-US.json`.
- [ ] `flutter analyze` e `flutter test` passando.

---

## 8. Prompt modelo para pedir uma nova integração a um agente

```
Siga o arquivo click_seguro_app/ENDPOINT_INTEGRATION_CONTEXT.md e a constituição em
.specify/memory/constitution.md.

Módulo: {modulo}
Feature: {descrição curta}
Endpoint: {MÉTODO} {path}  (autenticado: sim/não)
Request: {body/query de exemplo}
Resposta {status esperado}: {JSON de exemplo}
Erros: {status/errorCode → o que o usuário deve ver}
Regra de negócio no usecase: {ex.: ordenar por data desc / validar X}
Exibição: {página nova ou existente; o que mostrar por item; estados vazio/erro}

Trabalhe em TDD, camada por camada, na ordem: model → datasource → repository →
usecase → controller → extension → widget/página → module/rotas/traduções.
Em cada camada escreva primeiro o teste (Fakes à mão, sem Mockito), veja falhar e
depois implemente o mínimo para passar. Não altere código não relacionado. No fim,
rode `flutter analyze` e `flutter test`.
```
