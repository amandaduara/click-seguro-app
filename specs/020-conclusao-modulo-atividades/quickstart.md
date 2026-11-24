# Quickstart: Conclusão do módulo e aviso de login

**Feature**: [spec.md](spec.md) · **Plan**: [plan.md](plan.md) · **Contrato**:
[contracts/completion-flow.md](contracts/completion-flow.md)

## 1. Testes automáticos

Em `click_seguro_app/`:

```bash
flutter analyze
flutter test test/modules/activities test/modules/authentication
flutter test
```

Esperado: `analyze` sem avisos novos; suíte verde, inclusive o login (003) sem parâmetros.

## 2. No aparelho

```bash
curl https://clickseguro-api.onrender.com/          # acorda o servidor (~40 s)
flutter run --dart-define=API_URL=https://clickseguro-api.onrender.com/api/v1
```

**Como visitante** (Atividades › "Golpes Digitais"):

1. Responder as 3 perguntas. Na última, o painel mostra "Ver resultado".
2. "Ver resultado" → aviso "Guarde seu progresso" com "Criar conta" e "Continuar sem conta".
3. "Continuar sem conta" → conclusão: "Módulo concluído!", "Você acertou X de 3" e a mensagem
   conforme o resultado.
4. "Compartilhar" → menu do aparelho com o texto pronto; cancelar volta sem aviso.
5. "Refazer o módulo" → primeira pergunta; responder de novo até o fim → aviso de novo →
   conclusão com a pontuação nova.
6. Na conclusão, voltar do aparelho → painel de atividades com o módulo concluído.
7. Terminar de novo, "Criar conta" → tela de login já em "Criar conta"; voltar sem cadastrar →
   conclusão (ainda visitante).
8. Terminar de novo, "Criar conta" e cadastrar uma conta nova (com permissão; senha não guardada)
   → abre a aba Atividades com o módulo concluído na conta nova.

**Com conta**:

9. Terminar um módulo → conclusão direto (sem aviso), com a pontuação do serviço.

**Acessibilidade**:

10. Leitura automática ligada → a conclusão é lida sozinha (título, pontuação e mensagem).
11. Letra "Muito grande" + alto contraste → aviso e conclusão legíveis, roláveis e tocáveis.
12. Idioma English → aviso, conclusão e texto compartilhado em inglês.
