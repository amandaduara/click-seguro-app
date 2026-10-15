# Data Model: Configurações

**Feature**: [spec.md](spec.md) · **Plan**: [plan.md](plan.md) · **Date**: 2026-10-14

## Entidades (domain, módulo `settings`)

| Entidade | Campos | Regras |
|---|---|---|
| `AccountSummaryEntity` | `name`, `avatarUrl?`, `receiveNotifications` | de `GET /users/me`; `initials` = primeira e última palavra do nome |
| `LanguageChoice` (enum) | `device`, `portuguese`, `english` | ausente no aparelho = `device` |
| `ChangePasswordInput` | `currentPassword`, `newPassword` | nunca guardado; espaços contam (sem `trim`) |

## Política de senha (movida para `common`, R3)

`PasswordRule { length, uppercase, lowercase, digit, special }` e
`PasswordPolicy.rulesMet(String) → Set<PasswordRule>` (8–64 caracteres, `[A-Z]`, `[a-z]`, `[0-9]`,
`[^A-Za-z0-9]`). `PasswordPolicy.isValid(String)` = todas as regras.

## Falhas (`settings/domain/failures/settings_failures.dart`)

| Falha | Quando | Mensagem (chave) |
|---|---|---|
| `WrongCurrentPasswordFailure` | 401 `INVALID_CREDENTIALS` na troca | `settings_password_error_current` (no campo) |
| `SamePasswordFailure` | 409 `USER_NEW_PASSWORD_EQUALS_OLD` | `settings_password_error_same` (no campo) |
| `WeakPasswordFailure` | nova senha fora do RN-001 chegando ao usecase (proteção; o controller valida antes) | `settings_password_error_rules` |
| `PasswordChangedReloginFailure` | senha trocada, mas o login automático com a nova falhou (R0) | `settings_password_relogin` ("Senha alterada. Entre de novo com a nova senha."), mostrado no login depois de encerrar a sessão |
| `ConnectionFailure`, `ServerFailure`, `UnauthorizedFailure` | padrão | genérica da tela |

## Controllers

**`SettingsController`** (um por abertura da tela):

| Getter | Tipo | Significado |
|---|---|---|
| `account` | `AccountState` (`loading / loaded / failed`, próprio do `settings`: o `AreaState` é do `profile`) | cartão e chave |
| `fallbackName` | `String?` | nome da sessão, para o cartão sem rede |
| `isSavingAlerts` | bool | chave bloqueada durante o envio |
| `language` | `LanguageChoice` | escolha guardada |
| `appVersion` | `String?` | versão instalada |

Métodos: `load()`, `retryAccount()`, `setReceiveAlerts(bool) → Failure?` (otimista, volta em falha),
`setLanguage(LanguageChoice)` (só guarda; a página aplica no `easy_localization`), `logout()`.

**`ChangePasswordController`**:

| Campo | Regra |
|---|---|
| `current`, `newPassword`, `confirmation` (texto) | erros por campo: `required`, `rulesNotMet`, `mismatch`, `wrongCurrent`, `samePassword` |
| `rulesMet` | `Set<PasswordRule>` da nova, recalculado ao digitar |
| `canSave` | os três preenchidos e não está salvando |
| `isSaving`, `hasInput` | `hasInput` = algum campo com texto (diálogo de descarte) |

Método: `save() → ChangePasswordResult { saved, invalid, failed }` (+ `saveFailure`).

## Mudanças em outros módulos

- `common`: `PasswordRule`/`PasswordPolicy` (de `authentication`), `AppInfoService` (novo).
- `core/widgets`: `PasswordRulesList` (de `authentication`).
- `authentication`: passa a importar a política e a lista de `common`/`core` (sem mudar o
  comportamento).
- `shell`: `AppTopBar` esconde a engrenagem para quem não tem conta.
- `profile`: `ProfilePage` esconde a engrenagem para o visitante.
- `notifications`: `AlertsNotices` abre `/settings` e a tela confere de novo ao voltar; o texto
  `notifications_disabled_action` passa de "Ligar em Editar perfil" para "Ligar nas Configurações"
  ("Turn on in Settings").

## Chaves de i18n (novas, prefixo `settings_`; inglês equivalente)

| Chave | pt-BR |
|---|---|
| `settings_account_card_action` | Ver e editar seu perfil |
| `settings_section_account` / `_alerts` / `_reading` / `_about` | Conta / Alertas / Leitura e aparência / Sobre |
| `settings_personal_data` / `_sub` | Dados pessoais / Nome, e-mail, telefone e foto |
| `settings_change_password` / `_sub` | Alterar senha / Troque a senha de entrada no app |
| `settings_alerts` / `_sub` | Alertas de notícias novas / Avisamos quando sair uma notícia de golpe |
| `settings_alerts_failed` | Não foi possível mudar os alertas. Tente de novo. |
| `settings_account_load_failed` | Não foi possível carregar |
| `settings_accessibility` / `_sub` | Acessibilidade / Tamanho da letra, contraste e leitura em voz alta |
| `settings_language` | Idioma |
| `settings_language_device` / `_portuguese` / `_english` | Idioma do celular / Português / English |
| `settings_privacy` / `_sub` | Privacidade / Como cuidamos dos seus dados |
| `settings_about_app` / `settings_version` | Sobre o SafeNews / Versão {} |
| `settings_logout` / `settings_logout_note` | Sair da conta / Ao sair, seus contatos de emergência continuam guardados neste celular. |
| `settings_guest_title` / `_body` / `_action` | Entre na sua conta / As configurações são da sua conta. / Entrar ou criar conta |
| `settings_password_current` / `_new` / `_confirm` | Senha atual / Nova senha / Confirmar nova senha |
| `settings_password_show` / `_hide` | Mostrar senha / Esconder senha |
| `settings_password_save` / `_saved` / `_failed` | Salvar / Senha alterada / Não foi possível trocar a senha. Tente de novo mais tarde. |
| `settings_password_error_required` / `_rules` / `_mismatch` / `_current` / `_same` | Preencha este campo. / A senha não cumpre todas as regras. / As senhas não são iguais. / Senha atual incorreta / A nova senha precisa ser diferente da atual. |
| `settings_password_discard_title` / `_body` / `_confirm` / `_cancel` | Descartar alterações? / O que você digitou não será salvo. / Descartar / Continuar editando |
| `settings_privacy_*` | parágrafos da tela de Privacidade (conta no serviço; contatos e fotos só no celular; preferências no aparelho) |
| `settings_about_*` | objetivo do app e "Trabalho de Conclusão de Curso" |

As regras da senha reutilizam as chaves `auth_rule_*` existentes. `settings_title` e
`settings_accessibility_title` já existem.
