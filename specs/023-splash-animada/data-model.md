# Data Model — 023 Splash animada

Sem dados persistidos novos. Os "modelos" são estados de tela.

## SplashDestination (inalterado)

`onboarding` | `login` | `home` — regra da feature 004, decidida pelo `SplashController`.

## Fases da splash (estado derivado do progresso `t` ∈ [0, 1] do controlador de 1 800 ms)

| Estado | Condição | Na tela |
|---|---|---|
| `toque` | t < 0,22 | fundo `background`, toque `primary` pulsando |
| `mancha` | 0,11 ≤ t < 0,39 | mancha `primary` cresce até cobrir a tela |
| `marca` | 0,28 ≤ t < 0,64 | escudo se desenhando em `background`, idoso subindo |
| `onda` | 0,61 ≤ t < 0,86 | `primary` escorre; logo `background` acima da borda, `primary` abaixo |
| `final` | t = 1 | logo `primary`, título, frase, onda `primary-glow`/`primary` no rodapé |
| `respirando` | t = 1 e destino ainda não decidido | igual a `final`, logo em escala 1 ↔ 1,035 |

Transições: `toque → … → final` uma vez; `final → respirando` só se a validação não terminou;
`final|respirando → saída` (esmaecimento) quando animação e validação terminaram.
Com movimento reduzido: começa e fica em `final` (sem `respirando`).

## BrandMark (logo em código)

| Campo | Tipo | Regra |
|---|---|---|
| `color` | cor | `context.colors.primary` por padrão |
| `strokeProgress` | 0–1 | 1 = escudo completo; o traço cresce do topo pelas duas laterais |
| `elderProgress` | 0–1 | 1 = idoso no lugar; < 1 desloca para baixo dentro do recorte do escudo |

Paths: os do `assets/branding/click_seguro_logo.svg`, `viewBox` `88 440 444 492`.
