# Relatório de teste — Alertas locais (A6, feature 011)

| Item | Valor |
|---|---|
| Data | 2026-10-09 (a bateria terminou depois da meia-noite UTC; fuso do aparelho America/Sao_Paulo, 23:30 a 23:42) |
| Aparelho | Emulador Android Pixel 4 (1080 × 2280, 440 dpi), TalkBack instalado |
| Build | debug, `flutter run -t lib/dev/accessibility_playground.dart` (painel de acessibilidade e os quatro botões de desenvolvimento aparecem nos prints; o "Notícias salvas" e o "Alertas: voltar verificação 7 dias" cobrem parte do sino e do resumo). O `flutter run` caiu no primeiro "fechar e abrir" (`force-stop`); o app foi reaberto pelo ícone (`monkey`), em modo debug, e a bateria seguiu assim |
| Servidor | desenvolvimento (`https://clickseguro-api.onrender.com/api/v1`) |
| Conta de teste | `teste-a6v-20261009232834@example.com` (senha de teste descartável), criada por `POST /auth/app/register` e **desativada no fim** (`DELETE /users/me/deactivate` → 204; depois disso `/users/me` → 403 e login → 401) |
| Resultado geral | **Conforme, com ressalvas**: passo 14 só em parte (não existe saída da conta na interface) e "99+" não alcançável (o app guarda no máximo 50). Nenhum defeito do app encontrado |

## Como foi feito

- Interação por `adb shell input tap/swipe`, prints por `adb exec-out screencap` (reduzidos a 540 × 1140) e árvore de acessibilidade por `uiautomator dump` (conferência de rótulos, ordem e posição).
- "Fechar e abrir o app" = `am force-stop` + abrir pelo ícone. Modo avião por `cmd connectivity airplane-mode`. Letra do sistema por `settings put system font_scale`. Inglês por `cmd locale set-app-locales … --locales en-US` (idioma do app).
- Alertas provocados pelos botões do painel de desenvolvimento ("voltar verificação 7 dias", "apagar", "Abrir Alertas"); notícias reais do serviço de desenvolvimento (12 publicadas em 2026-10-08).
- `receiveNotifications` trocada com `PATCH /users/me` (204).
- Tempo do SC-001 por polling de pixel (cor do círculo do contador) a cada captura de tela (~0,3 s), contado do comando de abrir o app.
- Para ver os três grupos (a data real das 12 notícias, 07/10 no fuso do aparelho, só gera "Anteriores") e o limite de 50, o registro `flutter.notifications_alerts_v1` do app foi editado com `run-as` (só `publishedAt` dos 6 primeiros e, à parte, 120 alertas de mentira), sempre com o app fechado e depois restaurado. Isso é dado de teste; a lógica exibida é a do app.

## Resultado por passo

