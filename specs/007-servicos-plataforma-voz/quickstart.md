# Quickstart: validar os serviços de plataforma e a voz

**Feature**: [spec.md](spec.md) · **Date**: 2026-10-07

Comandos a partir de `click_seguro_app/`. A API pública validada aqui está em
[contracts/platform-services-api.md](contracts/platform-services-api.md); os estados do
controller, em [data-model.md](data-model.md).

## 1. Automático

```bash
flutter analyze
flutter test test/modules/common/services test/modules/common/presentation
flutter test
```

Esperado:

- análise sem avisos novos;
- `read_aloud_controller_test.dart` cobrindo os 10 cenários da US1 com o
  `FakeTextToSpeechService` (indisponível → `isAvailable == false`; leitura nova interrompe a
  antiga; parar; fim; falha; `dispose`; troca de idioma; velocidade);
- testes de cada implementação (`flutter_tts`, `url_launcher`, `share_plus`, `image_picker` +
  pasta temporária) e das funções `normalizePhoneNumber`/`isOpenableWebUrl`;
- suíte inteira verde (nenhuma tela existente muda).

## 2. No aparelho (Android físico; iOS se disponível)

Não há tela nova, então a validação usa uma tela de testes de desenvolvimento, separada do app
(mesmo esquema do style guide, com `main` próprio e sem uso pelo app):

```bash
flutter run -t lib/dev/platform_services_playground.dart
```

| # | Passos | Esperado |
|---|--------|----------|
| 1 | Abrir com o celular em português | "Voz disponível: sim" |
| 2 | "Ouvir" o texto B (mais de 4000 caracteres) | Leitura em pt-BR começa em até 1 s; estado "lendo"; segue até o fim, sem pausa estranha entre as partes |
| 3 | "Parar" no meio | Para em até 1 s; estado "parado" |
| 4 | Trocar para "lenta" e "rápida" e ouvir de novo | Diferença perceptível; "normal" igual à voz padrão |
| 5 | "Ouvir" o texto A e, durante a leitura, o texto B | A para, B começa; nunca os dois |
| 6 | Deixar terminar | Estado volta a "parado" sozinho |
| 7 | Mudar o idioma do celular para inglês e reabrir | Lê com voz en-US (ou "Voz disponível: não" se não houver voz instalada) |
| 8 | Sair da tela durante a leitura | A voz para |
| 9 | "Abrir fonte" com `https://www.gov.br` | Abre no navegador do aparelho, fora do app → "abriu" |
| 10 | "Abrir fonte" com `www.gov.br` e com vazio | Nada abre → "não abriu", app continua |
| 11 | "Ligar" `(11) 9 1234-5678` | Discador com `11912345678`, sem completar a ligação |
| 12 | "Pode ligar?" num tablet/emulador sem discador | "não" |
| 13 | "Compartilhar" e escolher o WhatsApp | Texto chega; resultado "compartilhado" |
| 14 | "Compartilhar" e fechar o menu | "cancelado", sem erro |
| 15 | "Galeria", escolher uma foto grande | Caminho em `.../app_flutter/images/img_….jpg`; foto ≤ 1024 px |
| 16 | "Câmera", tirar e confirmar | Mesmo resultado |
| 17 | Abrir a galeria/câmera e desistir | "nenhuma foto" |
| 18 | (iOS) negar acesso às fotos e tentar | "sem permissão" |
| 19 | "Apagar" a última foto, e apagar de novo | Some do disco; a segunda vez não dá erro |
