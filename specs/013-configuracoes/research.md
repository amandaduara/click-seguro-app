# Research: Configurações

**Feature**: [spec.md](spec.md) · **Plan**: [plan.md](plan.md) · **Date**: 2026-10-14

As decisões de produto estão na seção Clarifications da spec. As decisões abaixo saem do código das
features 001, 002, 003, 005, 007, 009, 011 e 012, do contrato da API 1.0.8 e do
`easy_localization` 3.0.8.

## R0. Conferência no servidor real (portão de API)

Feita em 2026-10-14 com a conta de teste nova `teste.claude.20261014@exemplo.com` (autorizada pela
usuária; senhas aleatórias, não guardadas).

| Pedido | Resultado |
|---|---|
| `PATCH /users/me/change-password` com a senha atual errada | ✅ 401 `INVALID_CREDENTIALS`; o `GET /users/me` seguinte dá 200 (sessão intacta) |
| Nova senha igual à atual | ✅ 409 `USER_NEW_PASSWORD_EQUALS_OLD` |
| Nova senha fraca | ✅ 400 `VALIDATION_ERROR` |
| Troca certa | ✅ 204; o `accessToken` antigo continua valendo |
| `POST /auth/app/refresh` com o `refreshToken` antigo, depois da troca | ⚠️ **401 `TOKEN_INVALID`**: a renovação é revogada |
| Login com a senha antiga / nova | 401 / 200 |
| `PATCH /users/me {receiveNotifications: false}` | ✅ 204; o `GET` seguinte traz `false` |

**Decision**: sem nada a fazer, a pessoa seria derrubada com "sessão expirada" quando o
`accessToken` vencesse. Por isso, **depois do 204 o repository entra de novo** (`POST
/auth/app/login` com o e-mail da sessão e a nova senha) e guarda o par novo na sessão
(`UserSessionService.saveSession`, mantendo e-mail e nome). A pessoa continua conectada (FR-013).
Se esse login falhar, a troca já valeu: a sessão é encerrada (`logout`) e a tela de login mostra
"Senha alterada. Entre de novo com a nova senha." Contrato da API → **1.0.9**.

**Alternatives considered**: deixar a sessão expirar sozinha (a pessoa veria "sessão expirada"
minutos depois, sem entender); mandar sempre ao login (a spec pede continuar conectada); importar o
login do `authentication` (Princípio I: o `settings` chama `/auth/app/login` no próprio datasource,
sem guardar a senha).

## R1. Dados da conta nas Configurações

**Decision**: o módulo `settings` ganha um datasource remoto próprio (`AccountRemoteDataSource`) com
`GET /users/me` (nome, foto, `receiveNotifications`), `PATCH /users/me {receiveNotifications}` e
`PATCH /users/me/change-password`. Não importa `profile`, `authentication` nem `notifications`.

**Rationale**: Princípio I (sem importar outro módulo), como os alertas (011) e o perfil (012)
fizeram com `/users/me`. Os três pedidos são da tela de configurações.

**Alternatives considered**: usar os usecases do `profile` (importaria outro módulo); levar o
perfil para `common` (mexe em duas features fechadas sem ganho para o usuário).

## R2. Sair da conta

**Decision**: `LogoutUseCase` chama `UserSessionService.logout()` (feature 001), sem confirmação
(clarificação). O redirecionamento do roteador (feature 005) já leva ao login quando a saída é pedida
pela pessoa. Nada além da sessão é apagado (RN-007): contatos, fotos, idioma e acessibilidade
ficam no aparelho, e os alertas locais são limpos pelo próprio `NotificationsController` ao ver a
sessão encerrada (feature 011), como já acontece.

**Rationale**: o serviço de sessão é do `common` e já é usado por usecases (B7). Um usecase mantém a
regra "controller só fala com usecase".

## R3. Troca de senha

**Decision**:
- A regra da nova senha (RN-001) é a mesma do cadastro e da recuperação (feature 003). Para não
  copiá-la (Princípio II) nem importar o `authentication` (Princípio I), **a política de senha vai
  para o `common`**: `PasswordRule` e `PasswordPolicy.rulesMet(password)` saem de
  `authentication/domain` para `common/validators/password_policy.dart`, e o `PasswordRulesList`
  sai de `authentication/presentation/widgets` para `core/widgets/password_rules_list.dart` (já é
  só visual). O `CredentialsValidator` passa a usar o `PasswordPolicy`, sem mudar o comportamento;
  os testes da 003 continuam iguais (só os imports mudam).
- `ChangePasswordController`: três campos com "mostrar senha", regras marcadas ao digitar,
  confirmação igual, `canSave`, `isSaving`, `save()` com resultado `saved | invalid | failed`.
- Falhas: 401 `INVALID_CREDENTIALS` → `WrongCurrentPasswordFailure` (erro no campo; a sessão
  **não** expira, garantido pelo `ApiClient` da F0.13); 409 `USER_NEW_PASSWORD_EQUALS_OLD` →
  `SamePasswordFailure` (erro no campo da nova); demais → mensagem genérica, campos mantidos.
