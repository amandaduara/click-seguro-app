# Contrato: perguntas do módulo (API, rota e tela)

**Feature**: [../spec.md](../spec.md) · **Plan**: [../plan.md](../plan.md)

## 1. Endpoint (contrato da API 1.0.10)

| Método e caminho | Auth | Sucesso | Erros tratados |
|---|---|---|---|
| `GET /app/educational/modules/{moduleId}` | opcional (visitante sem token) | 200 `moduleDetail` (R0) | 404 `EDUCATIONAL_MODULE_NOT_FOUND` → estado "sem atividades"; demais → erro com "Tentar novamente" |

## 2. Rota

| Caminho | Tela | Muda? |
|---|---|---|
| `/activities/:moduleId` (sobre as abas) | `LessonPage` (antes: `ActivityModulePage` provisória, removida) | sim |

Ao voltar para o painel, ele recarrega (B1, `RefreshOnReturnMixin`): sem mudança aqui.

## 3. Tela (de cima para baixo)

```text
AppBar: <título do módulo> (voltar)
"Pergunta 2 de 3"  ●✓  ●(atual)  ○
───────── rolável ─────────
[imagem, até 220 de altura; some se faltar ou falhar]
<enunciado> (18/700)
 1. <alternativa>
 2. <alternativa>
 3. <alternativa>
[Ouvir | Parar]   (só com voz no idioma do app)
───────── fixo ─────────
[Anterior]                 [Próxima]
```

| Ação | Efeito |
|---|---|
| "Próxima" | só com a pergunta atual respondida e não sendo a última; para a leitura; lê sozinha a nova se a leitura automática estiver ligada |
| "Anterior" | qualquer pergunta anterior; mesmo efeito na leitura |
| "Ouvir" | lê "<enunciado>. Alternativa 1: …. Alternativa 2: …" na velocidade da Acessibilidade |
| sair da tela | para a leitura |

| Estado | Conteúdo |
|---|---|
| carregando | `SafeLoadingState`; depois de 5 s, o aviso de serviço acordando |
| erro | `SafeErrorState` com "Tentar novamente" |
| sem atividades | `SafeEmptyState` "Este módulo ainda não tem atividades" |

## 4. Mudança compartilhada

`core/widgets/listen_button.dart` (`ListenButton`): botão "Ouvir"/"Parar" extraído do
`ReadAloudBar` da notícia (feature 010), que passa a usá-lo; chaves `common_listen`/`common_stop`.
