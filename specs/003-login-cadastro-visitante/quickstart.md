# Quickstart: validar a feature 003

**Feature**: [spec.md](spec.md) · **Contratos**: [contracts/authentication.md](contracts/authentication.md)
· **Modelo**: [data-model.md](data-model.md)

## 1. Testes automatizados

```bash
cd click_seguro_app
flutter analyze
flutter test
```

Esperado: nenhum erro ou warning novo; todos os testes verdes. Cobertura mínima por camada:

| Onde | O que provar |
|---|---|
| `test/modules/authentication/domain/` | regras do RN-001 (cada `PasswordRule`, nome 6–150, regex de e-mail, código ≥ 6); cada usecase barra entrada inválida **sem** chamar o repository (SC-004) |
| `test/modules/authentication/data/` | models (incluindo `role` desconhecido); datasource (caminhos, corpos, `authToken` no `getMe`); repository (sucesso salva a sessão; senha errada, papel ≠ USER, e-mail duplicado, conta criada sem login, código inválido, sem rede) |
| `test/modules/authentication/presentation/controller/` | alternância de modo preserva o necessário e limpa erros; envio duplicado ignorado; visitante; passos da recuperação; contagem do reenvio com relógio falso |
| `test/modules/authentication/presentation/pages/` | `LoginPage`: entra e vai a `/home`; erro de senha mostrado; campos inválidos marcados; olho alterna. `ForgotPasswordPage`: três passos, código inválido, volta ao login com o e-mail |
| `test/modules/common/api_client/api_client_test.dart` | `get(authToken:)`: header correto, sem renovação nem expiração |

## 2. No aparelho, contra a API real

```bash
flutter run -d <aparelho> --dart-define=API_URL=https://<host>/api/v1 --dart-define=DEBUG_MODE=true
```

1. Passe pelo onboarding (ou ele já foi visto) e chegue à tela de login.
2. **Criar conta** com um e-mail novo e uma senha forte → cai no Início provisório com "Olá, {nome}".
3. Feche e reabra o app. Ele volta ao login, porque a decisão da tela inicial é da A1, mas a
   sessão está salva.
4. **Entrar** com a mesma conta → Início. Com a senha errada → "E-mail ou senha incorretos.".
5. **Criar conta** com o mesmo e-mail → "Este e-mail já está cadastrado." e o atalho "Entrar".
6. **Esqueci minha senha** → e-mail → código recebido → nova senha → volta ao login com o
   e-mail preenchido → entra com a senha nova.
7. **Continuar sem login** com o modo avião ligado → Início como visitante ("Bem-vindo").
8. Com `DEBUG_MODE=true`, confira no log que senha e tokens não aparecem.
9. Se tudo funcionar, troque 🧪 por ✅ nas linhas de autenticação do
   [api-contract](../../.specify/memory/api-contract.md).
