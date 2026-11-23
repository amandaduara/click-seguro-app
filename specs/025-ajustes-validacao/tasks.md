# Tasks: Ajustes da validação no aparelho

**Input**: [spec.md](spec.md), [plan.md](plan.md)

Cada tarefa seguiu TDD: o teste veio antes da correção e depois foi validado no aparelho.

## Leitura em voz alta

- [x] T001 `SpeechPart`/`speakParts`/`contentLanguage` no `ReadAloudController`, com testes (FR-001, FR-005)
- [x] T002 Notícia, Reels e destaques na voz em português; "Ouvir" ao lado de "Destaques" e em cada Reel (FR-001, FR-002)
- [x] T003 Atividades: "Ouvir" abaixo do enunciado, do título do feedback e da conclusão; pergunta e explicação na voz em português (FR-002)
- [x] T004 "Ouvir" em Privacidade, Sobre e nos slides do Onboarding (FR-002)
- [x] T005 Assistente: "Ouvir" em cada resposta, nas boas-vindas e no resultado; só o que toca mostra "Parar" (FR-003)
- [x] T006 Assistente: respostas, explicação e cuidados na voz em português (FR-001)
- [x] T007 Assistente: leitura automática da resposta, do resultado e das boas-vindas (FR-004)

## Atividades

- [x] T008 Refazer módulo concluído começa do zero; módulo pela metade retoma (FR-006)
- [x] T009 Selo "Refazer" quando a maioria errou (FR-007)
- [x] T010 Conclusão sem "Compartilhar"; "Refazer o módulo" em destaque com menos da metade (FR-008)
- [x] T011 Cabeçalho da lição rola com o conteúdo (FR-009)

## Telas e componentes

- [x] T012 `SafePageHeader`/`SafePageScaffold`/`SafeBackButton` em core e uso nas telas internas (FR-010)
- [x] T013 Aviso de alertas desligados no padrão do app (FR-011)
- [x] T014 Seta e sinal de selecionado no fim da linha nas Configurações (FR-012)
- [x] T015 Saudação do Início colada ao título (FR-013)
- [x] T016 Assistente: teclado, abas sem seleção e efeito de toque no histórico (FR-014)

## Contatos e correções

- [x] T017 Contatos oficiais da API com cópia local e asset de reserva; api-contract 1.1.3 (FR-015)
- [x] T018 Máscara de telefone mantém números de até 4 dígitos (FR-016)
- [x] T019 Reels sem `setState` durante o build ao abrir outro Reel (FR-017)

## Fechamento

- [x] T020 `flutter analyze` sem avisos novos e `flutter test` verde (SC-002)
- [x] T021 Validação da usuária no aparelho (SC-001)
