# Quickstart: Resposta e feedback das atividades

**Feature**: [spec.md](spec.md) · **Plan**: [plan.md](plan.md) · **Contrato**:
[contracts/lesson-answer.md](contracts/lesson-answer.md)

## 1. Testes automáticos

Em `click_seguro_app/`:

```bash
flutter analyze
flutter test test/modules/activities
flutter test
```

Esperado: `analyze` sem avisos novos; suíte verde, inclusive os testes da B1 (painel e
transferência do visitante) com o `recordAnswer` novo.

## 2. No aparelho

```bash
curl https://clickseguro-api.onrender.com/          # acorda o servidor (~40 s)
flutter run --dart-define=API_URL=https://clickseguro-api.onrender.com/api/v1
```

**Como visitante** (Atividades › "Golpes Digitais"):

1. Tocar numa alternativa: fica marcada; "Confirmar resposta" ativa. Tocar em outra: a marcação
   muda.
2. Confirmar a **errada**: em cerca de 2 s (servidor acordado, SC-001) o painel sobe com "Não foi dessa vez", a correta e a explicação; nas
   alternativas, a escolhida aparece como errada e a correta como correta.
3. Tocar fora do painel e tentar arrastar: ele não fecha. Voltar do aparelho: fecha; a pergunta
   mostra o resultado; "Próxima" ativa; o rodapé mostra "Responder de novo".
4. "Responder de novo" → escolher a correta → confirmar: "Você acertou!" e "Você está com 1 de 3
   acertos".
5. "Próxima pergunta" até a última; na última, "Voltar às atividades" leva ao painel com o módulo
   "Concluído" (3 de 3).
6. Reabrir o módulo: as perguntas aparecem concluídas, sem marcação; dá para responder de novo.

**Com conta** (conta de teste, ou criar uma com permissão):

7. Responder uma pergunta: a pontuação do painel é a do serviço; voltar ao painel mostra o
   progresso novo; fechar e abrir o app mantém.
8. Visitante que responde e **cria conta** sem fechar o app: o painel da conta nova mostra as
   respostas (transferência da B1, agora com o registro da B3).

**Acessibilidade e erros**:

9. Leitura automática ligada: ao confirmar, a leitura da pergunta para e o feedback é lido
   (resultado, correta, explicação e pontuação); "Próxima pergunta" lê a nova pergunta.
10. Modo avião antes de confirmar: mensagem de falha; a alternativa continua marcada; voltar a
    rede e confirmar funciona.
11. Letra "Muito grande" + alto contraste: alternativas, rodapé e painel legíveis e roláveis;
    correta e errada distinguíveis sem cor.
12. Idioma English: botões e painel em inglês; alternativas e explicação em português.
