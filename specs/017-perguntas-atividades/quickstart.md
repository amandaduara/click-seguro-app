# Quickstart: Perguntas do módulo de atividades

**Feature**: [spec.md](spec.md) · **Plan**: [plan.md](plan.md) · **Contrato**:
[contracts/lesson-page.md](contracts/lesson-page.md)

## 1. Testes automáticos

Em `click_seguro_app/`:

```bash
flutter analyze
flutter test test/modules/activities test/modules/news test/core
flutter test
```

Esperado: `analyze` sem avisos novos; suíte verde, inclusive o detalhe da notícia com o
`ListenButton`.

## 2. No aparelho

```bash
curl https://clickseguro-api.onrender.com/          # acorda o servidor (~40 s)
flutter run --dart-define=API_URL=https://clickseguro-api.onrender.com/api/v1
```

Como responder só chega na B3, use a conta de teste com respostas (ou qualquer conta que já tenha
respondido pelo serviço) para conferir a navegação; como visitante, confira a primeira pergunta.

1. Atividades › "Golpes Digitais": abre "Pergunta X de 3" na primeira não respondida, com imagem,
   enunciado e as alternativas numeradas.
2. Marcas de progresso: as respondidas com check, a atual destacada.
3. "Próxima" desativado numa pergunta não respondida; ativo numa respondida (exceto na última).
4. "Anterior" até a primeira; volta a "Próxima" até a primeira não respondida.
5. "Ouvir": lê o enunciado e as alternativas; vira "Parar"; "Parar" interrompe.
6. Acessibilidade › "Ler automaticamente" ligado: cada pergunta começa a ser lida sozinha, uma vez;
   trocar de pergunta para a anterior e lê a nova.
7. Acessibilidade › "Lenta": a leitura fica lenta.
8. Modo avião ao abrir um módulo: erro com "Tentar novamente".
9. Letra "Muito grande" + alto contraste: tudo legível, rolável e tocável.
10. Idioma English: botões e "Question X of 3" em inglês; enunciado em português.
11. Voltar ao painel: recarrega sem "carregando".
12. Detalhe de uma notícia: o "Ouvir" continua igual (mesmo botão, agora compartilhado).
