# Implementation Plan: Central de ajuda

**Branch**: `015-central-ajuda` | **Date**: 2026-10-22 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/019-central-ajuda/spec.md`

O diretório `019-central-ajuda` usa o próximo número livre (`016` é o Assistente, `017` e `018` são as perguntas e a resposta das atividades). A branch histórica `015-central-ajuda` permanece para preservar o PR20.

## Summary

B6 organiza contatos oficiais e pessoais, oferece chamada/cópia de telefone e permite manter contatos pessoais com dados e foto locais. O asset oficial permanece vazio até haver fonte autorizada. A pendência de conteúdo oficial mantém B6 aberta.

## Technical Context

**Language/Version**: Dart / Flutter conforme `click_seguro_app/pubspec.yaml`

**Primary Dependencies**: Provider, GetIt, go_router, fpdart e serviços de plataforma existentes

**Storage**: Cache local para contatos e cópias locais de imagem

**Testing**: `flutter test` direcionado para help, profile e rotas; `flutter analyze`

**Target Platform**: Android e iOS

**Project Type**: Aplicativo móvel

**Constraints**: Offline para contatos pessoais; não inventar contatos oficiais; serviços de plataforma retornam resultados tipados.

**Scale/Scope**: Tela principal, formulário de contato, persistência local e acessos compartilhados de avatar/normalização.

## Constitution Check

- Camadas seguem `presentation → usecase → repository → datasource`.
- Serviços de plataforma são consumidos pelo controller conforme exceção prevista na constituição.
- GetIt registra o módulo; Provider observa os controllers.
- Testes são locais e determinísticos; asset oficial real é verificado pelo bundle de teste.
- Avatar e normalização são compartilhados para evitar duplicação.

## Project Structure

```text
click_seguro_app/lib/core/widgets/person_avatar.dart
click_seguro_app/lib/modules/help/{data,domain,presentation}/
click_seguro_app/lib/modules/profile/domain/validators/profile_form_validator.dart
click_seguro_app/test/modules/help/
click_seguro_app/test/modules/profile/
click_seguro_app/test/core/routing/
```

**Structure Decision**: A feature segue o módulo existente em `click_seguro_app/lib/modules/help`; recursos visuais comuns ficam em `core/widgets`.

## Pending Product Input

A definição dos contatos de polícia, bancos e Procon e suas fontes ainda depende da orientação do TCC. RF-031 exige essa lista para concluir B6; o asset está temporariamente `[]` até essa confirmação.
