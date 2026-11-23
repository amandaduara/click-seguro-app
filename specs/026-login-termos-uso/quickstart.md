# Quickstart: validar o login, o aceite e os Termos de uso

**Feature**: [spec.md](spec.md) · **Data**: 2026-11-23

## Pré-requisitos

- Branch `026-login-termos-uso`, dependências instaladas (`flutter pub get` em
  `click_seguro_app/`).
- Android real ou emulador; servidor de desenvolvimento acordado (pode levar ~40 s na primeira
  chamada).
- Referência visual: canvas https://claude.ai/artifact/Sninpo6jiADGa2r4YAgPRu (telas da
  versão A e "Termos de uso").

## Testes automáticos

```bash
cd click_seguro_app
flutter analyze
flutter test test/core/widgets/brand_scene_test.dart \
  test/core/routing/app_router_test.dart \
  test/modules/authentication \
  test/modules/settings \
  test/modules/splash
```

Esperado: tudo verde e o `analyze` sem avisos novos. A suíte completa (`flutter test`, ~30 min)
roda uma vez no polimento.

## Roteiro no aparelho

| # | Passo | Esperado | Spec |
|---|---|---|---|
| 1 | Configurações → "Termos de uso" (com conta e como visitante) | Linha logo abaixo de "Privacidade", com "O que vale ao usar o app"; tela com voltar + título, "Ouvir", "Última atualização: 23/11/2026" e os cinco cartões | US1, FR-001–004 |
| 2 | Nos Termos, tocar em "Ver Privacidade" e em "Ouvir" | Abre a Privacidade; o "Ouvir" lê título, data e cada assunto | FR-002, FR-003 |
| 3 | Sair da conta → aba "Criar conta" | Caixa de aceite desmarcada abaixo das regras; "Criar conta" desativado | FR-005, FR-009 |
| 4 | Preencher nome, e-mail e senha válidos; marcar a caixa pelo texto "Li e aceito os" | Caixa coral com visto, cartão coral claro; "Criar conta" ativo | FR-007, FR-008 |
| 5 | Tocar em "Termos de uso" e voltar; depois em "Política de privacidade" e voltar | Abrem as telas (sem pedir login); na volta, campos e caixa intactos | FR-006, SC-003 |
| 6 | Trocar para "Entrar" e voltar para "Criar conta" | Caixa continua marcada | Esclarecimento 2026-11-23 |
| 7 | Desmarcar a caixa | "Criar conta" volta a ficar desativado | US2 cenário 4 |
| 8 | Olhar o login inteiro | Marca centralizada, título, slogan, abas, campos, "Esqueci minha senha" à direita, "Entrar" com seta, "Continuar sem login" coral, onda no rodapé, sem divisor "ou" e sem o aviso do visitante | US3, FR-011–014 |
| 9 | Fonte "Muito grande" e alto contraste no login | Conteúdo rola e termina acima da onda; cores do alto contraste | US3 cenários 2–3 |
| 10 | Fechar o app sem sessão (onboarding já visto) e abrir | A splash termina e a marca sobe até o topo do login sem piscar; o formulário entra em sequência em ~1,3 s | US4, FR-016 |
| 11 | Repetir o passo 10 com "Reduzir animações" ligado | O login aparece direto | FR-017 |
| 12 | Abrir o app com sessão; e sair da conta | Splash → Início como hoje; sair → login com esmaecimento, sem a marca voar | FR-018 |
| 13 | App em inglês: passos 1, 3 e 8 | Todos os textos novos em inglês ("Last updated: 11/23/2026") | FR-019 |
| 14 | Criar uma conta de teste (só com a permissão da usuária) | Cadastro funciona como antes | FR-015 |
