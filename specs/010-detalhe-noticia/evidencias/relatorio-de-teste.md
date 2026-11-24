# Relatório de teste — Detalhe da notícia e notícias salvas (A5, feature 010)

| Item | Valor |
|---|---|
| Data | 2026-10-09 |
| Aparelho | Emulador Android Pixel 4 (1080 × 2280, 440 dpi), Google TTS em pt-BR e en-US, Chrome e TalkBack instalados |
| Build | debug, `flutter run -t lib/dev/accessibility_playground.dart` (painel de acessibilidade e botão "Notícias salvas" são só de desenvolvimento, o "Notícias salvas" cobre o canto superior direito nos prints) |
| Servidor | desenvolvimento (`https://clickseguro-api.onrender.com/api/v1`) |
| Conta de teste | `teste-a5-20261009183350@example.com` (senha de teste descartável), **desativada no fim** (`DELETE /users/me/deactivate` → 204; depois disso `/users/me` → 403 `USER_INACTIVE` e login → 401) |
| Resultado geral | **Conforme, com duas ressalvas**: SC-001 só no limite (ver passo 1) e passo 14 só em parte (não existe saída da conta na interface) |

Nenhum defeito do app foi encontrado.

## Resultado por passo

| # | Esperado | Obtido | Evidência |
|---|---|---|---|
| 1 | Visitante: detalhe com imagem, categorias, título, fonte, data, curtidas e texto | ✅ Conforme. SC-001: ver nota 1 | [01](01-visitante-detalhe.jpg) |
| 2 | Notícia de "Golpes no WhatsApp": bloco de atividade; toque abre `/activities/<id>` | ✅ Conforme (também em "Golpes Digitais"). A rota abre o placeholder "Atividade — Em breve" (tela da trilha C ainda não existe) | [02](02-bloco-atividade-golpes-digitais.jpg), [03](03-bloco-atividade-whatsapp.jpg), [04](04-bloco-abre-atividade.jpg) |
| 3 | Notícia só de "Segurança Bancária": sem bloco e sem espaço vazio | ✅ Conforme ("Banco não pede senha…" e "Verificação em duas etapas…", ambas sem módulo) | [05](05-sem-bloco-seguranca-bancaria.jpg) |
| 4 | "Ouvir", trocar velocidade, "Parar" | ✅ "Ouvir" vira "Parar" (voz Google pt-BR no log), velocidade "rápida" aplicada, "Parar" volta a "Ouvir" | [06](06-ouvir-lendo.jpg), [07](07-velocidade-rapida.jpg), [08](08-parar.jpg) |
| 5 | Leitura automática ligada: voz começa sozinha; voltar para a voz | ✅ Voz começou sem tocar; ao voltar, o log mostra `Utterance ID has been stopped … Interrupted: true` (SC-004). SC-003: ver nota 2 | [09](09-leitura-automatica.jpg) |
| 6 | App em inglês: voz em inglês lê o texto em português | ✅ Textos fixos em inglês ("News", "Stop", "Speed", "Save", "Share"); o log mostra `Synthesis request for locale eng-USA` | [10](10-app-em-ingles-ouvir.jpg) |
| 7 | Visitante toca no marcador: convite, nenhum pedido | ✅ Convite "Entre na sua conta" com "Entrar ou criar conta" e "Agora não"; nada mudou na tela | [11](11-visitante-marcador-convite.jpg) |
| 8 | Conta: salvar 2 notícias; marcador alterna; aviso "Notícia salva" | ✅ Cadastro pelo app, 3 notícias salvas; botão vira "Salvo" e o aviso "Notícia salva" aparece (depois do servidor responder) | [12](12-conta-nova-noticia-salva.jpg) |
| 9 | "Notícias salvas": **anotar a ordem** | ✅ Ordem observada: **da salva mais recente para a mais antiga**. Salvas na sequência PIX → WhatsApp → e-mail falso; a lista mostrou e-mail falso, WhatsApp, PIX. Não é a ordem de `publishedAt` (seria PIX, e-mail falso, WhatsApp). Com 2 notícias, o `GET` direto confirmou a mesma regra | [13](13-lista-tres-salvas-ordem.jpg) |
| 10 | Remover dos salvos e voltar: some da lista | ✅ Aviso "Removida dos salvos"; ao voltar, a lista tem 2 itens | [14](14-removida-dos-salvos.jpg), [15](15-lista-apos-remover.jpg) |
| 11 | Modo avião: lista e notícia salva já aberta com aviso de offline | ✅ Lista com "Você está sem internet. Mostrando o conteúdo salvo." e detalhe com a cópia e o mesmo aviso. Tocar "Salvar" sem rede mostra "Sem conexão com a internet." sem mudar o estado | [16](16-offline-lista.jpg), [17](17-offline-detalhe-salvo.jpg) |
| 12 | Modo avião: notícia nunca aberta: erro com "Tentar novamente" | ✅ Erro "Sem conexão…" com "Tentar novamente"; com a rede de volta, o botão carregou a notícia | [18](18-offline-nunca-aberta-erro.jpg), [19](19-tentar-novamente-ok.jpg) |
| 13 | "Compartilhar" e "Abrir fonte" | ✅ Menu do aparelho com título, fonte e endereço (`CERT.br https://www.cert.br/`); "Abrir fonte" abriu o Chrome em cert.br e o voltar retornou ao app | [20](20-compartilhar.jpg), [21](21-abrir-fonte-navegador.jpg) |
| 14 | Sair da conta e entrar como visitante; "Notícias salvas": convite, sem cópia anterior | ⚠️ **Parcial.** O convite do visitante em "Notícias salvas" está conforme ([22](22-visitante-salvas-convite.jpg)), mas **não há como sair da conta pela interface** (Perfil e Configurações ainda são "Em breve"; `UserSessionService.logout()` não tem botão). Para chegar ao visitante limpei os dados do app (`pm clear`), o que apaga a cópia à força e não prova a limpeza ao sair (FR-018). Essa limpeza segue coberta só pelos testes automáticos | [22](22-visitante-salvas-convite.jpg) |
| 15 | Alto contraste e letra 150%: detalhe e lista legíveis, sem sobreposição, botões ≥ 48 dp | ✅ Lista (cartões com 2 e 3 linhas de título, sem sobreposição), detalhe, ações, texto e bloco legíveis, contornos fortes e vermelho-escuro. Botões e chips medem ≥ 48 dp já no tamanho normal (≈ 48 a 54 dp) e crescem com a letra | [23](23-alto-contraste-150-lista.jpg), [24](24-alto-contraste-150-detalhe.jpg), [25](25-alto-contraste-150-acoes-texto.jpg), [26](26-alto-contraste-150-bloco.jpg) |
| 16 | TalkBack no detalhe: ordem e estados | ✅ Com o TalkBack ligado, a árvore de acessibilidade (`uiautomator dump`) sai nesta ordem: Voltar, "Notícia", categorias (chips), "título, fonte, data" (um item só), "0 curtidas", "Ouvir", "Velocidade: normal", lenta / normal (selecionado) / rápida, "Salvo" (selecionado), "Compartilhar", "Abrir fonte", texto da notícia, bloco "Pratique o que aprendeu, Golpes Digitais, …, 3 perguntas". A imagem não é lida. Observação: as categorias vêm antes do título (como na tela); o quickstart não as cita | [27](27-talkback-ligado-detalhe.jpg) |

