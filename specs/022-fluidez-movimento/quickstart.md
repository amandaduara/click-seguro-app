# Quickstart: validar a feature 022

## Pré-requisitos

- Flutter 3.47+ e Android Studio atual (o JDK dele é usado pelo Flutter).
- Emulador Android, por exemplo `fuja_api36` (Android 16).

## Rodar

```sh
cd click_seguro_app
flutter pub get
flutter emulators --launch fuja_api36
flutter run -d emulator-5554            # debug, com hot reload
flutter run -d emulator-5554 --profile  # medir fluidez (DevTools → Performance)
```

Se o `flutter run` falhar com "incompatibility between Java and Gradle", o toolchain da Fase 0
não foi aplicado (ver research R14).

Se a instalação terminar mas o app não abrir ("Activity class does not exist"), espere alguns
segundos ou reinicie o emulador. É um estado transitório do gerenciador de pacotes do Android 16
logo depois de `adb install`.

## Testes automatizados

```sh
flutter analyze
flutter test
```

## Roteiro manual (no emulador)

| # | Passo | Esperado | Spec |
|---|---|---|---|
| 1 | Abrir o app | Logo entra suave; Início chega com esmaecimento; texto em Montserrat | FR-001, FR-018 |
| 2 | Puxar o feed para atualizar | Cartões continuam na tela; um só indicador | FR-002 |
| 3 | Trocar de categoria rápido 3× | Lista esmaece e troca uma vez, sem sumir | FR-002, edge |
| 4 | Abrir notícia pelo feed | Título e imagem na hora; Hero da imagem | FR-017 |
| 5 | Voltar | Cartão com selo "lida" | FR-005 |
| 6 | Sair e entrar com outra conta | Feed recarrega sem marcas antigas | FR-004 |
| 7 | Tocar nas abas | Fade-through; rolagem preservada | FR-016 |
| 8 | Tocar o topo do círculo central | Abre Reels | FR-006 |
| 9 | Tocar um Reel no carrossel | Imagem já visível ao chegar | FR-019 |
| 10 | Deslizar Reels; curtir; dois toques | Sem tela preta; coração pulsa; vibra | FR-021, FR-030 |
| 11 | Responder pergunta certa e errada | Destaque + vibração distinta; próxima entra de lado | FR-022, FR-027 |
| 12 | Login: alternar Entrar/Criar conta | Campos entram/saem suave | FR-023 |
| 13 | Gesto de voltar numa tela empilhada | Prévia da tela anterior | FR-015 |
| 14 | Acessibilidade → Reduzir animações; repetir 1–13 | Nada desliza, aumenta ou brilha | FR-010 |
| 15 | Servidor frio (primeira abertura do dia) | Esqueletos + aviso de lentidão após 5 s | FR-011, FR-014 |
| 16 | TalkBack nos botões e cartões | Anunciados como botão | FR-007 |

## Achados (2026-11-08, emulador `fuja_api36`, build debug, inglês)

Coberto nesta passada:

- Passos 1, 15: feed abre com esqueletos e o aviso de lentidão, agora com margem lateral (T062).
- Passo 8: o círculo central abre os Reels.
- Passo 10: dois toques na imagem, como visitante, abrem o convite de conta (sem curtir).
- Passo 12: login sem o retângulo de outro tom dentro dos campos (T060), ícones Lucide; "Criar
  conta" mostra nome e regras.
- Achado e corrigido: o chip "All" (rótulo curto) saía como círculo; agora tem largura mínima de
  80 (T061).

## Achados (2026-11-09, emulador `fuja_api36`, build profile, inglês)

Resto do roteiro, já com T063–T066:

- Passo 2: puxar para atualizar mantém os cartões e mostra um só indicador.
- Passo 3: três trocas rápidas de categoria: a lista antiga esmaece com a barra de progresso, sem
  vazio e sem sumir (T066), e fica a última escolha.
