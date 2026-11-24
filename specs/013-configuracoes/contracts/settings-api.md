# Contrato: configurações (API usada, rotas e interface do módulo)

**Feature**: [../spec.md](../spec.md) · **Plan**: [../plan.md](../plan.md)

## 1. Endpoints (contrato da API 1.0.9, conferidos em 2026-10-14, R0)

| Método e caminho | Sucesso | Erros tratados |
|---|---|---|
| `GET /users/me` | 200 `{name, email, phone?, role, receiveNotifications, avatarUrl?}` → só `name`, `avatarUrl`, `receiveNotifications` | padrão (sem rede → cartão com o nome da sessão) |
| `PATCH /users/me` `{receiveNotifications: bool}` | 204 | padrão → a chave volta |
| `PATCH /users/me/change-password` `{currentPassword, newPassword}` | 204 | 401 `INVALID_CREDENTIALS` → `WrongCurrentPasswordFailure` (**não** encerra a sessão); 409 `USER_NEW_PASSWORD_EQUALS_OLD` → `SamePasswordFailure`; 400 `VALIDATION_ERROR` → genérica (evitado pela validação local). Depois do 204 o `refreshToken` é revogado → entrar de novo (linha abaixo) |
| `POST /auth/app/login` `{email, newPassword}` (logo depois da troca) | 200 `{accessToken, refreshToken}` → `UserSessionService.saveSession` | qualquer falha → `PasswordChangedReloginFailure`: sessão encerrada, login com "Senha alterada. Entre de novo com a nova senha." |

## 2. Rotas

| Caminho | Navegador | Tela | Dono |
|---|---|---|---|
| `/settings` | raiz (já existe) | `SettingsPage` (com conta) ou convite | settings |
| `/settings/security` | raiz (já existe) | `ChangePasswordPage` | settings |
| `/settings/accessibility` | raiz (já existe) | provisória até a B9 | settings |
| `/settings/privacy` | raiz (**nova**) | `PrivacyPage` | settings |
| `/settings/about` | raiz (**nova**) | `AboutPage` | settings |
| `/settings/account` | — | **removida** ("Dados pessoais" abre `/profile/edit`) | settings |

Saídas: cartão → `go('/profile')`; Dados pessoais → `push('/profile/edit')`; sair → o roteador
leva a `/login`; convite → `go('/login')`.

## 3. Interface do módulo `settings`

```dart
// domain/repositories/account_repository.dart
Future<Either<Failure, AccountSummaryEntity>> getAccount();
Future<Either<Failure, Unit>> setReceiveAlerts(bool value);
Future<Either<Failure, Unit>> changePassword({required String currentPassword, required String newPassword});
// troca e, em seguida, entra de novo com o e-mail da sessão e a nova senha (R0)

// domain/repositories/language_repository.dart
Future<LanguageChoice> getLanguage();        // ausente/ilegível → device
Future<void> saveLanguage(LanguageChoice choice);

// domain/usecases
GetAccountUseCase, SetReceiveAlertsUseCase,
ChangePasswordUseCase      // valida a política antes de chamar o repository
LogoutUseCase(session)     // UserSessionService.logout()
GetLanguageUseCase, SaveLanguageUseCase,
GetAppVersionUseCase(appInfo)
```

## 4. Fora do módulo

```dart
// common/validators/password_policy.dart (movido de authentication)
enum PasswordRule { length, uppercase, lowercase, digit, special }
abstract final class PasswordPolicy { static Set<PasswordRule> rulesMet(String p); static bool isValid(String p); }

// common/services/app_info_service.dart (novo, package_info_plus)
abstract class AppInfoService { Future<String> version(); }

// core/widgets/password_rules_list.dart (movido de authentication)

// shell: AppTopBar mostra a engrenagem só com sessionStatus == authenticated
// profile: ProfilePage idem
// notifications: AlertsNotices → push('/settings') e checkNew(force: true) na volta
```
