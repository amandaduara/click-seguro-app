# Data Model: Login que continua a splash, aceite dos termos e Termos de uso

**Feature**: [spec.md](spec.md) · **Data**: 2026-11-23

A feature não cria dados persistidos nem muda o que vai para o serviço. Só há estado de tela e
conteúdo fixo.

## 1. Aceite dos termos (estado do `AuthenticationController`)

| Campo | Tipo | Começa | Observação |
|---|---|---|---|
| `termsAccepted` | `bool` | `false` | Só tem efeito no modo cadastro |

**Transições**

| Evento | Antes | Depois |
|---|---|---|
| `setTermsAccepted(true)` | `false` | `true` |
| `setTermsAccepted(false)` | `true` | `false` |
| `setMode(login ↔ register)` | qualquer | **igual** (esclarecimento de 2026-11-23) |
| `reset()` (a tela abre ou a pessoa entra) | qualquer | `false` |
| Falha no cadastro (ex.: e-mail já existe) | `true` | `true` |
| Abrir Termos ou Privacidade pelo link e voltar | qualquer | igual (a página continua montada) |

**Regra derivada**

```text
canSubmit = sem erros no formulário
            && não está enviando
            && (modo == login || termsAccepted)
```

`submit()` confere a mesma condição e não chama o usecase se ela falhar.

## 2. Abertura splash → login (estado da página)

| Campo | Tipo | Valor |
|---|---|---|
| `fromSplash` | `bool` | `true` só para `/login?from=splash` |
| progresso da abertura | `double` 0–1 | 0 → 1 em 1 250 ms; nasce em 1 sem `fromSplash` ou com movimento reduzido |
| retângulo inicial da marca | `Rect` | `BrandScene.logoRectFor(largura, altura da tela, topo seguro)` |
| retângulo final da marca | `Rect` | o slot da marca no `AuthHeader`, medido depois do primeiro layout |

Os trechos da linha do tempo estão em [research.md](research.md) R1. Durante a abertura, a
página ignora toques.

## 3. Termos de uso (conteúdo fixo, traduzido)

| Item | Chaves de texto |
|---|---|
| Título | `settings_terms` |
| Frase na lista das Configurações | `settings_terms_sub` |
| Data | `settings_terms_updated` |
| 5 assuntos (ícone, título, texto) | `settings_terms_{about,limits,account,use,data}_{title,body}` |
| Link do último assunto | `settings_terms_see_privacy` |

Ícones (Lucide): `info`, `triangleAlert`, `keyRound`, `circleCheck`, `shieldCheck`. A lista
completa das chaves, com os textos, está em [contracts/ui-contract.md](contracts/ui-contract.md).