- Passos 4 e 5: título, fonte e data na hora; ao voltar, selo "lida". **Achado (T068)**: vindo de
  um cartão compacto, a imagem do detalhe mostrava o ícone até carregar (o cartão decodifica em
  80 px e o detalhe na largura da tela: outra chave de cache). Corrigido: a miniatura do cartão,
  ampliada, cobre a espera; o Hero voa com ela.
- Passo 6: conta nova ("Teste 022 c") sem a marca de lida da anterior. Observação: o filtro de
  categoria escolhido continua o mesmo depois da troca de conta.
- Passo 7: fade-through entre abas; a rolagem do feed volta onde estava.
- Passo 9: **achado (T069)**: o esqueleto dos Reels ainda mostrava o ícone, porque o
  pré-carregamento só começava no toque e a imagem em tela cheia não chegava a tempo. Corrigido:
  o cartão do carrossel pré-carrega ao aparecer; agora a imagem está lá desde o primeiro quadro.
- Passo 11: errada ("Not this time") e certa ("You got it right!") distintas; a imagem da próxima
  pergunta já está pronta (T064). Observação (feature 017, fora do escopo): a bolinha de progresso
  de uma pergunta respondida errada também ganha o check verde ("respondida", não "certa").
- Passo 13: o gesto de voltar encolhe a tela com cantos arredondados e volta para Atividades
  (Android 16 com SDK 36 liga a volta preditiva sem `enableOnBackInvokedCallback`).
- Passo 14 (Reduzir animações): troca de aba e de categoria imediatas; Reels com o esqueleto
  parado e a imagem do item tocado. **Achado (T068)**: o Hero da imagem ainda voava ao abrir e ao
  voltar; corrigido (sem Hero com movimento reduzido). Em aberto: os indicadores de carregamento
  (barra e círculo) continuam animados; tratados como essenciais (comunicam estado, WCAG 2.3.3), a
  confirmar.
- Letra em 200% (escala do sistema): Início, detalhe, Reels (título e texto com reticências e "Read
  full story") e lição cabem, com rolagem; os ícones do topo descem para baixo do título. O rótulo
  "Activities" da barra inferior encolhe para caber.
- Alto contraste: bordas escuras nos cartões, vermelho mais forte, esqueleto visível no detalhe.
- Passo 16: a árvore de acessibilidade expõe cartões, filtros, abas e botões do topo como
  `Button` com rótulo completo. O TalkBack não reconhece os deslizes injetados pelo `adb`, então
  os anúncios em voz não foram ouvidos.

Perfil (T059, `--profile`, mesmo roteiro do T067, 3 rodadas): feed com raster p50 2,2–2,3 ms, p90
2,7–2,9 ms e nenhum quadro acima de 16,7 ms; Reels conforme a tabela abaixo (com desfoque).

T067 (2026-11-09, `--profile` no emulador fuja_api36): Reels já carregados, roteiro fixo de 8
passadas para cima e 8 para baixo, 3 rodadas de 20 s (~1050 quadros cada) por variante.

| Variante | raster p50 | raster p90 | quadros > 16,7 ms |
| --- | --- | --- | --- |
| Com desfoque (barra e botões) | 3,7–4,0 ms | 4,8–5,4 ms | 0, 0, 1 |
| Sem desfoque | 1,7–1,8 ms | 2,1–2,2 ms | 0, 0, 1 |

O desfoque custa ~2 ms por quadro e fica muito abaixo do orçamento de 16,7 ms: mantido. Os 14 ms
anteriores vieram de uma passada sem aquecimento (e as repetições logo depois deram 9,4 e 5,3
ms): a hipótese é a primeira exibição das imagens (não medida à parte), não o desfoque.

T056: as durações literais que sobraram não são de transição de interface (tempo-limite de rede,
espera da busca, contagem do reenvio, tempo mínimo da splash, atraso do aviso de lentidão) ou são o
período do brilho do esqueleto, que já fica parado com o movimento reduzido.
