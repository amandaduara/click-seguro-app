# Data Model: Serviços de plataforma e voz

**Feature**: [spec.md](spec.md) · **Plan**: [plan.md](plan.md) · **Date**: 2026-10-07

Nada é persistido nem vai para a API. Os únicos dados guardados são os arquivos de foto em
`<documentos do app>/images/`. Os tipos abaixo são valores trocados entre os serviços, o
controller e as telas.

## Tipos de valor

| Tipo | Arquivo | Valores / campos | Regras |
|---|---|---|---|
| `ReadingSpeed` (enum) | `text_to_speech_service.dart` | `slow`, `normal`, `fast` | Padrão `normal`. A conversão para o plugin (0.4/0.5/0.6) fica só na implementação ([R4](research.md#r4-velocidades)). |
| `SpeechLanguage` (enum) | `text_to_speech_service.dart` | `ptBr` (`'pt-BR'`), `enUs` (`'en-US'`); campo `tag` | `fromLocale(Locale)`: `en` → `enUs`, outro → `ptBr` ([R5](research.md#r5-idioma-da-voz)). |
| `ShareOutcome` (enum) | `share_service.dart` | `shared`, `cancelled`, `failed` | `cancelled` não é erro (US3 cenário 2). |
| `PhotoSource` (enum) | `image_storage_service.dart` | `gallery`, `camera` | |
| `PickImageResult` (sealed) | `image_storage_service.dart` | `PickedImage(String path)`, `PickImageCancelled`, `PickImagePermissionDenied`, `PickImageFailed` | `path` é sempre absoluto e dentro de `images/` do app. |

## Foto guardada (arquivo)

- **Local**: `<getApplicationDocumentsDirectory()>/images/img_<microssegundos>[_n].<ext>`.
- **Tamanho**: lado maior ≤ 1024 px, qualidade JPEG 85 (FR-014, SC-004).
- **Nome único**: o sufixo `_n` é acrescentado se o nome já existir (edge case "duas fotos com o
  mesmo nome de origem").
- **Ciclo de vida**: criada por `pickImage`, apagada por `delete(path)`. Ela sobrevive ao logout
  (RN-007) e some se o app for desinstalado. Quem guarda o caminho e decide quando apagar são as
  telas (B6, B7).

## `ReadAloudController` (estado)

| Campo (getter) | Tipo | Inicial | Significado |
|---|---|---|---|
| `isAvailable` | `bool` | `false` | Há voz no idioma preparado. Continua `false` enquanto não houver verificação. |
| `isSpeaking` | `bool` | `false` | Uma leitura iniciada por **este** controller está em curso. |
| `speed` | `ReadingSpeed` | `normal` | Velocidade da próxima leitura. |

Campos internos: idioma preparado (`SpeechLanguage?`), cache de disponibilidade por idioma
(`Map<SpeechLanguage, bool>`) e geração da leitura atual (`int`).

### Transições

```text
              prepare(locale)
  [sem idioma] ─────────────▶ verifica (cache por idioma) ──▶ isAvailable = true | false

  isSpeaking:
  parado ── speak(texto não vazio) e isAvailable ──▶ lendo        (geração++, notifica)
  lendo  ── speak(outro texto) ──▶ stop + lendo                   (geração++, a antiga é ignorada)
  lendo  ── stop() ──▶ parado                                     (na hora, sem esperar o motor)
  lendo  ── fim do Future de speak (true/false) da geração atual ──▶ parado
  lendo  ── dispose() ──▶ stop no serviço (sem notificar)
  parado ── speak("" / "  ") ou !isAvailable ──▶ parado           (nada é chamado)
```

- `setSpeed(s)`: muda `speed` e notifica. Não afeta a leitura em curso (cenário 7).
- Falha do motor: o `Future` de `speak` devolve `false` e o estado volta a parado (cenário 10).
- `prepare` com outro idioma durante uma leitura não interrompe a leitura. A nova voz vale para
  a próxima (cenário 9).

## Mapeamento requisito → elemento

| Requisito | Onde |
|---|---|
| FR-001, FR-002 | `TextToSpeechService.isAvailable` + `ReadAloudController.prepare/isAvailable` |
| FR-003 | `speak(text, language, speed)` + `SpeechLanguage.fromLocale` + `ReadingSpeed` |
| FR-004 a FR-007 | transições do `ReadAloudController` |
| FR-008, FR-009 | `ExternalLauncherService.openUrl` + `isOpenableWebUrl` |
| FR-010, FR-011 | `canCall`, `call` + `normalizePhoneNumber` |
| FR-012 | `ShareService.shareText` → `ShareOutcome` |
| FR-013 a FR-016 | `ImageStorageService.pickImage/delete` → `PickImageResult` |
| FR-017 | nenhum serviço lança ([R1](research.md#r1-formato-dos-contratos-resultados-tipados-nunca-exceção)) |
| FR-018 | fakes em `test/fakes/` + registro no `CommonModule` |
