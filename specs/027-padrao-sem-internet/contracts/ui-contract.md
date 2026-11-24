# UI Contract: Padrão único para a falta de internet

## Componentes compartilhados (`core`)

### `SafeErrorState`

```dart
const SafeErrorState({
  Key? key,
  required Failure? failure,   // decide o desenho e a frase
  String? message,             // texto da tela (traduzido) para falhas que não são de conexão
  required VoidCallback onRetry,
});
```

| `failure` | Ilustração | Texto |
|---|---|---|
| `ConnectionFailure` | `stateOffline` (nuvem) | `error_connection` |
| outra | `stateError` (tomada) | `message` ou `failure.message` |
| `null` | `stateError` | `message` ou `error_generic` |

Sempre com o botão `common_try_again`.

### `SafeOfflineBanner`

```dart
const SafeOfflineBanner({Key? key, bool showsSavedContent = true});
```

### `FailureMessageKey.messageKeyOr`

`Failure?` → chave de texto: `error_connection` para `ConnectionFailure`, senão a chave
recebida.

## Chaves de texto

| Chave | pt-BR | en-US |
|---|---|---|
| `common_offline_banner_short` (nova) | Você está sem internet. | You're offline. |
| `error_connection` (existente) | Sem conexão com a internet. Verifique sua rede. | (atual) |

Nenhuma chave existente muda de texto.

## Onde cada caso aparece

| Caso | Telas e ações | Formato |
|---|---|---|
| Tela sem conteúdo | Atividades, Lição, Reels, Perfil, Editar perfil, Conquistas, Central de ajuda, Formulário de contato, Histórico do Assistente, Salvas, Detalhe da notícia, Início sem cópia | `SafeErrorState` |
| Ação com a tela aberta | Responder questão, Trocar senha, Editar perfil (salvar, foto), salvar/curtir/denunciar notícia, atualizar o Início | `SnackBar` |
| Formulário de entrada | Login, Criar conta, Esqueci a senha, Assistente | texto na tela (atual) |
| Bloco parcial | Números e conquistas no Perfil, fim do feed/Salvas/Reels, linha dos alertas | texto no bloco + tentar de novo (atual) |
| Conteúdo guardado | Início, Detalhe, Salvas, Alertas | `SafeOfflineBanner` |
| Sem rede | Configurações (exceto alertas), Acessibilidade, Privacidade, Termos, Sobre | nada muda |
