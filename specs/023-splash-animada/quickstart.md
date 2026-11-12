# Quickstart — validar a 023

Pré-requisitos: Flutter 3.47.x; emulador `fuja_api36` (ver memória do projeto); para regenerar
imagens, WSL Ubuntu com `libcairo2` e `librsvg2` (já instalados) e Pillow num venv temporário.

## Testes

```bash
cd click_seguro_app
flutter analyze
flutter test test/core/widgets test/modules/splash test/modules/authentication/presentation/widgets
flutter test
```

Esperado: tudo verde; inclui (a) navegação só depois de 1 800 ms com destino pronto, (b)
navegação imediata com movimento reduzido, (c) respiração enquanto a validação demora, (d)
`AppLogo` na cor `primary` do tema (normal e alto contraste), (e) nenhum `C0503E` no SVG.

## Regenerar as imagens da marca

```bash
wsl -d Ubuntu -- bash -lc 'python3 -m venv /tmp/brandvenv && /tmp/brandvenv/bin/pip -q install pillow && cd "<repo>/click_seguro_app" && /tmp/brandvenv/bin/python tools/generate_brand_assets.py'
```

Esperado: ícones Android/iOS/web e `assets/branding/click_seguro_logo.png` em `#FE3152`.

## No aparelho

1. `flutter run` no emulador, abrir a frio: toque → mancha → escudo → onda → logo vermelho,
   nome e frase; chega à tela certa em ~2 s.
2. Configurações → Acessibilidade → "Reduzir animações": abrir de novo; estado final direto.
3. Alto contraste: logo e mancha em `#9E0019`.
4. Gravar a tela na abertura: só fundo claro antes do toque vermelho (sem logo estático).
5. Conferir o ícone do app na tela inicial e o logo no login e em "Sobre".
