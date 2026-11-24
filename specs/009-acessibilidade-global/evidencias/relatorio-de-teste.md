# Relatório de teste — Acessibilidade global (F0.6, feature 009)

| Item | Valor |
|---|---|
| Feature | `009-acessibilidade-global` (F0.6: RF-038 a RF-041, RNF-003/RNF-004) |
| Data | 2026-10-08 |
| Responsável | Arthur (execução assistida pelo Claude Code) |
| Aparelho | Emulador Android Pixel 4 (1080 × 2280, 440 dpi), imagem `sdk gphone16k x86_64` |
| Build | debug, `flutter run -t lib/dev/accessibility_playground.dart` (Flutter 3.47.6) |
| Servidor | desenvolvimento (Render), usado só para carregar o feed do Início |
| Código testado | branch `009-acessibilidade-global`, commit `c9648ca` |
| Demonstração | [00-demonstracao-emulador.jpg](00-demonstracao-emulador.jpg) (terminal e emulador durante o teste) |
| Resultado geral | ✅ **Aprovado.** 2 defeitos encontrados durante o teste, corrigidos e testados de novo |

## 1. Objetivo e escopo

Conferir, no aparelho, que as preferências de acessibilidade:

1. aumentam a letra de todo o app, somando com a escala do sistema e com teto de 2× (US1);
2. ficam guardadas e já valem no splash da próxima abertura (US2);
3. trocam o app inteiro para o tema de alto contraste (US3);
4. guardam a leitura automática e a velocidade da voz (US4).

**Fora do escopo:** a tela de Acessibilidade (tarefa B9). Como ela ainda não existe, as
preferências foram trocadas por um painel **só de desenvolvimento** (botão cinza na borda
esquerda dos prints), que chama o mesmo `AccessibilityController` que a B9 vai usar. O app normal
não tem esse botão.

## 2. Testes automatizados

| Verificação | Resultado |
|---|---|
| `flutter analyze` | ✅ 28 infos, todos antigos (linha de base: 28); 0 warnings, 0 erros |
| `flutter test` | ✅ **571 testes verdes** (linha de base: 518; +53 novos) |

Testes novos, por camada:

| Arquivo | O que cobre |
|---|---|
| `test/modules/common/accessibility/accessibility_preferences_test.dart` | níveis 100/115/130/150%, teto 2×, padrões, `copyWith`, igualdade, notifier |
| `test/modules/settings/data/accessibility_preferences_model_test.dart` | gravação/leitura; campo ausente, de tipo errado ou desconhecido cai no padrão só dele |
| `test/modules/settings/data/accessibility_repository_impl_test.dart` | chave `accessibility_preferences_v1`; falha de leitura → padrões; falha de gravação → `CacheFailure` |
| `test/modules/settings/domain/accessibility_usecases_test.dart` | usecases Get/Save |
| `test/modules/settings/presentation/accessibility_controller_test.dart` | `load`, efeito imediato, gravação, falha de gravação, mudanças seguidas (a última vence) |
| `test/modules/settings/settings_module_test.dart` | registro no GetIt, carga real do `shared_preferences`, **FR-010** (sair da conta e entrar como visitante não mudam as preferências) |
| `test/core/theme/app_palette_test.dart` | paleta normal = `AppColors`; **contraste AAA medido** (texto ≥ 7:1, bordas ≥ 3:1); temas |
| `test/accessibility_app_test.dart` | app real: tema e escala na hora, escala do sistema × nível, teto 2× |
| `test/core/widgets/safe_button_test.dart` | botão usa o vermelho-escuro no alto contraste |
| `test/modules/common/presentation/controller/read_aloud_controller_test.dart` | voz usa a velocidade guardada |
| `test/modules/shell/presentation/require_account_test.dart` | convite de conta no teto de 2× sem estourar (regressão do defeito D1) |

## 3. Casos de teste no emulador

