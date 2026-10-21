# Tarefas — Assistente de IA

- [x] Conferir schemas e paths de IA no Swagger local.
- [x] Criar entities, falhas tipadas, repository de domínio e quatro usecases com limites de entrada.
- [x] Criar models de análise/histórico preservando null, enums desconhecidos e paginação real.
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