## Notas

1. **SC-001 (notícia completa em até 3 s)**. Medido por polling de pixel no aparelho (`adb shell`) do toque até a imagem e as categorias aparecerem. Com o app em uso: 1,93 s, 1,97 s, 1,95 s. Primeira abertura depois de uns 45 s parado: 3,09 s e 5,1 s; primeira da série, 4,4 s. O `curl` ao servidor leva ~1,0 s, então a diferença é de conexão fria (nova conexão TLS/Render). Dentro de 3 s no uso normal, fora do limite na primeira abertura depois de uma pausa. Fica para o orquestrador decidir se isso conta como "serviço acordado".
2. **SC-003 (voz em até 1 s depois de a notícia aparecer)**. Com a leitura automática ligada, o log `TTS: Utterance ID has started` caiu no mesmo quadro em que a notícia apareceu (diferença de ~0,003 s nas 3 aberturas medidas). Conforme. Numa abertura após ~45 s parado não foi capturada a linha do log.
3. Conta desativada (extra, fora do quickstart): com a conta desativada, "Notícias salvas" mostra o erro genérico "Não foi possível completar a ação" com "Tentar novamente" (o servidor devolve 403 `USER_INACTIVE`, não 401, então a sessão não é encerrada e a cópia não é usada). [28](28-conta-desativada-403.jpg).
4. O painel de dev e o botão "Notícias salvas" aparecem nos prints porque o teste usou a entrada de desenvolvimento (R8).
