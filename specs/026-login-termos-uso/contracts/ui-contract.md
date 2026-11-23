# UI Contract: rotas, telas sem sessão e textos

**Feature**: [../spec.md](../spec.md) · **Data**: 2026-11-23

O app não expõe API. O contrato desta feature é o que outras partes do app (e os testes)
podem usar: rotas, quais telas abrem sem sessão e as chaves de texto.

## Rotas

| Rota | Tela | Transição | Muda? |
|---|---|---|---|
| `/login` | Login/cadastro (versão A) | esmaecimento (`appFadePage`) | visual |
| `/login?mode=register&next=…` | Login aberto em "Criar conta" | esmaecimento | visual |
| `/login?from=splash` | Login com a abertura (R1) | **sem transição** (o primeiro quadro é o último da splash) | **nova** |
| `/settings/terms` | Termos de uso | a padrão das Configurações | **nova** |
| `/settings/privacy` | Privacidade | a padrão | passa a abrir sem sessão |

`from=splash` só é usado pela splash (`SplashDestination.login`). Outros valores ou a ausência
do parâmetro: login sem abertura.

## Telas que abrem sem sessão (`_publicPaths`)

```text
/  ·  /onboarding  ·  /login  ·  /forgot-password  ·  /settings/terms (nova)  ·  /settings/privacy (nova)
```

Depois de "Sair da conta", qualquer outra rota volta ao login, como hoje.

## Chaves de texto

### Novas

| Chave | pt-BR | en-US |
|---|---|---|
| `auth_welcome_title` | Bem-vindo ao Click Seguro | Welcome to Click Seguro |
| `auth_terms_prefix` | Li e aceito os | I have read and accept the |
| `auth_terms_link` | Termos de uso | Terms of use |
| `auth_terms_and` | e a | and the |
| `auth_privacy_link` | Política de privacidade | Privacy policy |
| `settings_terms` | Termos de uso | Terms of use |
| `settings_terms_sub` | O que vale ao usar o app | What applies when using the app |
| `settings_terms_updated` | Última atualização: 23/11/2026 | Last updated: 11/23/2026 |
| `settings_terms_about_title` | O que é o Click Seguro | What Click Seguro is |
| `settings_terms_about_body` | O Click Seguro ajuda você a reconhecer golpes digitais com notícias e atividades. É gratuito e foi feito como Trabalho de Conclusão de Curso. | Click Seguro helps you recognize online scams through news and activities. It is free and was made as a final undergraduate project. |
| `settings_terms_limits_title` | O que o app não faz | What the app does not do |
| `settings_terms_limits_body` | O app ensina a desconfiar, mas não garante que uma mensagem ou ligação é segura. Ele não substitui o seu banco, a polícia nem um profissional. Caiu em um golpe? Ligue para o seu banco e registre um boletim de ocorrência. | The app teaches you to be suspicious, but it cannot guarantee that a message or call is safe. It does not replace your bank, the police or a professional. Fell for a scam? Call your bank and file a police report. |
| `settings_terms_account_title` | Sua conta | Your account |
| `settings_terms_account_body` | Use um e-mail seu e guarde a senha só para você. Não passe a senha para ninguém, nem para quem diz ser do Click Seguro: nós nunca pedimos. | Use your own email and keep your password to yourself. Never give it to anyone, not even someone who says they are from Click Seguro: we never ask for it. |
| `settings_terms_use_title` | Bom uso do app | Using the app well |
| `settings_terms_use_body` | Use o Click Seguro para aprender e se proteger. Não tente copiar, mudar ou atrapalhar o funcionamento do serviço. | Use Click Seguro to learn and protect yourself. Do not try to copy, change or disrupt the service. |
| `settings_terms_data_title` | Seus dados | Your data |
| `settings_terms_data_body` | O que guardamos, onde e para quê está explicado na tela Privacidade. | What we store, where and why is explained on the Privacy screen. |
| `settings_terms_see_privacy` | Ver Privacidade | See Privacy |

O texto completo do aceite é `auth_terms_prefix` + `auth_terms_link` + `auth_terms_and` +
`auth_privacy_link` + ".". Em inglês fica: "I have read and accept the Terms of use and the
Privacy policy."

### Reaproveitadas

`splash_tagline` (slogan no cabeçalho do login), `auth_mode_login`, `auth_mode_register`,
`auth_continue_as_guest`, `auth_forgot_password`, `settings_privacy`.

### Removidas (ficam sem uso)

`auth_or`, `auth_guest_note`, `auth_welcome`, `auth_brand`.
