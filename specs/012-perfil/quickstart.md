# Quickstart: validar o perfil

**Feature**: [spec.md](spec.md) · **Date**: 2026-10-12

Comandos a partir de `click_seguro_app/`. Endpoints, rotas e interface em
[contracts/profile-api.md](contracts/profile-api.md); estados em [data-model.md](data-model.md).

## 1. Automático

```bash
flutter analyze
flutter test test/modules/profile test/modules/news test/modules/shell test/modules/common
flutter test
```

Esperado: análise sem avisos novos; testes de models, datasource, repository, conquistas,
validador, controllers e páginas verdes; testes da lista de salvas (feature 010) verdes sem
mudança de comportamento; suíte inteira verde.

## 2. No aparelho

Acordar o servidor (`curl https://clickseguro-api.onrender.com/`, ~40 s) e rodar com
`--dart-define=API_URL=https://clickseguro-api.onrender.com/api/v1`. Usar uma conta própria (as
contas de teste não têm senha guardada). O servidor tem 3 módulos de atividades.

| # | Passos | Esperado |
|---|--------|----------|
| 1 | Como visitante, abrir a aba Perfil | Convite "Entre na sua conta" e a lista do que se ganha |
| 2 | Entrar com a conta e abrir a aba Perfil | Foto (ou iniciais) e nome, sem e-mail; Lidas/Salvas/Curtidas; "Conquistas (N)"; dois cartões coloridos |
| 3 | Deslizar as medalhas; tocar em "Ver todas" | Alcançadas primeiro (coloridas, "Conquistada"), depois as com progresso; a lista completa abre na mesma ordem |
| 4 | Abrir uma notícia, voltar à aba Perfil | "Lidas" aumentou; "Leitor atento" conquistada |
| 5 | Tocar em "Lidas", depois numa notícia | Lista "Notícias lidas"; o detalhe abre; voltar mantém a lista |
| 6 | Tocar em "Curtidas" sem nenhuma curtida | Mensagem de vazio e botão para o Início |
| 7 | Tocar em "Salvas" | Lista de salvas da feature 010 |
| 8 | Tocar no lápis da foto, trocar o nome, "Salvar" | "Dados salvos"; perfil e saudação do Início com o nome novo |
| 9 | Nome com 3 letras; telefone "1234"; apagar um telefone já salvo | Erro em cada campo; "Salvar" não envia |
| 10 | Trocar o e-mail e salvar | (com o bug do servidor) "Não foi possível salvar. Tente de novo mais tarde.", e o texto continua |
| 11 | Mudar algo e tocar em voltar | "Descartar alterações?" |
| 12 | Tocar na foto → "Galeria" → escolher | Foto nova com "Enviando foto…", depois salva; aparece no perfil |
| 13 | Tocar na foto → "Remover foto" → confirmar | Iniciais de novo |
| 14 | Modo avião, voltar à aba Perfil e "Tentar novamente" | Erro e recuperação ao voltar a rede |
| 15 | Fonte do sistema no máximo e alto contraste | Tudo legível; os três números podem quebrar linha sem cortar |
| 16 | TalkBack | Lápis "Editar perfil", "12 notícias lidas, abrir lista", medalhas e cartões com rótulo |
