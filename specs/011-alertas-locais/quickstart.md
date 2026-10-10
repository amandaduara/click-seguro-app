# Quickstart: validar os alertas locais

## Pré-requisitos

- Branch `011-alertas-locais`, emulador Pixel 4 (ou aparelho) com voz e internet.
- Servidor de desenvolvimento (`https://clickseguro-api.onrender.com/api/v1`); a primeira
  resposta pode levar ~40 s. **Não usar o servidor de produção.**
- Uma conta de teste criada pelo próprio app (desativar no fim com
  `DELETE /users/me/deactivate`, como na [feature 010](../010-detalhe-noticia/research.md) R0) e,
  para o passo "desligado", o `PATCH /users/me {"receiveNotifications": false}` dessa conta
  (a chave só ganha tela na B7).
- O serviço de desenvolvimento já tem notícias; como a **primeira conferência não gera alertas**
  (FR-003), os alertas do emulador vêm do botão de desenvolvimento "Alertas: voltar verificação
  7 dias" ([research.md](research.md) R10).

## Automático

```bash
cd click_seguro_app
flutter analyze     # nenhum aviso novo
flutter test        # suíte toda verde
```

## No emulador

```bash
cd click_seguro_app
flutter run -t lib/dev/accessibility_playground.dart   # tem os três botões de alertas (R10)
```

Prints e relatório em `specs/011-alertas-locais/evidencias/`.

| # | Passo | Esperado |
|---|---|---|
| 1 | Entrar como visitante e tocar no sino (Início) | Convite para entrar ou criar conta; sino sem número; nenhum pedido ao serviço (US4) |
| 2 | Visitante abre `/notifications` (botão "Abrir Alertas" do painel de desenvolvimento) | Convite dentro da tela, botão grande "Entrar ou criar conta" |
| 3 | Entrar com a conta de teste; abrir o app pela primeira vez | Sino sem número e sem alertas (primeira conferência só marca o horário) (US1) |
| 4 | Painel de desenvolvimento: "Alertas: voltar verificação 7 dias"; reabrir o app (fechar e abrir) | Sino com número igual às notícias publicadas nos últimos 7 dias (até 50) (US1) |
| 5 | Fechar e abrir o app de novo logo em seguida | Mesmo número; nenhum alerta repetido (SC-002) |
| 6 | Tocar no sino | Tela "Alertas": resumo "Você tem N alertas novos", botão "Marcar todos como lidos" fixo, grupos Hoje/Ontem/Anteriores, "Novo" escrito em cada alerta (US2) |
| 7 | Tocar num alerta | Abre a notícia (detalhe); voltar → alerta sem "Novo" e sino com N−1 |
| 8 | Tocar em "Marcar todos como lidos" | Todos sem "Novo"; resumo "Você não tem alertas novos"; botão some; sino sem número (US3) |
| 9 | Fechar e abrir o app | Alertas e marcações continuam (FR-018) |
| 10 | Modo avião: abrir o app e a tela de Alertas | Alertas e número guardados continuam; faixa "sem internet" fixa na tela; nenhuma mensagem de erro nas outras telas (SC-006, SC-009) |
| 11 | Modo avião: tocar num alerta de notícia nunca aberta | Detalhe com erro e "Tentar novamente" (feature 010) |
| 12 | Desligar "Receber alertas" da conta de teste (PATCH); voltar o horário 7 dias; reabrir o app | Nenhum alerta novo; tela mostra "Os alertas novos estão desligados." e "Ligar em Editar perfil", que abre `/profile/edit` (US4, SC-005) |
| 13 | Religar a chave (PATCH) e abrir a tela de Alertas | Aviso some; só notícias publicadas depois entram (FR-006) |
| 14 | Sair da conta e entrar com outra (ou como visitante); abrir os Alertas | Nenhum alerta da conta anterior (FR-019). Se a saída pela interface ainda não existir (B8), registrar e cobrir pelo teste automático, como na 010 |
| 15 | Alto contraste e letra em 150% (painel de acessibilidade) | Contador, "Novo", resumo e botão legíveis, sem sobreposição; botões ≥ 48 dp (SC-008) |
| 16 | Letra do sistema em 2× | Texto do botão quebra em mais linhas; nada cortado |
| 17 | TalkBack na tela e no sino | Sino: "Alertas, N novos"; tela: título, resumo, botão, grupos e alertas na ordem; cada alerta anuncia "Novo", título, fonte e hora |
| 18 | Idioma do aparelho em inglês | Textos fixos em inglês ("Alerts", "New", "Mark all as read"); títulos das notícias seguem em português |

Pendências do [R0](research.md) para anotar neste guia ao validar: qual data o `startDate` usa e a
diferença entre o relógio do aparelho e o do serviço.
