# Contrato: tela de Acessibilidade e Configurações do visitante

**Feature**: [../spec.md](../spec.md) · **Plan**: [../plan.md](../plan.md)

Sem endpoints: nada desta feature chama a API.

## 1. Rotas

| Caminho | Navegador | Tela | Muda? |
|---|---|---|---|
| `/settings` | raiz | `SettingsPage`: lista com conta **ou lista do visitante** (antes: convite) | sim |
| `/settings/accessibility` | raiz | `AccessibilityPage` (antes: `SettingsSectionPage` provisória) | sim |
| `/settings/security` | raiz | `ChangePasswordPage` (sem conta: convite) | só o texto do convite |
| `/settings/privacy`, `/settings/about` | raiz | sem mudança | não |

A `SettingsSectionPage` fica sem uso depois desta troca e é **removida**.

## 2. Entradas para as Configurações

| Lugar | Antes (feature 013) | Depois |
|---|---|---|
| `AppTopBar` (Início, Atividades, Ajuda) | engrenagem só com conta | engrenagem sempre → `push('/settings')` |
| `ProfilePage` (`_Header`) | engrenagem só com conta | engrenagem sempre → `push('/settings')` |

## 3. Conteúdo das Configurações por estado da sessão

| Item | Com conta | Visitante |
|---|---|---|
| Cartão da conta | ✅ | — |
| Conta: Dados pessoais, Alterar senha | ✅ | — |
| Alertas: chave | ✅ | — |
| Leitura e aparência: Acessibilidade, Idioma | ✅ | ✅ |
| Sobre: Privacidade, Sobre o SafeNews (com versão) | ✅ | ✅ |
| "Sair da conta" + frase dos contatos | ✅ | — |
| Convite para entrar | — | — |
| Pedido ao serviço ao abrir | `GET /users/me` | **nenhum** |

## 4. Tela de Acessibilidade (ordem de cima para baixo)

```text
AppBar: "Acessibilidade" (voltar)
─ Tamanho da letra ───────────────────────────
  [cartão de prévia: título + frase]
  ( ) Padrão ...................... 100%
  ( ) Grande ...................... 115%
  ( ) Maior ....................... 130%
  ( ) Muito grande ................ 150%
─ Aparência ──────────────────────────────────
  [ícone] Alto contraste                 [chave]
          Cores mais fortes para ler melhor
─ Leitura em voz alta ────────────────────────
  [ícone] Ler automaticamente            [chave]
          Ao abrir uma notícia, o app começa a ler sozinho
  Velocidade da voz
  ( ) Lenta  ( ) Normal  ( ) Rápida   (uma linha cada)
```

| Toque | Chamada | Efeito visível |
|---|---|---|
| nível de letra | `AccessibilityController.setFontScale(level)` | opção marcada; app e prévia mudam de tamanho |
| chave de contraste | `setHighContrast(!atual)` | tema de alto contraste no app inteiro |
| chave de leitura | `setAutoReadAloud(!atual)` | próxima notícia aberta lê (ou não) sozinha |
| velocidade | `setReadingSpeed(speed)` | opção marcada; próxima leitura usa a velocidade |

Toda a tela rola (`ListView`). Linhas com altura mínima 64 dp e alvo de toque ≥ 48 dp; a linha
inteira é tocável. Semântica: opções anunciam "selecionado"; chaves anunciam "ligado/desligado".

## 5. Interface do módulo `settings`

Sem mudança no barrel `settings.dart` além do que já exporta. A `SettingsController` ganha
`loadDeviceSettings()` (data-model §2). Os widgets novos são internos ao módulo.
