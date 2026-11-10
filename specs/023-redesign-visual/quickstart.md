# Quickstart: validar o redesign visual 2.0

**Feature**: [spec.md](spec.md) · Figma:
[Click Seguro · Redesign 2.0](https://www.figma.com/design/jr3QeiIsXvuWqJirZFFdYf)

## Pré-requisitos

- Branch `023-redesign-visual`, com `flutter pub get` em `click_seguro_app/`.
- Um aparelho Android (ou emulador) e a URL da API de desenvolvimento (`--dart-define=API_URL=...`;
  a primeira resposta pode demorar uns 40 s, porque o servidor acorda).
- O Figma aberto ao lado, para comparar quadro a quadro.

## Verificação automática

```bash
cd click_seguro_app
flutter analyze     # sem erros nem warnings; infos no máximo iguais às do develop
flutter test        # todos verdes
flutter build web   # continua compilando
```

## Conferência no aparelho

Para cada passo, compare com o quadro indicado do Figma. Divergências de conteúdo que a spec manda
manter (FR-012) não contam como erro.

1. **Primeira abertura** (apague os dados do app): splash (quadro 01) → onboarding nos 3 slides
   (02) → login (03): logo oficial e nome "Click Seguro". Confira o botão "Ouvir" no onboarding.
2. **Barra inferior**: passe pelas cinco abas. Em cada uma, só a aba atual tem a pílula coral e o
   rótulo em negrito, e "Notícias" abre os Reels como antes (SC-007).
3. **Início** (04):
   - saudação, busca, chips;
   - "Novidades" em carrossel, "Destaques" grandes, "Recomendadas" e "Tudo recente" em 2 colunas;
   - uma notícia sem imagem mostra a capa ilustrada.
4. **Notícia** (05): capa com botões flutuantes, reprodutor de áudio e "Pratique o que aprendeu"
   com o cartão de módulo.
5. **Atividades** (06–09):
   - o painel mostra o anel enchendo e os cartões com ilustração por tema;
   - responda uma pergunta certa (check com mola) e uma errada (balanço e lâmpada);
   - termine o módulo (confete e placar contando).
6. **Assistente** (10): três abas em pílula, balões e cartão de análise.
7. **Ajuda** (11): o cartão "Caiu em um golpe?" no topo; "Ligar para 190" abre o discador com 190.
8. **Estados** (13–16):
   - modo avião nas Atividades: faixa e "sem internet";
   - API fora: erro;
   - notícias salvas sem nada: vazio;
   - primeira carga lenta: brilho e aviso azul.
9. **Perfil**: mesmo layout de antes, com os botões, cartões e listas novos.
10. **Acessibilidade**:
    - fonte no maior nível: nada cortado e a grade do Início em 1 coluna (SC-003);
    - alto contraste: componentes e ilustrações em preto, branco e vermelho escuro (SC-002);
    - liga "Reduzir animações": repetir os passos 5 e 8 sem nenhum movimento (SC-004);
    - desliga e liga o "Remover animações" do Android: mesmo resultado.
11. **Inglês**: troque o idioma do aparelho para inglês dos EUA e confira o cartão de emergência e o
    interruptor traduzidos, sem textos cortados.

## Resultado esperado

Todos os passos ok. Mudanças de comportamento achadas no aparelho viram clarificação na spec, como
nas features anteriores, e só então as tarefas são marcadas e o PR é aberto.
