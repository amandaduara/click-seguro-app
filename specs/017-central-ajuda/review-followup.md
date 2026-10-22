# Revisão B6 — PR20

Branch histórica `015-central-ajuda` preservada para o PR20. A documentação da feature usa `017-central-ajuda`, próximo número livre porque `016` está ocupado pelo Assistente.

| # | Item revisado | Resultado |
|---:|---|---|
| 1 | Especificação, plano e tarefas Spec Kit | Criados em `specs/017-central-ajuda`; alinhados à implementação. |
| 2 | Lista oficial / RF-031 | Pendente de orientação e fontes. Asset vazio; B6 e T011 continuam abertas. |
| 3 | Chaves sem uso | Removidas helpSaveFailed, helpDeleteFailed e helpPhotoInitials dos AppStrings e JSONs. |
| 4 | Avatar e iniciais compartilhados | `PersonAvatar` e função de iniciais compartilhada por Help/Profile; escala do texto preservada. |
| 5 | Normalização de telefone | Um normalizador comum é usado por Help e serviço de discagem; validator de Profile restaurado. |
| 6 | Fakes compartilhados | Removidos fakes duplicados da feature; helper usa os fakes existentes em `test/fakes`. |
| 7 | Teste do asset oficial | Removido parâmetro bundle; teste lê o asset real e valida campos quando houver registros, sem exigir lista vazia. |
| 8 | Barrel público | Removidos exports de HelpController e ContactFormController. |
| 9 | Estado do formulário | Removidos controllers e setters duplicados da página; formulário observa o controller via `Consumer` e usa valores iniciais. |
| 10 | Widget de formulário legado | Wrapper `HelpContactPage` removido; rotas apontam para `ContactFormPage`. |
| 11 | Cache | Removida releitura após persistência bem-sucedida. |
| 12 | Erros e validação de widgets | Help cobre erro/retry, contato não encontrado, permissão negada e validação de nome e telefone inválido. |
| 13 | Fallback de telefone | Removido estado redundante; a página usa o retorno da chamada e o telefone do contato. |
| 14 | Serviços de plataforma | Removidos catches de falhas que os contratos tipados não lançam. |
| 15 | API pública de controller | Dependências e identificadores de contato ficaram privados. |
| 16 | Helpers de rotas | Rotas usam helper de caminho para formulário de contato. |
| 17 | Igualdade da entidade | Confirmado uso apenas em testes; `==`/`hashCode` removidos e teste de modelo compara os campos. |
| 18 | Título e contato ausente | Criação usa `helpAddContact`; contato não encontrado usa `SafeEmptyState`. |
| 19 | Localização do teste de modelo | Teste movido para `test/modules/help/data/models`. |
| 20 | Injeção em testes | `HelpModule` registrado normalmente; fake repository substitui o lazy singleton somente no helper de testes. |

O `SafeTextField` recebeu suporte a valor inicial para o formulário observar somente o estado
do controller. Testes cobrem troca de controller e preservação de seleção/composição ao digitar.
O roadmap global voltou a usar subtarefas simples, com B6 aberta por RF-031. Alterações auxiliares
em Settings e no validator de Profile foram revertidas para manter o escopo da revisão.

## Validação

- `flutter test --no-pub test/core/widgets test/modules/common/services/external_launcher_service_test.dart test/modules/help test/modules/profile test/core/routing/app_router_test.dart` — passou, 246 testes.
- `flutter analyze --no-pub --no-fatal-infos` — sem erros ou warnings; 28 infos preexistentes em `safe_badge`, `unavailable_service` e `style_guide`.
- `git diff --check` — passou.

## Pendência

RF-031 requer a lista de contatos de polícia, bancos e Procon e as fontes oficiais indicadas pelo TCC. Essa definição ainda depende de orientação de produto; T011 permanece aberta e B6 não está concluída.