- O corpo do pedido não vai para o log: `/users/me/change-password` já está nas rotas sensíveis do
  `ApiClient` (F0.2).
- Sair com algo digitado: `PopScope` + "Descartar alterações?" (mesmo diálogo da B7).

**Alternatives considered**: copiar as regras e a lista (duplicação, Princípio II); importar o
`authentication` (Princípio I).

## R4. Chave "Alertas de notícias novas"

**Decision**: o `SettingsController` lê `receiveNotifications` junto com o cartão da conta. Tocar na
chave muda na hora (otimista), envia o `PATCH` e volta ao valor anterior em falha, com `SnackBar`.
Toques durante o envio são ignorados. Se a conta não carregou, a chave fica desabilitada com
"Não foi possível carregar" e "Tentar novamente".

O aviso "alertas desligados" da tela de Alertas (feature 011) passa a abrir `/settings` (era
`/profile/edit`, que não tem mais a chave) e, ao voltar, a tela de Alertas confere de novo
(`checkNew(force: true)`), para o aviso sumir na hora.

## R5. Idioma

**Decision**:
- Escolha `LanguageChoice { device, portuguese, english }`, guardada no aparelho pelo
  `LocalCacheService` (chave `language_choice`), num `LanguageRepository` local do `settings`.
  Ausente = `device`.
- Aplicar a escolha precisa do `BuildContext` do `easy_localization`, então fica na apresentação:
  `portuguese`/`english` → `context.setLocale(...)` (o pacote também guarda a escolha e a usa na
  próxima abertura); `device` → `context.setLocale(<idioma do aparelho suportado>)` seguido de
  `context.deleteSaveLocale()`, para a próxima abertura seguir o aparelho de novo.
- Mudança do idioma do celular com o app aberto vale na próxima abertura (o `easy_localization`
  lê o idioma do aparelho ao iniciar).
- A leitura em voz alta já segue `context.locale` (feature 007), sem mudança.
- A escolha aparece numa folha por baixo (mesmo padrão da folha de foto da B7), com as três opções
  em linhas de 56 e a atual marcada.

**Rationale**: o `easy_localization` guarda o idioma escolhido, mas não informa durante o uso se a
escolha atual é "seguir o aparelho" (o `savedLocale` só é lido ao iniciar). Guardar a escolha à
parte deixa a linha mostrar "Idioma do celular" com certeza.

**Alternatives considered**: ler a chave `locale` do `SharedPreferences` do pacote (acopla a um
detalhe interno); só duas opções (rejeitada na clarificação).

## R6. Visitante e engrenagem

**Decision**: a engrenagem só aparece com conta:
- `ProfilePage` (feature 012): o `_Header` esconde a engrenagem para o visitante.
- `AppTopBar` (feature 005, `shell`): o botão de configurações só aparece com
  `sessionStatus == authenticated`.
- `/settings` aberto sem conta (link direto ou sessão expirada com a tela aberta) mostra um convite
  simples (`SafeEmptyState` + "Entrar ou criar conta" → `/login`), sem pedido ao serviço. O
  `settings` não importa o convite do `profile` (Princípio I).

## R7. Versão do app

**Decision**: adicionar `package_info_plus` e um `AppInfoService` no `common/services`
(contrato + implementação + fake), que devolve a versão (`1.0.0`). A tela "Sobre" e a linha
"Sobre o SafeNews" leem a versão por um `GetAppVersionUseCase`.

**Rationale**: é a forma padrão do Flutter de ler a versão instalada; uma constante no código
ficaria diferente do `pubspec.yaml` a cada versão. Pacote mantido pela equipe do Flutter
Community, sem permissões novas.

**Alternatives considered**: constante em `EnvironmentConfig` (esquecida a cada versão);
`--dart-define` no build (exige lembrar em cada build).

## R8. Rotas

| Rota | Tela | Antes |
|---|---|---|
| `/settings` | `SettingsPage` | provisória |
| `/settings/security` | `ChangePasswordPage` | provisória |
| `/settings/accessibility` | provisória (B9) | igual |
| `/settings/privacy` | `PrivacyPage` | nova |
| `/settings/about` | `AboutPage` | nova |
| `/settings/account` | removida | provisória; "Dados pessoais" vai a `/profile/edit` |

O cartão da conta faz `context.go('/profile')`; "Dados pessoais", `context.push('/profile/edit')`.
Ao voltar da edição, as Configurações recarregam o cartão (nome e foto podem ter mudado).

## R9. Testes

Datasource com `FakeHttpClientAdapter` (caminhos, corpos, 401/409); repository (falhas por código);
usecases (logout, troca de senha valida antes, idioma); `PasswordPolicy` (movido, mesmos casos);
controllers (carga, falha da conta, chave otimista e volta, troca de senha com cada falha);
páginas (linhas e destinos, visitante por link direto, sair, idioma nas três opções com
`pumpLocalized`, "Sobre" com a versão do fake, fonte 2×, alvos de 48); `AppTopBar` e `ProfilePage`
sem engrenagem para o visitante; tela de Alertas abrindo `/settings`.
