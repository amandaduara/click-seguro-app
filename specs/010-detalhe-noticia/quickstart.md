# Quickstart: validar o detalhe da notícia e as salvas

## Pré-requisitos

- Branch `010-detalhe-noticia`, emulador Pixel 4 (ou aparelho) com voz em português instalada.
- Servidor de desenvolvimento (`https://clickseguro-api.onrender.com/api/v1`); a primeira
  resposta pode levar ~40 s.
- Uma conta de teste (criar pelo próprio app; desativar no fim pelo endpoint
  `DELETE /users/me/deactivate`, como no [research.md](research.md) R0).

## Automático

```bash
cd click_seguro_app
flutter analyze     # nenhum aviso novo
flutter test        # suíte toda verde
```

## No emulador

```bash
cd click_seguro_app
flutter run -t lib/dev/accessibility_playground.dart   # tem o botão "Notícias salvas" (R8)
```

Prints e relatório em `specs/010-detalhe-noticia/evidencias/`.

| # | Passo | Esperado |
|---|---|---|
| 1 | Visitante: tocar numa notícia do feed | Detalhe com imagem, categorias, título, fonte, data, curtidas e texto (US1) |
| 2 | Notícia de "Golpes no WhatsApp" | Bloco de atividade relacionada; tocar abre `/activities/<id>` (US5) |
| 3 | Notícia só de "Segurança Bancária" | Sem bloco, sem espaço vazio |
| 4 | Tocar em "Ouvir", trocar velocidade, "Parar" | Lê título e texto em pt-BR; velocidade muda; para (US2) |
| 5 | Ligar leitura automática no painel e abrir outra notícia | Voz começa sozinha; voltar para a voz |
| 6 | App em inglês (idioma do aparelho) e "Ouvir" | Voz em inglês lê o texto em português (decisão de 2026-10-09) |
| 7 | Visitante toca no marcador | Convite para entrar; nenhum pedido (US3) |
| 8 | Com conta: salvar 2 notícias | Marcador alterna; aviso "Notícia salva" |
| 9 | Abrir "Notícias salvas" | As 2 notícias; **anotar a ordem** (pendência do R0) |
| 10 | Abrir uma salva, remover dos salvos, voltar | Some da lista |
| 11 | Modo avião: abrir "Notícias salvas" e a notícia salva já aberta | Cópia com aviso de offline (RNF-002) |
| 12 | Modo avião: abrir notícia nunca aberta | Erro com "Tentar novamente" |
| 13 | "Compartilhar" e "Abrir fonte" | Menu do aparelho com título, fonte e endereço; navegador abre a fonte (US4) |
| 14 | Sair da conta e entrar como visitante; abrir "Notícias salvas" | Convite; nenhuma cópia da conta anterior |
| 15 | Alto contraste e letra 150% no painel | Detalhe e lista legíveis, sem sobreposição; botões ≥ 48 dp |
| 16 | TalkBack no detalhe | Ordem: título, fonte, data, ações, texto, bloco; botões com estado |
