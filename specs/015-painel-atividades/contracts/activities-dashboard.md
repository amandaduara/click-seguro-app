# Contrato: painel de atividades (API usada, rotas, sessão e tela)

**Feature**: [../spec.md](../spec.md) · **Plan**: [../plan.md](../plan.md)

## 1. Endpoints (contrato da API → 1.0.10, conferidos em 2026-10-19, R0)

| Método e caminho | Quando | Sucesso | Erros tratados |
|---|---|---|---|
| `GET /app/educational/modules` | toda carga do painel; sem token sem conta (visitante, sessão expirada) | 200 `{modules[], totalLessonsCompleted, totalLessonsAvailable}` | padrão → estado de erro (ou mantém o conteúdo na recarga) |
| `POST /app/educational/modules/{moduleId}/lessons/{lessonId}/answer` `{selectedOptionId}` | só na transferência, com token da conta recém-criada | 200 (resultado ignorado; a lição fica concluída) | 404 `EDUCATIONAL_*_NOT_FOUND` e 400 → descarta a resposta; demais → tenta na próxima carga |

## 2. Rotas

| Caminho | Tela | Muda? |
|---|---|---|
| `/activities` (aba 2) | `ActivitiesDashboardPage` (antes: `ActivitiesPage` provisória) | sim |
| `/activities/:moduleId` (sobre as abas) | `ActivityModulePage` provisória até a B2 | não |
| `/login` | aberta pelo botão do aviso do visitante (`go`) | não |

## 3. Sessão (`common`)

```dart
Future<void> saveSession({
  required String accessToken,
  required String refreshToken,
  required String email,
  String? userName,
  bool newAccount = false,          // NOVO: true só no cadastro
});

bool get startedFromSignUp;         // NOVO: só memória; definido antes de sessionStatus mudar
```

## 4. Interface do módulo `activities` para a B3

O `GuestProgressStore` fica interno ao módulo (`activities/data`), registrado no `GetIt`; a B3, no
mesmo módulo, chama:

```dart
void recordAnswer({
  required String moduleId,
  required String lessonId,
  required String selectedOptionId,
});
int answeredCount(String moduleId);
```

O barrel `activities.dart` continua exportando só o módulo, as rotas e as páginas.

## 5. Tela (de cima para baixo)

```text
AppTopBar: "Atividades" (saudação, sino e engrenagem como nas outras abas)
[só visitante (isGuest); não na sessão expirada] aviso: "Sem conta, seu progresso vale até fechar o app." [Entrar ou criar conta]
[se totalAvailable > 0] cartão "Seu progresso": "4 de 9 lições concluídas" + barra
cartões dos módulos, na ordem do serviço:
  letra 100%  → duas colunas, descrição até 3 linhas
  letra > 100% → uma coluna, descrição inteira
  cada cartão: ícone · título · descrição · "2 de 3 lições" · selo de status
```

| Estado | Conteúdo |
|---|---|
| carregando | `SafeLoadingState`; depois de 5 s, aviso de servidor acordando |
| erro (sem conteúdo) | `SafeErrorState` com "Tentar novamente" |
| vazio | `SafeEmptyState` "Ainda não há atividades" (sem cartão de progresso) |
| recarga falha (com conteúdo) | conteúdo mantido, sem aviso |

| Toque | Efeito |
|---|---|
| cartão disponível | `push('/activities/{id}')` uma vez; na volta, recarrega |
| cartão indisponível | nada (sem `button` na semântica) |
| voltar à aba | recarrega sem mostrar "carregando" |
| "Entrar ou criar conta" | `go('/login')` |

Semântica de cada cartão: um item com título, status, "X de Y lições" e a descrição inteira;
disponível → botão "Abrir módulo".
