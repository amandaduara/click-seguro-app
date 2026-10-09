# Quickstart: validar a acessibilidade global no emulador

## Automatizado

```bash
cd click_seguro_app
flutter analyze
flutter test
```

## No emulador

1. `flutter run -t lib/dev/accessibility_playground.dart` (app real + botão de acessibilidade de
   desenvolvimento).
2. **Padrão** (SC-001): primeira abertura com o armazenamento limpo → splash, login e Início com
   letra e cores normais.
3. **Letra** (US1, FR-002/FR-006): no painel, trocar para 115%, 130% e 150% com o Início aberto →
   o texto cresce na hora. Voltar a 100%.
4. **Escala do sistema** (US1 cenário 2, FR-004): Configurações do Android → Tamanho da fonte no
   máximo; no app, 150% → texto maior, mas sem passar de 2× (telas usáveis).
5. **Alto contraste** (US3): ligar → fundo branco, texto preto, botões vermelho-escuro, bordas
   pretas em login, Início, abas, convite de conta. Desligar → volta.
6. **Lembrar** (US2, RF-041): deixar 150% + alto contraste, fechar o app (tirar dos recentes) e
   abrir pelo ícone → o splash já aparece com letra grande e alto contraste.
7. **Conta** (FR-010): sair da conta / entrar como visitante → preferências mantidas.
8. **Telas no nível máximo** (SC-004): 150% + escala do sistema alta → splash, onboarding, login,
   Início, abas: nada cortado sem rolagem, botões alcançáveis.

Prints em `evidencias/` e relatório em [evidencias/relatorio-de-teste.md](evidencias/relatorio-de-teste.md).
