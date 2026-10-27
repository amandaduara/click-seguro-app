# Tarefas — Assistente de IA

- [x] Conferir schemas e paths de IA no Swagger local.
- [x] Criar entities, falhas tipadas, repository de domínio e quatro usecases com limites de entrada.
- [x] Criar models de análise/histórico preservando null, enums desconhecidos e os campos de paginação consumidos pela UI.
- [x] Criar contrato e implementação de datasource para chat, análise de texto/imagem e histórico autenticados.
- [x] Validar assinatura e tamanho de imagem antes da rede; mapear erros HTTP/parse/IO no repository.
- [x] Escrever testes de domínio, datasource/multipart e mapeamento de falhas offline.
- [x] Registrar módulo, proteção de logs para `/app/ai/` e integrar tela com três áreas.
- [x] Escrever testes offline da apresentação para sessão visitante, envio explícito, histórico, estados e limpeza temporária.
- [x] Atualizar contrato da API e documentar privacidade, histórico sem diálogo e validação pendente.
- [x] Executar testes/análise/formatador e revisar screenshot na etapa central de integração.
- [ ] Validar endpoints de IA contra o servidor; aguardando login válido no emulador.

## Validação local (2026-10-20)

- 27 testes da feature validados em rodadas direcionadas; 118 regressões de API/logs,
  shell, rotas e smoke do app passaram na rodada integrada. As falhas encontradas na
  apresentação foram corrigidas e os cinco widget tests passaram na revisão final.
- `flutter analyze --no-pub --no-fatal-infos`: sem erros ou warnings; apenas 28 infos
  preexistentes fora da feature.
- `dart format` e `git diff --check` concluídos.
- Prévia Flutter em `previews/assistant.png`, renderizada com serviços simulados.
- Validação de interface inclui visitante sem chamadas, envio explícito, filtros,
  resultado nulo/desconhecido/erro e viewport de 320 px com texto em 200% e alto contraste.
- QA adicional: 56 testes direcionados passaram, incluindo corridas no histórico e
  envio duplicado. Corrigida invalidação do histórico após chat/análise concorrentes.
- Teste manual no Pixel_4 e limitações registrados em `evidencias/relatorio-de-teste.md`.

## Ajustes do review de 2026-10-21

Rastreabilidade dos 19 itens em [review-followup.md](review-followup.md).

- [x] Registrar decisão de inclusão de IA, com responsável/data, e então atualizar escopo/RFs globais (aprovação de Amanda Duara em 2026-10-22; RF-043 a RF-045, B10).
- [x] Validar todos os ajustes técnicos, regressões e análise estática na rodada integrada.
- [x] Revalidar cabeçalho em tela de celular e convite padrão no emulador.
- [ ] Homologar as operações reais de IA autenticadas; endpoints continuam 🧪.

## Validação dos ajustes (2026-10-22)

- `flutter test --no-pub test/modules/assistant test/modules/shell/presentation/app_top_bar_test.dart test/core/widgets/safe_badge_test.dart test/modules/common/api_client/redacting_log_interceptor_test.dart`: 67 testes passaram.
- `flutter test --no-pub test/core/routing/app_router_test.dart test/modules/shell/presentation/app_shell_test.dart test/modules/settings/presentation/privacy_and_about_pages_test.dart`: 40 regressões passaram.
- `flutter analyze --no-pub --no-fatal-infos`: 27 infos fora da feature, nenhum erro ou warning.
- `dart format`: 41 arquivos verificados, nenhuma alteração; `git diff --check` sem problemas.
- `flutter build apk --debug --no-pub`: APK compilado e instalado com preservação dos dados no Pixel_4.
- Cabeçalho conferido no emulador: ações ao lado do título com fonte padrão e segunda linha com fonte em 200%; convite padrão de conta ao tocar no Assistente como visitante. Evidências e limites no relatório de teste.