| # | Esperado | Obtido | Evidência |
|---|---|---|---|
| 1 | Visitante toca no sino: convite, sino sem número, nenhum pedido | ✅ Convite "Entre na sua conta" com "Entrar ou criar conta" e "Agora não"; sino sem número. "Nenhum pedido ao serviço": o app não registra as chamadas de rede e não há proxy no emulador, então não foi medido no aparelho; a regra segue coberta pelos testes (SC-004) | [01](01-visitante-sino-convite.jpg) |
| 2 | Visitante abre `/notifications` | ✅ "Entre na sua conta" + "Entrar ou criar conta" (botão grande) dentro da tela | [02](02-visitante-tela-alertas.jpg) |
| 3 | Conta de teste, 1ª abertura: sino sem número, sem alertas | ✅ Sino sem número; registro guardado com `lastCheckAt` = agora e `alerts: []` (SC-003) | [03](03-conta-primeira-abertura.jpg) |
| 4 | "Voltar 7 dias" + reabrir: sino com o nº de notícias dos últimos 7 dias | ✅ Sino "Alertas, 12 novos"; o `GET /app/news?startDate=` de 7 dias devolve 12 (todas publicadas em 2026-10-08). SC-001: ver nota 1 | [04](04-sino-com-12-alertas.jpg) |
| 5 | Reabrir logo em seguida: mesmo número, sem repetição | ✅ Continua 12, 12 `newsId` distintos guardados (SC-002) | [05](05-reabrir-mesmo-numero.jpg) |
| 6 | Tela "Alertas": resumo, botão fixo, grupos, "Novo" | ✅ "Você tem 12 alertas novos", "Marcar todos como lidos" fixo (resumo e botão não rolam), "Novo" em cada alerta. Grupos: "Anteriores" (data real, `07/10`) e, com `publishedAt` ajustado, "Hoje" (hora) e "Ontem" (hora) na ordem Hoje, Ontem, Anteriores | [06](06-tela-alertas-12-novos.jpg), [06b](06b-tela-alertas-rolada.jpg), [06c](06c-grupos-hoje-ontem-anteriores.jpg), [06d](06d-grupos-ontem.jpg), [06e](06e-grupos-anteriores.jpg) |
| 7 | Tocar num alerta: abre a notícia; voltar: sem "Novo", sino N−1 | ✅ Abre o detalhe da notícia; voltar → alerta sem "Novo", resumo "11 novos", sino "Alertas, 11 novos". SC-007 conforme: Início → sino → alerta = 2 toques | [07](07-alerta-abre-noticia.jpg), [07b](07b-voltar-alerta-lido.jpg), [07c](07c-sino-11.jpg) |
| 8 | "Marcar todos como lidos" | ✅ Todos sem "Novo", "Você não tem alertas novos", botão some, sino sem número | [08](08-marcar-todos-lidos.jpg), [08b](08b-sino-sem-numero.jpg) |
| 9 | Fechar e abrir: tudo continua | ✅ Alertas e marcações iguais, sino sem número | [09](09-reabrir-persiste.jpg), [09b](09b-sino-sem-numero-apos-reabrir.jpg) |
| 10 | Modo avião: alertas e número guardados; faixa "sem internet" fixa; sem erro nas outras telas | ✅ Sino "Alertas, 11 novos" no Início; tela com os 11 alertas e a faixa "Você está sem internet. Mostrando o conteúdo salvo." que não rola com a lista. Nenhuma mensagem de erro dos alertas no Início (a faixa de "conteúdo salvo" do feed é a mesma da feature 007) (SC-006, SC-009) | [10](10-offline-inicio-sino-guardado.jpg), [10b](10b-offline-tela-alertas.jpg), [10c](10c-offline-faixa-fixa.jpg) |
| 11 | Modo avião: alerta de notícia nunca aberta | ✅ Detalhe com "Sem conexão com a internet. Verifique sua rede." e "Tentar novamente". Observação: o alerta já ficou lido ao tocar (sino 11 → 10) mesmo com o detalhe em erro | [11](11-offline-noticia-nunca-aberta-erro.jpg) |
| 12 | "Receber alertas" desligado + 7 dias + reabrir: nenhum alerta; faixa e "Ligar em Editar perfil" | ✅ Com `PATCH receiveNotifications:false` e registro apagado antes, nada entrou (`alerts: []`, `receiveAlerts:false`); "Os alertas novos estão desligados." com o botão "Ligar em Editar perfil", que abre `/profile/edit` (placeholder "Editar dados — Em breve") (SC-005) | [12](12-desligado-faixa.jpg), [12b](12b-ligar-abre-editar-perfil.jpg) |
| 13 | Religar e abrir a tela: aviso some; só notícias novas | ✅ Com `receiveNotifications:true` o aviso some; nenhuma das 12 notícias antigas voltou (a última verificação foi avançada enquanto estava desligado); lista vazia porque não saiu notícia depois | [13](13-religado-aviso-some.jpg) |
| 14 | Sair da conta e entrar com outra/visitante: nenhum alerta anterior | ⚠️ **Parcial.** Não há saída da conta na interface (B7/B8). Cobertura possível: com o registro de outro e-mail (`owner` diferente) e 12 alertas gravados, o app **não** mostrou nenhum e substituiu o registro pelo da conta atual (FR-019, isolamento por dono). A limpeza ao sair segue coberta pelos testes automáticos | [14](14-outra-conta-sem-alertas-anteriores.jpg) |
| 15 | Alto contraste + letra 150%: legível, sem sobreposição, botões ≥ 48 dp | ✅ Com 130%: topo fixo (resumo e botão não rolam). Com 150% + alto contraste: resumo e botão entram na lista e rolam junto (uma rolagem só); contador "11", "Novo", resumo e botão legíveis, contornos fortes. Alvos: sino 132 px = 48 dp; botão "Marcar todos" 150 px ≈ 54 dp; alertas > 150 px | [15a](15a-letra-130-inicio-sino.jpg), [15b](15b-letra-130-alertas.jpg), [15c](15c-letra-150-alto-contraste-topo.jpg), [15d](15d-letra-150-alto-contraste-rolada.jpg), [15e](15e-letra-150-alto-contraste-inicio-sino.jpg) |
| 16 | Letra do sistema 2×: botão quebra, nada cortado | ✅ Com `font_scale 2.0` a tela fica numa lista só; títulos e rodapé de cada alerta quebram em mais linhas; nada cortado. O texto do botão ("Marcar todos como lidos") coube em uma linha; a quebra do botão fica coberta pelo teste de 2× (T045). Nos prints, as sobreposições vêm dos botões de desenvolvimento, que também crescem | [16a](16a-sistema-2x-inicio.jpg), [16b](16b-sistema-2x-alertas.jpg) |
| 17 | TalkBack no sino e na tela | ✅ Com o TalkBack ligado, a árvore (`uiautomator dump`) tem: sino "Alertas, 11 novos"; na tela, na ordem: "Voltar", "Alertas", "Você tem 11 alertas novos", "Marcar todos como lidos", "Hoje", alertas e "Ontem"; cada alerta "Novo, título, fonte, hora" (o lido sem "Novo"). O foco verde do TalkBack aparece e navega por deslize. Não foi gravada a fala (sem log de fala no `logcat`) | [17a](17a-talkback-inicio-sino.jpg), [17b](17b-talkback-tela-alertas.jpg), [17c](17c-talkback-foco-alerta.jpg) |
| 18 | Idioma em inglês | ✅ "Alerts", "You have 11 new alerts", "Mark all as read", "Today", "Yesterday", "Earlier", "New", "Back", sino "Alerts, 11 new"; títulos das notícias continuam em português | [18](18-ingles-alertas.jpg) |

