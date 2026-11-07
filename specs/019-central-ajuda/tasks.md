---
description: "Tarefas da central de ajuda"
---

# Tasks: Central de ajuda

**Input**: Documentos de design em `/specs/019-central-ajuda/`

**Prerequisites**: `plan.md`, `spec.md`

**Tests**: Incluídos conforme os cenários e requisitos da feature.

## Phase 1: Base e lista de contatos

- [x] T001 Manter o asset temporariamente sem dados fabricados até a orientação sobre a lista oficial obrigatória de RF-031.
- [x] T002 Carregar o asset oficial real em `click_seguro_app/lib/modules/help/data/datasources/official_contacts_local_data_source.dart`.
- [x] T003 Exibir estados vazio, erro e nova tentativa na lista em `click_seguro_app/lib/modules/help/presentation/pages/help_page.dart`.
- [x] T004 Oferecer cópia do telefone do próprio contato quando a chamada não abre em `click_seguro_app/lib/modules/help/presentation/pages/help_page.dart`.

## Phase 2: Contatos pessoais e foto

- [x] T005 Validar e persistir contatos pessoais pelo módulo Help.
- [x] T006 Exibir validação, permissão negada e contato ausente no formulário.
- [x] T007 Reutilizar normalização de telefone e avatar nas features Help/Profile.
- [x] T008 Cobrir datasource, controller, formulário, rotas e módulo com fakes locais.

## Phase 3: Revisão e documentação

- [x] T009 Remover APIs e traduções sem uso, releitura redundante de cache e wrappers de rota.
- [x] T010 Manter os artefatos de especificação coerentes com o comportamento entregue.
- [ ] T011 Definir os contatos oficiais de polícia, bancos, Procon e canais anti-golpe e suas fontes conforme a orientação do TCC (RF-031).

## Dependency Note

T011 depende da orientação do TCC e da validação das fontes oficiais. A feature B6 permanece aberta por RF-031 até essa decisão.
