# Resposta ao review da PR #21 — 2026-10-21

Referência: review de `amandaduara` em 2026-10-21, sobre o commit `f1bcf939`.

## Decisão de escopo

Em 2026-10-22, Amanda Duara (dupla do TCC) aprovou a inclusão de IA na v1 (confirmado por ela
em 2026-10-27, na revisão da PR #21). A aprovação não é homologação dos endpoints.

- Item 1: decisão registrada com data e responsável; criados RF-043 a RF-045 e tarefa B10,
  removida a exclusão vigente de IA de §1.3/§8 e das notas globais.
- Item 3: endpoints continuam 🧪. A nova entrada 1.1.1 registra a aprovação; entradas antigas
  do changelog preservam o estado histórico. A entrada 1.0.0 mantém seu texto original.
- Item 4: módulo, rota e ação no cabeçalho compartilhado incluídos no escopo aprovado e
  registrados no mapa e no registro de módulos do plano global.

## Correções técnicas

| Item do review | Ajuste |
|---|---|
| 2 | AppTopBar mantém a Row com fonte padrão, inclusive em 320/360/412 dp; a quebra só ocorre com fonte ampliada. Testes exercitam dimensões de celular e 200%. |
| 5 | Removidas as quatro chaves sem uso dos AppStrings e dos dois JSONs. |
| 6 | Entities/model projetam somente os campos consumidos. Removidos cached, inputType/AiInputType e metadados de paginação sem uso; a spec distingue o contrato completo da projeção do cliente. |
| 7 | Uma extensão de apresentação mapeia ameaça para a chave exibida em resultado e histórico. |
| 8 | Um botão circular parametrizado atende Assistente e Configurações. O sino preserva o contador próprio. |
| 9 | Origens da API são constantes únicas no domínio; source segue string opcional no contrato. |
| 10 | Limites são constantes de domínio compartilhadas entre validação e interface. |
| 11 | Entrada do Assistente usa requireAccount. A página conserva o bloqueio de rede em deeplink visitante ou sessão expirada, com fallback reduzido que usa o mesmo convite padrão. |
| 12 | AppIdentity.name em core/constants é a fonte única do nome usado em Assistente e Sobre. |
| 13 | Modo, origem e entrada anterior pertencem ao controller, com retryAnalysis. Troca de modo limpa resultado/falha e impede reenvio de texto anterior no modo imagem. |
| 14 | Escolhida a alternativa mínima permitida no review: código INVALID_IMAGE_FORMAT único, compartilhado entre datasource e repository. A validação binária continua antes da chamada de rede. |
| 15 | Contexto pega os últimos turnos com skip, sem sucessivas cópias e reversões. |
| 16 | AiChatTurn é reutilizado para exibir a conversa; removido AssistantChatMessage. |
| 17 | Data do histórico usa formatação por locale. |
| 18 | Resultado usa SafeBadge. A correção de largura/fonte e cores já aprovada no SafeBadge da develop (PR #22) foi incorporada sem divergência, com os testes existentes. |
| 19 | Acrescentados widgets de erro/retry de chat e histórico e seleção/envio/limpeza de imagem; nomes de testes do controller em português. |

Também foi corrigida a perda de rascunho: a resposta de um envio anterior não pode apagar uma
mensagem nova digitada durante a espera. Os testes de regressão cobrem esse cenário e a troca de
modo após uma falha de análise.

## Validação

Em 2026-10-22, passaram 67 testes direcionados e 40 regressões de rotas, shell e Sobre.
A análise estática apresentou 27 infos fora da feature, nenhum erro ou warning. O APK foi
compilado e instalado no Pixel_4; cabeçalho padrão/ampliado e convite de conta foram conferidos.
Comandos e evidências estão em tasks.md e no relatório de teste.
A validação dos endpoints reais de IA continua pendente de sessão de teste válida.
A implementação/testes automatizados não realizam chamadas de IA reais.
