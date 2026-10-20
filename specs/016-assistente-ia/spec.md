# Assistente de IA

## Objetivo

Oferecer orientação sobre segurança digital e permitir verificar textos ou imagens suspeitas usando os endpoints v1 de IA da API. Esta especificação autoriza o v2 antes adiado.

## Escopo funcional

- A tela terá três áreas: **Conversar**, **Verificar** e **Histórico**.
- Conversar envia mensagem entre 5 e 1.000 caracteres e até 20 turnos de contexto (`user`/`model`), cada um entre 1 e 2.000 caracteres. Uma resposta completa permanece na conversa em memória; ao montar contexto para próximo envio, turnos acima de 2.000 caracteres são limitados ao contrato. Respostas não são persistidas no aparelho nem recuperadas do histórico.
- Verificar oferece texto (10–5.000 caracteres) e imagem JPEG, PNG ou WebP até 5 MB. O envio só ocorre após ação explícita. A origem é opcional e permanece string, limitada a 1–50 caracteres.
- Histórico permite paginação por `page` e `limit` (1–100) e filtro opcional `ANALYZE`/`CHAT`. A lista representa os metadados e análises fornecidos pela API; não reconstrói mensagens nem respostas do chat.
- Todas as operações exigem sessão autenticada. Sessões visitantes não chamam esses endpoints.

## Contrato da API

Usar exclusivamente `POST /app/ai/chat`, `POST /app/ai/analyze`, `POST /app/ai/analyze/image` e `GET /app/ai/history`, sob o prefixo de API já configurado. Não criar endpoint, streaming, identificador de conversa ou exclusão de histórico.

O resultado de análise preserva `type`, scores anuláveis, explicação, dicas, cache, tipo de entrada, status e data. Enum futuro/desconhecido deve permanecer desconhecido; nulos permanecem indisponíveis e nunca viram zero ou `SAFE`. A UI deve apresentar risco e confiança sem omitir a incerteza do serviço.

## Privacidade e limites

Mensagens, turnos e imagens são enviados apenas após ação do usuário e processados pelo serviço; o Swagger descreve persistência de entradas para auditoria. Não persistir conteúdo localmente. A API não retorna conteúdo completo de conversas no histórico. Imagens temporárias escolhidas para análise devem ser removidas após envio ou cancelamento. A implementação valida tamanho e assinatura binária do arquivo antes da rede e envia o campo multipart `image` com MIME correspondente.

## Critérios de aceite

- Payload, autenticação, filtros e paginação seguem o Swagger local.
- Validações de limites ocorrem antes da rede e produzem falhas tipadas com chaves `assistant_*`.
- Erros de provider, parse, arquivo inválido e rate limit têm falhas distinguíveis; outros erros seguem o mapper comum.
- Testes são determinísticos e offline; nenhum endpoint real é chamado durante implementação ou validação.
