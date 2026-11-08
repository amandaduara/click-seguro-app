# Quickstart: validar a feature 022

## Pré-requisitos

- Flutter 3.47+ e Android Studio atual (o JDK dele é usado pelo Flutter).
- Emulador Android, por exemplo `fuja_api36` (Android 16).

## Rodar

```sh
cd click_seguro_app
flutter pub get
flutter emulators --launch fuja_api36
flutter run -d emulator-5554            # debug, com hot reload
flutter run -d emulator-5554 --profile  # medir fluidez (DevTools → Performance)
```

Se o `flutter run` falhar com "incompatibility between Java and Gradle", o toolchain da Fase 0
não foi aplicado (ver research R14).

Se a instalação terminar mas o app não abrir ("Activity class does not exist"), espere alguns
segundos ou reinicie o emulador. É um estado transitório do gerenciador de pacotes do Android 16
logo depois de `adb install`.

## Testes automatizados

```sh
flutter analyze
flutter test
```

## Roteiro manual (no emulador)

| # | Passo | Esperado | Spec |
|---|---|---|---|
| 1 | Abrir o app | Logo entra suave; Início chega com esmaecimento; texto em Montserrat | FR-001, FR-018 |
| 2 | Puxar o feed para atualizar | Cartões continuam na tela; um só indicador | FR-002 |
| 3 | Trocar de categoria rápido 3× | Lista esmaece e troca uma vez, sem sumir | FR-002, edge |
| 4 | Abrir notícia pelo feed | Título e imagem na hora; Hero da imagem | FR-017 |
| 5 | Voltar | Cartão com selo "lida" | FR-005 |
| 6 | Sair e entrar com outra conta | Feed recarrega sem marcas antigas | FR-004 |
| 7 | Tocar nas abas | Fade-through; rolagem preservada | FR-016 |
| 8 | Tocar o topo do círculo central | Abre Reels | FR-006 |
| 9 | Tocar um Reel no carrossel | Imagem já visível ao chegar | FR-019 |
| 10 | Deslizar Reels; curtir; dois toques | Sem tela preta; coração pulsa; vibra | FR-021, FR-030 |
| 11 | Responder pergunta certa e errada | Destaque + vibração distinta; próxima entra de lado | FR-022, FR-027 |
| 12 | Login: alternar Entrar/Criar conta | Campos entram/saem suave | FR-023 |
| 13 | Gesto de voltar numa tela empilhada | Prévia da tela anterior | FR-015 |
| 14 | Acessibilidade → Reduzir animações; repetir 1–13 | Nada desliza, aumenta ou brilha | FR-010 |
| 15 | Servidor frio (primeira abertura do dia) | Esqueletos + aviso de lentidão após 5 s | FR-011, FR-014 |
| 16 | TalkBack nos botões e cartões | Anunciados como botão | FR-007 |
