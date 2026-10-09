# Quickstart: validar os Reels

Pré-requisitos: Flutter com Dart ≥ 3.11.3, aparelho ou emulador Android, servidor de
desenvolvimento acordado (abra `https://clickseguro-api.onrender.com/api/v1/app/news/reels` no
navegador e espere responder) e uma conta de teste do time.

## 1. Testes automáticos

```bash
cd click_seguro_app
flutter analyze
flutter test test/modules/news
flutter test
```

Esperado: nenhum erro/aviso novo; toda a suíte verde (models, datasource, repository, usecases,
`ReelsController`, extension e widget tests da `ReelsPage`).

## 2. Visitante (US1, US4, SC-004)

`flutter run` → "Entrar como visitante" → aba **Notícias**.

- Primeiro Reel em tela cheia; arrastar para cima/baixo e usar as setas.
- Passar do 7º Reel: a 2ª parte chega (12 Reels hoje no servidor); no último, "Você viu todas
  as notícias" e a seta "Próxima" desabilitada.
- Tocar no coração e no marcador → convite para entrar; nada muda.
- "Abrir fonte" → navegador externo; voltar ao app no mesmo Reel.
- "Ler notícia completa" → detalhe (provisório); voltar no mesmo Reel.

## 3. Carrossel do Início (FR-004)

Aba Início → tocar no 3º cartão de "Novidades" → a aba Notícias abre nesse Reel; arrastar para
baixo leva ao 2º.

## 4. Conta (US2, US3) — conferir o contrato 🧪

Entrar com a conta de teste → aba Notícias.

- Curtir: coração preenche e a contagem sobe na hora; tocar de novo desfaz.
- Salvar: marcador preenche e aparece "Notícia salva"; tocar de novo, "Removida dos salvos".
- Fechar e reabrir o app: o marcador continua como ficou (vem do servidor).
- Se like/save responderam como no [contrato](contracts/reels.md), trocar 🧪 por ✅ no
  `api-contract.md`.

## 5. Falhas

- Modo avião na aba recém-aberta → erro com "Tentar novamente"; religar e tocar → carrega.
- Modo avião com Reels carregados → curtir: coração volta e aparece a mensagem de sem conexão.

## 6. Acessibilidade

TalkBack ligado: passar por 5 Reels só com as setas; cada botão anuncia rótulo e estado. Fonte
do sistema no máximo: nada sobreposto.
