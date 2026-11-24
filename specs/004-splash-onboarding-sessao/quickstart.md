# Quickstart: validar o splash com sessão e o onboarding

**Feature**: [spec.md](spec.md) · **Date**: 2026-10-04

Comandos a partir de `click_seguro_app/`.

## 1. Automático

```bash
flutter analyze
flutter test test/modules/splash test/modules/onboarding
flutter test
```

Esperado: análise sem avisos, as 8 linhas da
[tabela de decisão](data-model.md#tabela-de-decisão-completa-base-dos-testes-do-fr-013) cobertas,
os testes do onboarding verdes e a suíte inteira verde.

## 2. No aparelho

Pré-requisito: o servidor de desenvolvimento acordado (abra a URL da API no navegador e espere
cerca de 40 s) e a conta de teste. Rode pelo VS Code (o `launch.json` já passa `API_URL`).

| # | Passos | Esperado |
|---|--------|----------|
| 1 | Desinstalar o app, instalar e abrir | Splash com "Sua segurança em primeiro lugar", depois o onboarding |
| 2 | Ir até o fim e tocar em "Começar" | Login |
| 3 | Fechar por completo e reabrir | Splash → login (o onboarding não volta) |
| 4 | Entrar com a conta de teste, fechar e reabrir | Splash → área principal, cumprimentando pelo nome |
| 5 | Ligar o modo avião, fechar e reabrir | Splash (até ~3 s) → área principal, ainda conectado |
| 6 | Sair da conta (ou usar uma conta desativada), fechar e reabrir | Splash → login |
| 7 | No login, "Continuar sem login", fechar e reabrir | Splash (~2 s) → área principal, como visitante |
| 8 | Em qualquer destino, tocar em "voltar" do aparelho | O app fecha; o splash não reaparece |
| 9 | Reinstalar e, no 1º slide, tocar em "Pular" | Login; reabrir não mostra o onboarding |
