# Quickstart: validar o feed da aba Início

**Feature**: [spec.md](spec.md) · **Date**: 2026-10-05

## 1. Automático

```bash
cd click_seguro_app
flutter analyze
flutter test test/modules/news
flutter test
```

Esperado: datasource, repository (incluindo a cópia guardada e a deduplicação), usecases,
controller (paginação, filtro, busca com espera, respostas antigas descartadas), extensions e
widgets verdes; suíte inteira verde.

## 2. No aparelho

Acorde o servidor antes (`curl https://clickseguro-api.onrender.com/`, ~40 s). O servidor de
desenvolvimento tem poucas notícias: paginação longa e várias categorias só aparecem nos testes
automatizados.

| # | Passos | Esperado |
|---|--------|----------|
| 1 | Abrir como visitante | Carregando → "Bem-vindo!", busca, filtros, Novidades (Reels) e Tudo recente |
| 2 | Conferir um cartão | Imagem, título, fonte, data ("Há N dias" ou "12 de set.") e categorias |
| 3 | Tocar num cartão | Detalhe provisório por cima das abas; voltar → mesma posição |
| 4 | Tocar num cartão das Novidades | Aba Notícias (Reels) selecionada |
| 5 | Tocar numa categoria | Só notícias dela, ou "Nenhuma notícia nesta categoria ainda." |
| 6 | Buscar "teste" e depois "xyzxyz" | Resultados; depois o estado vazio com o texto; "X" volta ao feed |
| 7 | Puxar a lista para baixo | Recarrega |
| 8 | Fechar, modo avião, abrir | Feed guardado com a faixa de sem internet |
| 9 | Modo avião sem nunca ter carregado (dados do app apagados) | Erro de conexão com "Tentar novamente" |
| 10 | Entrar com a conta de teste | "Olá, {nome}!"; recomendações só se o servidor mandar |
| 11 | Fonte do sistema no máximo | Cartões crescem sem cortar além das linhas do título |
