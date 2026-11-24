# Implementation Plan: Ajustes da validação no aparelho

**Branch**: `025-ajustes-validacao` | **Date**: 2026-11-19 | **Spec**: [spec.md](spec.md)

## Resumo

Ajustes pequenos, feitos rodada a rodada conforme a usuária validava no aparelho. As decisões
técnicas principais estão abaixo. O resto é ajuste local de tela.

## Contexto técnico

Flutter 3.47 / Dart 3.13, Clean Architecture por módulo (`data → domain → presentation`),
Provider + GetIt, go_router, easy_localization (pt-BR/en-US), `flutter_tts`. Sem dependência
nova.

## Decisões

1. **Leitura em trechos com idioma** (`common/presentation/controller/read_aloud_controller.dart`):
   - `SpeechPart(text, {content})` marca o trecho que vem do banco;
   - `speakParts` lê os trechos em ordem, cada um na sua voz;
   - `contentLanguage` é pt-BR;
   - `prepare` confere a voz do idioma do app e a do conteúdo;
   - `isContentAvailable` mostra o botão em telas só de conteúdo;
   - `speak(text, {content})` continua como atalho.

   As respostas da IA são conteúdo: a API é uma assistente brasileira, sem opção de idioma.
2. **Cabeçalho único em `core/widgets/safe_page_header.dart`**: `SafeBackButton`,
   `SafePageHeader` e `SafePageScaffold` (com `scrollable` para o cabeçalho rolar junto). Ele
   substitui a `AppBar` do Material nas telas internas e o cabeçalho próprio das Configurações.
3. **Tentativa nova ao refazer** (activities):
   - `ModuleDetailEntity.startsNewAttempt` e `forRetake` decidem: o módulo todo concluído (ou o
     pedido de refazer) começa do zero, e só as lições respondidas nesta tentativa contam;
   - `ModuleSummaryEntity.score` dá o status `retry` (selo "Refazer") quando a pessoa acertou
     menos da metade;
   - a lista da API não traz a pontuação. Por isso o repositório pede o detalhe de cada módulo
     concluído, em paralelo, na carga do painel. Uma falha deixa o módulo como "Concluído".
     Decisão consciente: são poucos módulos. Se a API passar a mandar `score` na lista, essas
     chamadas saem.
4. **Contatos oficiais da API** (help): o datasource remoto usa o `ApiClient`, e o repositório
   segue o caminho API → cópia em `LocalCacheService` → asset de reserva. Está em
   api-contract 1.1.3.
5. **Assistente com uma estrutura de layout só**: a troca de layout ao abrir o teclado recriava
   o campo. O rodapé fica limitado à metade da altura e rola. A leitura automática escuta o
   `AssistantController` (resposta e resultado novos) e o `ReadAloudController` (voz verificada
   → boas-vindas).

## Constituição

- I (arquitetura): sem import entre módulos; o controller só chama usecases.
- II (TDD): cada ajuste tem teste antes da correção.
- IV (dependências): nenhuma nova.
- V (acessibilidade): botões com 48 dp, `Semantics` e teste com letra 2×.