| # | Caso (requisito) | Passos | Esperado | Obtido | Evidência |
|---|---|---|---|---|---|
| CT-01 | Primeira abertura (FR-008, SC-001) | Limpar os dados do app e abrir | Letra e cores normais | ✅ Conforme | [01](01-padrao-onboarding.jpg) |
| CT-02 | Letra maior na hora (US1, FR-002, FR-006) | No onboarding, escolher 150% | Texto cresce sem reiniciar | ✅ Conforme | [02](02-letra-150-onboarding.jpg) |
| CT-03 | Alto contraste na hora (US3, FR-005) | Ligar o alto contraste | Fundo branco, texto preto, vermelho-escuro, sem reiniciar | ✅ Conforme | [03](03-alto-contraste-onboarding.jpg) |
| CT-04 | Alto contraste no login (US3) | Pular o onboarding | Campos com contorno visível, botões em vermelho-escuro | ⚠️ → ✅ Contorno dos campos sem contraste (**D2**); corrigido | [04](04-alto-contraste-150-login.jpg) (depois) |
| CT-05 | Alto contraste no Início (US3) | Entrar como visitante e aguardar o feed | Feed, chips, cartões e barra inferior no tema | ✅ Conforme | [05](05-alto-contraste-150-inicio.jpg), [06](06-alto-contraste-150-cartoes.jpg) |
| CT-06 | Convite de conta (US3) | Tocar no sino como visitante | Convite no tema de alto contraste | ✅ Conforme | [07](07-alto-contraste-150-convite.jpg) |
| CT-07 | Voltar ao padrão (US1/US3) | 100% e alto contraste desligado | Tudo volta como antes, na hora | ✅ Conforme | [08](08-padrao-inicio.jpg) |
| CT-08 | Lembrar ao reabrir (US2, RF-041) | 130% + alto contraste + voz lenta → fechar o app (forçar parada) → abrir pelo ícone | Abre já com 130% e alto contraste | ✅ Conforme | [09](09-painel-130-alto-contraste-lenta.jpg), [10](10-reaberto-130-alto-contraste.jpg) |
| CT-09 | Splash já com as preferências (SC-001) | Reabrir e capturar 30 quadros seguidos | Nenhum quadro com o vermelho padrão (`#FE3152`) | ✅ O 1º quadro do Flutter já sai em `#9E0019` (alto contraste) | [11](11-reaberto-splash-alto-contraste.jpg) |
| CT-10 | Escala do sistema × app e teto (FR-003, FR-004) | Letra do Android em 200% + 150% no app | Letra cresce até 2× e não passa disso | ✅ Conforme (130% e 150% ficam iguais no teto) | [12](12-teto-2x-inicio.jpg), [13](13-teto-2x-cartoes.jpg) |
| CT-11 | Telas usáveis no teto (SC-004) | Passar pelas 5 abas | Nada cortado sem rolagem | ✅ Conforme | [14](14-teto-2x-abas.jpg) |
| CT-12 | Convite no teto (SC-004) | Tocar no sino no teto de 2× | Os dois botões alcançáveis | ❌ → ✅ Estourava 90 px e escondia "Agora não" (**D1**); corrigido | [15 antes](15-teto-2x-convite-ANTES-overflow.jpg), [16 depois](16-teto-2x-convite-DEPOIS.jpg) |
| CT-13 | Login e cadastro no teto (SC-004) | "Entrar ou criar conta" → alternar para "Criar conta" e rolar | Formulário completo acessível | ✅ Conforme | [17](17-teto-2x-login.jpg), [18](18-teto-2x-cadastro-rolado.jpg) |
| CT-14 | Lembrar as quatro preferências (US2, US4) | 150% + alto contraste + leitura automática + voz lenta → fechar e abrir pelo ícone | As quatro voltam iguais | ✅ Conforme | [19](19-reaberto-quatro-preferencias.jpg) |
| CT-15 | Sem erros de layout | `adb logcat` durante CT-10 a CT-13 | Nenhum `overflowed`/exceção do Flutter | ✅ Conforme após D1 | — |

## 4. Defeitos encontrados

| ID | Severidade | Descrição | Causa | Correção | Situação |
|---|---|---|---|---|---|
| D1 | Alta (bloqueia ação) | Com a letra no teto (2×), o convite "Entre na sua conta" estoura 90 px e o botão "Agora não" fica fora da tela | Folha com altura máxima de metade da tela e sem rolagem | `isScrollControlled: true` e conteúdo em `SingleChildScrollView`; teste com tela de Pixel 4 e escala 2× | ✅ Corrigido e conferido (CT-12) |
| D2 | Média (contraste) | No alto contraste, o contorno dos campos de texto continuava cinza-claro (abaixo de 3:1) | O contorno usava `input`, que é cor de preenchimento | Novo token `inputBorder` (igual a `input` no tema normal, preto no alto contraste) e teste de contraste | ✅ Corrigido e conferido (CT-04) |

Os dois ajustes estão no commit `c9648ca`.

## 5. Observações (sem defeito)

- **Botão "Entrar" desabilitado** (login vazio) fica rosado no alto contraste: é o estado
  desabilitado (40% de opacidade), que a WCAG dispensa da exigência de contraste.
- **Cabeçalho do Início no teto de 2×**: o título e a busca, que ficam fixos no topo, ocupam
  cerca de 40% da tela. O feed continua rolando normalmente. Vale avaliar na auditoria de
  acessibilidade (C3) se o cabeçalho deve rolar junto com letra grande.
- **Cartões de notícia no tema normal** têm um leve fundo cinza, que vem da sombra do próprio
  cartão. Já era assim antes desta feature (a migração das cores é 1:1). No alto contraste as
  sombras somem e o cartão fica branco.
- **Leitura automática**: aqui só é guardada e lida pelo app (CT-14 e testes). Ler sozinho ao
  abrir uma notícia ou pergunta é das tarefas A5 e B2.
- **Sair da conta (FR-010)**: a tela de sair é da B8. O comportamento foi coberto por teste
  automatizado (`settings_module_test.dart`), não no aparelho.

## 6. Conclusão

As quatro histórias da feature 009 funcionam no aparelho. A letra e o alto contraste valem em
todas as telas existentes e mudam na hora. As preferências voltam já no primeiro quadro do splash.
A escala total respeita o teto de 2×. Os dois defeitos achados no teste (D1 e D2) foram corrigidos,
ganharam testes automatizados e foram conferidos de novo no emulador. Pendente fora desta PR:
depois do merge da PR #12 (Reels), migrar as cores dos widgets dos Reels para o tema (T021).
