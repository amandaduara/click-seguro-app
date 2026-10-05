# Quickstart: validar o shell de navegação e a base das trilhas

**Feature**: [spec.md](spec.md) · **Date**: 2026-10-04

Comandos a partir de `click_seguro_app/`.

## 1. Automático

```bash
flutter analyze
flutter test test/modules/shell test/core test/widget_test.dart
flutter test
```

Esperado: análise sem avisos novos; teste de fumaça subindo o app como visitante e passando pelas
cinco abas; convite, aviso de sessão expirada, saída, rotas e estados comuns verdes.

## 2. Style guide

```bash
flutter run -t lib/style_guide/style_guide.dart -d chrome
```

Esperado: seção "Estados" com carregando, erro (com "Tentar novamente"), vazio e sem internet.

## 3. No aparelho

| # | Passos | Esperado |
|---|--------|----------|
| 1 | Abrir com sessão (ou entrar) | Aba Início com "Olá, {nome}" e a barra inferior com 5 abas, "Início" destacada |
| 2 | "Continuar sem login" no login | Início com "Bem-vindo" |
| 3 | Tocar em Atividades, Ajuda e Perfil | Cada tela provisória com o seu título; Perfil sem barra superior |
| 4 | Tocar no botão central | Tela provisória dos Reels, barra inferior visível, sem barra superior, botão central com anel |
| 5 | Como visitante, tocar no sino | Convite "Entre na sua conta"; "Agora não" fecha e mantém a tela |
| 6 | Repetir e tocar "Entrar ou criar conta" | Login |
| 7 | Conectado, tocar no sino | Tela provisória de Alertas, sem a barra inferior; voltar → aba |
| 8 | Tocar na engrenagem | Configurações por cima; voltar → aba |
| 9 | Em Ajuda, "voltar" do aparelho | Vai para Início; em Início, "voltar" fecha o app |
| 10 | Fonte do sistema no máximo | Barras e textos sem cortes nem sobreposição |
