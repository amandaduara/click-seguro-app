# Contrato: navegação de abertura (splash e onboarding)

**Feature**: [spec.md](../spec.md) · **Date**: 2026-10-04

Contrato de UI entre o splash, o onboarding e as rotas que eles abrem. Nenhum endpoint novo: a
conferência da conta usa o `GET /users/me` já descrito no
[api-contract](../../../.specify/memory/api-contract.md) e encapsulado pelo
`SessionValidationService` (feature 002).

## Rotas

| Rota | Tela | Quem abre | Como |
|------|------|-----------|------|
| `/` | Splash | rota inicial do app | `initialLocation` |
| `/onboarding` | Onboarding | splash | `context.go` (substitui) |
| `/home` | Área principal (provisória até a F0.9) | splash | `context.go` |
| `/login` | Login | splash e onboarding | `context.go` |

Toda navegação é por `go` (substitui a pilha): "voltar" nunca retorna ao splash nem ao onboarding
(FR-003).

## Splash

- **Exibe**: escudo, "SafeNews" (`app_title`) e a frase de apoio (`splash_tagline`), sobre o fundo
  primário.
- **Tempo**: no mínimo 2 s; no máximo cerca de 3 s (prazo da conferência).
- **Navega uma única vez**, para o destino da [tabela de decisão](../data-model.md), e só se a
  tela ainda estiver montada.

## Onboarding

- 3 slides; "Continuar" nos dois primeiros, "Começar" no último; "Pular" em todos.
- "Começar" e "Pular" gravam a marcação e vão a `/login`, mesmo se a gravação falhar.

## Interfaces internas (Dart)

```text
ValidateStoredSessionUseCase          (splash/domain/usecases)
  call() → Future<UserSessionStatus>   nunca lança

SplashDestination                      (splash/presentation/controller)
  onboarding('/onboarding') · home('/home') · login('/login')
  path: String

SplashController                       (splash/presentation/controller)
  SplashController(CheckOnboardingSeenUseCase, ValidateStoredSessionUseCase,
                   {Duration minimumDisplayDuration = 2 s})
  destination: SplashDestination?      null até decidir
  resolveDestination() → Future<void>  notifica uma vez ao decidir
```
