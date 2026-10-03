# Quickstart: validar a sessão persistente com modo visitante

**Feature**: [spec.md](spec.md) · **Contratos**: [contracts/session-and-storage.md](contracts/session-and-storage.md)
· **Modelo**: [data-model.md](data-model.md)

## Pré-requisitos

- Flutter 3.47.x (`flutter --version`) e dependências instaladas:
  `cd click_seguro_app && flutter pub get`.
- Para a verificação no aparelho: celular Android com depuração USB ligada (`flutter devices`).

## 1. Testes automatizados (cobrem as 3 histórias)

```powershell
cd click_seguro_app
flutter analyze
flutter test test/modules/common/services/ test/modules/common/api_client/
flutter test
```

Resultado esperado: todos verdes e nenhum erro ou warning novo no `analyze`. O que cada grupo
prova:

| Grupo de teste | Prova | Spec |
|---|---|---|
| `user_session_service_test.dart` › restaurar | reabrir com registro `authenticated`/`guest` recupera o estado; sem registro, corrompido ou falha de leitura → desconectado, sem exceção | US1, US2, FR-001, FR-006, FR-014, SC-001, SC-007 |
| › visitante | `startGuestSession` persiste; `saveSession` a partir do visitante remove a marca | US2, FR-005, FR-007 |
| › encerrar | `logout` → motivo `userLogout`; `expire` → motivo `expired`; `expire` sem sessão não faz nada; outras chaves intactas | US3, FR-012, FR-012a, FR-013, SC-005 |
| › notificação | quem escuta `sessionStatus` lê valores já atualizados | FR-004 |
| `secure_storage_service_test.dart` / `local_cache_service_test.dart` | implementações de plataforma com os mocks oficiais dos pacotes | FR-010, F0.3 |
| `api_client_test.dart` › 401 | 401 com sessão → `expire()` (fica `unauthenticated` com motivo `expired`); 401 sem sessão → nenhum aviso | FR-012a, CB-003 |

## 2. Auditoria do log (SC-006)

```powershell
flutter run --dart-define=DEBUG_MODE=true --dart-define=API_URL=<url-da-api>
```

Com qualquer tela que faça uma requisição autenticada, procurar no console por `Bearer` e
`Authorization`. Resultado esperado: **nenhuma ocorrência**.

## 3. Build de release no aparelho (FR-015)

```powershell
flutter build apk --release
flutter install -d <id-do-aparelho>
```

Resultado esperado: o app instala e abre sem erro. A permissão de internet está no manifest
principal (dá para conferir com
`aapt dump permissions build/app/outputs/flutter-apk/app-release.apk`, se o `aapt` estiver
disponível).

## 4. Ponta a ponta com UI (depois da tarefa A2)

Esta feature não tem tela. Quando o login (A2) existir, repetir no aparelho:

1. Entrar com uma conta → fechar o app pela lista de recentes → reabrir. Deve abrir conectado
   (SC-001).
2. Modo avião → reabrir. Deve continuar conectado (SC-003).
3. Sair da conta → reabrir. Deve abrir no login (SC-005).
4. "Entrar como visitante" → fechar → reabrir. Deve continuar visitante (US2).
