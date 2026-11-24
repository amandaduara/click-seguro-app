# Data Model: Splash com sessão e onboarding

**Feature**: [spec.md](spec.md) · **Date**: 2026-10-04

Nenhum dado novo é persistido. A feature combina dois estados que já existem e produz um destino.

## Entradas (já existentes)

| Item | Onde vive | Valores | Origem |
|------|-----------|---------|--------|
| Marcação de onboarding visto | `SharedPreferences`, chave `onboarding_seen` (via `OnboardingRepository`) | `true` / `false`; leitura com falha → tratada como `false` | RN-004, já existe |
| Estado da sessão | `UserSessionService.sessionStatus` (restaurado antes do `runApp`) | `UserSessionStatus.authenticated` / `guest` / `unauthenticated` | features 001 e 002 |

## Transição causada pela validação

Só acontece quando o estado inicial é `authenticated`; para `guest` e `unauthenticated` a
validação não faz nada (FR-007).

| Resposta da conferência (feature 002) | Efeito na sessão | Estado depois |
|---------------------------------------|------------------|---------------|
| Conta confirmada | nome e e-mail atualizados | `authenticated` |
| Conta inexistente / renovação recusada | sessão encerrada pelo `ApiClient` | `unauthenticated` |
| Sem rede, erro 5xx, corpo inválido, prazo esgotado | nenhum | `authenticated` |
| Erro inesperado (não deveria ocorrer) | nenhum | o estado no momento do erro |

## Saída: `SplashDestination` (novo, enum de apresentação)

| Valor | Rota | Quando |
|-------|------|--------|
| `onboarding` | `/onboarding` | marcação = `false` (independente da sessão) |
| `home` | `/home` | marcação = `true` e estado depois da validação ∈ {`authenticated`, `guest`} |
| `login` | `/login` | marcação = `true` e estado depois da validação = `unauthenticated` |

## Tabela de decisão completa (base dos testes do FR-013)

| # | Onboarding visto | Sessão inicial | Conferência | Destino |
|---|------------------|----------------|-------------|---------|
| 1 | não | qualquer | qualquer | `onboarding` |
| 2 | leitura falhou | qualquer | qualquer | `onboarding` |
| 3 | sim | `authenticated` | confirmada | `home` |
| 4 | sim | `authenticated` | conta recusada | `login` |
| 5 | sim | `authenticated` | sem rede / prazo esgotado | `home` |
| 6 | sim | `guest` | não feita | `home` |
| 7 | sim | `unauthenticated` | não feita | `login` |
| 8 | sim | `authenticated` | erro inesperado no usecase | `home` (estado mantido) |
