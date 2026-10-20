# Plano — Assistente de IA

1. **Domínio e dados:** entities tipadas para análise e página de histórico, enum de turno, repository/usecases, modelos, datasource via `ApiClient` e repository que converte exceções em `Either<Failure, T>`.
2. **Contrato:** integrar as quatro rotas autenticadas do Swagger, mantendo os limites, valores anuláveis, enums desconhecidos e metadados reais de paginação.
3. **Segurança de imagem:** conferir assinatura JPEG/PNG/WebP e tamanho máximo de 5 MB antes de abrir chamada multipart; encaminhar origem como query.
4. **Apresentação:** três áreas Conversar/Verificar/Histórico; mensagens ficam em memória enquanto a tela estiver aberta; envio de verificação ocorre somente após ação explícita. Visitantes não acessam as operações.
5. **Validação:** testes offline cobrem regras e mapeamentos usando adapter Dio falso e arquivos temporários com assinaturas conhecidas. Validação automatizada central e contra o servidor ainda pendente; não executar chamadas reais durante a implementação.

## Riscos e decisões

- Histórico não restaura conversa: o contrato não disponibiliza mensagens/respostas completas.
- Risco e confiança podem ser nulos e enums podem evoluir; apresentação precisa ter estados “indisponível/desconhecido”.
- `ApiClient.postMultipart` não aceita query; a rota de imagem inclui `source` na URI construída pelo datasource, sem alterar o cliente comum.
- O logger oculta bodies nos caminhos `/app/ai/`; a validação do comportamento fica na etapa central.
- O conteúdo enviado vai ao serviço, que pode persistir entradas para auditoria; a aplicação não o guarda localmente e o histórico da API não restaura conversas.