## Notas

1. **SC-001 (número do sino em até 5 s depois de o app abrir)**. Tempo do comando de abrir o app até o círculo do contador aparecer, com o serviço acordado e registro apagado + voltar 7 dias antes de cada medida: **3,45 s, 3,12 s, 2,93 s** (inclui ~1 s de partida do app). Conforme.
2. **Contador "99+"**. Não alcançável pelo app: ao carregar, o registro é cortado em 50 (teto de 50 alertas guardados, igual ao `limit=50`). Com 120 alertas gravados à mão o sino mostrou **"50"** e a tela "Você tem 50 alertas novos". O "99+" continua coberto só pelo teste de widget. [04b](04b-sino-teto-50.jpg).
3. **Pendências do R0 (para anotar no quickstart)**. O `startDate` usa `publishedAt` (T002/contrato 1.0.7). Diferença entre o relógio do aparelho e o do serviço: 0 s (o emulador usa o relógio do host; `Date` do serviço e `date -u` iguais em 2 s de precisão). Em aparelho real com relógio errado a conferência usa o horário do aparelho (`lastCheckAt`), como a spec assume.
4. O painel de dev e os quatro botões aparecem nos prints porque o teste usou a entrada de desenvolvimento (R10). Eles cobrem parte do contador e do resumo ("Você tem 11 alertas novos" aparece com texto sobreposto só por causa deles).
5. Horário: a bateria passou de 23:30 a 23:42, perto da meia-noite do aparelho. Os alertas "Hoje" foram gravados com 20 min de diferença e a conferência dos grupos ficou antes da virada.
6. Só uma conta de teste foi criada (desativada no fim); nenhum teste usou o servidor de produção.
