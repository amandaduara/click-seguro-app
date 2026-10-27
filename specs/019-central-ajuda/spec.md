# Feature Specification: Central de ajuda

**Feature Branch**: `015-central-ajuda`

**Created**: 2026-10-22

**Status**: Em andamento — B6 permanece aberta

**Input**: Central de ajuda com contatos oficiais e pessoais, discagem, cadastro, edição, exclusão e foto local de contatos de confiança.

**ID documental**: `019` é o próximo número livre (`016` é o Assistente, `017` e `018` são as perguntas e a resposta das atividades); a branch histórica `015-central-ajuda` foi mantida para preservar o PR20.

## User Scenarios & Testing

### User Story 1 — Consultar e ligar para contatos (Priority: P1)

A pessoa consulta a lista oficial disponível ou seus contatos pessoais e tenta ligar para um contato.

**Why this priority**: A ligação é a ação urgente da central de ajuda.

**Independent Test**: Abrir `/help`, alternar as abas e acionar uma chamada com o discador disponível e indisponível.

**Acceptance Scenarios**:

1. **Given** que a lista oficial ainda não foi validada por uma fonte autorizada, **When** a pessoa abre a aba oficial, **Then** o app informa que a lista ainda não está disponível e não mostra números inventados.
2. **Given** que existem contatos pessoais, **When** a pessoa tenta ligar e o aparelho não abre o discador, **Then** o app mostra o número do próprio contato e permite copiá-lo.

### User Story 2 — Manter contatos de confiança (Priority: P2)

A pessoa cadastra, edita e remove contatos pessoais, com nome e telefone obrigatórios e parentesco e foto opcionais.

**Why this priority**: Contatos escolhidos pela própria pessoa tornam possível usar a central mesmo sem uma lista oficial definida.

**Independent Test**: Cadastrar contato válido, rejeitar nome/telefone inválidos, reabrir para edição e confirmar remoção.

**Acceptance Scenarios**:

1. **Given** o formulário vazio, **When** a pessoa salva nome ou telefone inválido, **Then** o campo correspondente informa o erro e nenhum contato é salvo.
2. **Given** um contato salvo, **When** a pessoa altera seus dados ou o remove, **Then** a lista pessoal reflete a operação e fotos locais removidas são limpas pelo serviço de plataforma.

### User Story 3 — Escolher uma foto (Priority: P3)

A pessoa pode escolher uma foto da galeria ou câmera para identificar um contato.

**Why this priority**: A foto ajuda a reconhecer o contato, mas é opcional para concluir o cadastro.

**Independent Test**: Selecionar foto, negar permissão e salvar contato sem foto.

**Acceptance Scenarios**:

1. **Given** que a permissão foi negada, **When** a pessoa tenta escolher uma foto, **Then** recebe orientação e pode continuar sem foto.
2. **Given** uma imagem local ausente ou inválida, **When** a lista é exibida, **Then** o avatar mostra iniciais sem ampliar a escala do sistema.

## Edge Cases

- A lista oficial vazia permanece vazia até receber contatos e origem oficialmente autorizados.
- Uma falha ao carregar contatos permite tentar novamente.
- Um contato editado que deixou de existir mostra estado de não encontrado.
- Falha ao abrir o discador oferece cópia do telefone do contato.
- Erro ao escolher foto não impede salvar sem foto.

## Requirements

### Functional Requirements

- **FR-001**: O sistema MUST exibir listas oficiais e pessoais em abas separadas.
- **FR-002**: O sistema MUST exibir a lista oficial de contatos de emergência indicada pelo TCC, com contatos de polícia, bancos e Procon.
- **FR-003**: O sistema MUST permitir tentativa de ligação e cópia do número quando o discador não puder ser aberto.
- **FR-004**: O sistema MUST validar nome e telefone antes de salvar contato pessoal.
- **FR-005**: O sistema MUST permitir cadastrar, editar e remover contatos pessoais localmente.
- **FR-006**: A foto MUST ser opcional e permanecer armazenada no aparelho.
- **FR-007**: A falha de permissão para fotos MUST permitir que a pessoa continue sem foto.
- **FR-008**: Estados de carregamento, erro com nova tentativa e contato não encontrado MUST ter mensagens compreensíveis.

### Key Entities

- **Contato**: identificador, nome, telefone, tipo oficial/pessoal e parentesco/foto opcionais.

## Success Criteria

- **SC-001**: Contatos pessoais válidos podem ser cadastrados, reabertos e removidos sem rede.
- **SC-002**: Entradas inválidas não são persistidas e exibem o campo a corrigir.
- **SC-003**: Todos os contatos oficiais exibidos têm procedência autorizada e incluem as categorias definidas em RF-031.

## Assumptions

- Contatos pessoais e fotos são dados locais do aparelho.
- A orientação do TCC para preencher e verificar a lista oficial ainda está pendente; RF-031 mantém B6 aberta.
- A funcionalidade usa os serviços de plataforma compartilhados para discagem e seleção/remoção de imagens.
