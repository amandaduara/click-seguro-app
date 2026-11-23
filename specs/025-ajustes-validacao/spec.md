# Feature Specification: Ajustes da validação no aparelho

**Feature Branch**: `025-ajustes-validacao`

**Created**: 2026-11-19

**Status**: Implemented (validado pela usuária no aparelho)

**Input**: Rodadas de validação do redesign 2.0 (specs/024) feitas pela usuária num Android real,
enviadas como listas numeradas de ajustes.

**Rastreabilidade**: tarefa **R2 Ajustes da validação no aparelho** no
[tasks do produto](../../.specify/memory/tasks.md) · RF-041 (leitura em voz alta), RNF-002
(offline), RNF-003 e RNF-004 (idosos e acessibilidade) da
[especificação do produto](../../.specify/memory/specification.md) ·
[contrato da API](../../.specify/memory/api-contract.md) 1.1.3 (contatos oficiais) ·
[feature 024](../024-redesign-visual/spec.md).

## Contexto

Depois do redesign 2.0, a usuária usou o app no próprio celular e listou o que atrapalhava. A
maior parte é sobre a leitura em voz alta. O botão "Ouvir" faltava em telas e, onde existia,
ficava longe do texto. O conteúdo do banco, que é em português, era lido com a voz em inglês
quando o app estava em inglês. A leitura automática não lia o Assistente. O resto são
correções visuais e de fluxo vistas no uso real.

Não muda regra de negócio nem rota. A única mudança de contrato é que os contatos oficiais
passam a vir da API (decisão da usuária, 2026-11-19).

## Requisitos

### Leitura em voz alta

- **FR-001**: O conteúdo do banco (notícias, Reels, destaques, perguntas e explicações das
  atividades, respostas da IA) é lido na voz em português, mesmo com o app em inglês. Os textos
  do próprio app são lidos no idioma do app. Uma leitura pode misturar as duas vozes, em ordem.
- **FR-002**: "Ouvir" fica junto do texto que ele lê, no topo do conteúdo: abaixo do enunciado
  da pergunta, do título do feedback e da conclusão; ao lado de "Destaques" no Início; em cada
  Reel; em Privacidade, Sobre e nos slides do Onboarding.
- **FR-003**: No Assistente, cada resposta, o balão de boas-vindas e o resultado da verificação
  têm o próprio "Ouvir". Só o que está tocando mostra "Parar". Tocar em outro troca a leitura.
- **FR-004**: Com a leitura automática ligada, o Assistente lê:
  - as boas-vindas ao abrir a conversa vazia (uma vez);
  - cada resposta nova;
  - cada resultado novo da verificação.
- **FR-005**: O botão só aparece quando o aparelho tem a voz necessária: a do idioma do app ou,
  para conteúdo, a do português.

### Atividades

- **FR-006**: Abrir pela lista um módulo já todo respondido começa uma tentativa nova: a barra
  de progresso vem vazia na pergunta 1. Um módulo respondido pela metade continua de onde parou.
- **FR-007**: Um módulo concluído em que a pessoa errou a maioria mostra o selo "Refazer".
- **FR-008**: A conclusão não tem "Compartilhar". Quem acertou menos da metade vê "Refazer o
  módulo" primeiro, em destaque.
- **FR-009**: Na lição, o título do módulo e o voltar rolam com o conteúdo. O rodapé
  "Confirmar resposta" continua fixo.

### Telas e componentes

- **FR-010**: As telas internas usam um cabeçalho único (`SafePageHeader`/`SafePageScaffold`):
  voltar redondo com o título na mesma linha. Isso vale para Alertas, listas do perfil,
  Conquistas, edição de perfil, contato, lição, conclusão, recuperar senha e Configurações.
- **FR-011**: O aviso de alertas desligados é um cartão do padrão do app, com o botão em
  destaque.
- **FR-012**: Nas linhas das Configurações com valor ("Idioma  English"), a seta fica no fim da
  linha. Na escolha de idioma, o sinal de selecionado também fica no fim.
- **FR-013**: A saudação do Início fica colada ao título "Notícias seguras".
- **FR-014**: O Assistente:
  - não fecha o teclado ao abrir o campo;
  - não desenha o indicador das abas fora do trilho quando o Histórico está aberto;
  - mostra o efeito de toque nos itens do histórico.

### Contatos oficiais

- **FR-015**: Os contatos oficiais vêm de `GET /app/official-contacts`. O app guarda uma cópia e
  tem o asset como reserva offline. O cartão mostra a descrição. Itens sem telefone são
  ignorados.
- **FR-016**: Números curtos de até 4 dígitos (ex.: 1331) aparecem sem máscara.

### Correções

- **FR-017**: Abrir outro Reel com a página já aberta não gera erro de `setState` durante o
  build (visto ao trocar de idioma e tocar numa notícia).

## Critérios de sucesso

- **SC-001**: A usuária validou cada item no aparelho (Samsung S24, Android).
- **SC-002**: `flutter analyze` sem avisos novos e `flutter test` todo verde.
