# Quickstart: validar as configurações

**Feature**: [spec.md](spec.md) · **Date**: 2026-10-14

Comandos a partir de `click_seguro_app/`. Endpoints, rotas e interface em
[contracts/settings-api.md](contracts/settings-api.md); estados em [data-model.md](data-model.md).

## 1. Automático

```bash
flutter analyze
flutter test test/modules/settings test/modules/authentication test/modules/common test/modules/shell test/modules/profile test/modules/notifications
flutter test
```

Esperado: análise sem avisos novos; testes de datasource, repository, usecases, política de senha,
controllers e páginas verdes; testes de login, cadastro e recuperação de senha (feature 003) verdes
sem mudança de comportamento; suíte inteira verde.

## 2. No aparelho

Acordar o servidor (`curl https://clickseguro-api.onrender.com/`, ~40 s) e rodar com
`--dart-define=API_URL=https://clickseguro-api.onrender.com/api/v1`. Usar uma conta própria.

| # | Passos | Esperado |
|---|--------|----------|
| 1 | Como visitante, olhar o topo do Início e do Perfil | Sem engrenagem |
| 2 | Entrar com a conta e tocar na engrenagem | Cartão com foto/iniciais, nome e "Ver e editar seu perfil"; seções Conta, Alertas, Leitura e aparência, Sobre; "Sair da conta" com a frase dos contatos |
| 3 | Tocar no cartão; voltar; tocar em "Dados pessoais" | Perfil; depois a edição de dados |
| 4 | Mudar o nome na edição e voltar | O cartão mostra o nome novo |
| 5 | Desligar "Alertas de notícias novas"; abrir os Alertas | Aviso de alertas desligados; o botão dele abre as Configurações |
| 6 | Ligar de novo e voltar aos Alertas | O aviso some |
| 7 | Modo avião e mudar a chave | A chave volta e aparece o aviso |
| 8 | "Alterar senha": nova senha fraca; confirmação diferente | Regras desmarcadas e erro na confirmação; nada enviado |
| 9 | Senha atual errada e nova válida | "Senha atual incorreta" no campo; continua conectada |
| 10 | Nova igual à atual | Aviso no campo da nova senha |
| 11 | Troca certa | "Senha alterada"; volta às Configurações; continua conectada; sair e entrar com a nova senha funciona |
| 12 | Digitar algo em "Alterar senha" e voltar | "Descartar alterações?" |
| 13 | Idioma → English | Tudo em inglês na hora; fechar e abrir continua em inglês; a leitura em voz alta de uma notícia sai em inglês |
| 14 | Idioma → Idioma do celular | Volta a seguir o celular (pt-BR); fechar e abrir continua seguindo o celular |
| 15 | "Privacidade" e "Sobre o SafeNews" | Textos claros; versão 1.0.0; "Trabalho de Conclusão de Curso" |
| 16 | "Acessibilidade" | Abre a tela de acessibilidade (conteúdo na B9) |
| 17 | "Sair da conta" | Vai ao login na hora; contatos de emergência e idioma continuam |
| 18 | Fonte do sistema no máximo, alto contraste e TalkBack | Linhas legíveis sem corte; chave anuncia "ligada/desligada"; alvos de 48 |
