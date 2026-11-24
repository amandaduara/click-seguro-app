# Quickstart: validar o padrão de sem internet

## Automático

```bash
cd click_seguro_app
flutter analyze
flutter test
```

Esperado: sem erros no analyze (1 info de base) e a suíte inteira verde.

## No aparelho

Pré-requisito: app instalado com `--dart-define=API_URL=…` (servidor de dev) e uma conta de
teste. Abra cada tela uma vez **com** internet antes, para o Início e os Alertas terem cópia.

### US1: tela sem conteúdo (modo avião)

1. Atividades: nuvem, "Sem conexão com a internet. Verifique sua rede." e "Tentar novamente".
2. Abrir Atividades com internet, ligar o modo avião e tocar num módulo: a lição mostra o mesmo
   estado.
3. Reels: mesmo estado, com a frase **branca e legível** no fundo preto.
4. Perfil, Central de ajuda e uma notícia nunca aberta: o mesmo estado.
5. Desligar o modo avião e tocar em "Tentar novamente": a tela carrega.

### US2: ação com a tela aberta

6. Abrir uma lição com internet, escolher a resposta, ligar o modo avião e confirmar: aviso
   "Sem conexão…" e a resposta continua marcada.
7. Trocar senha preenchida, modo avião, salvar: aviso "Sem conexão…", campos mantidos.
8. Editar perfil: salvar e trocar a foto em modo avião: aviso "Sem conexão…".
9. Configurações: mexer na chave dos alertas em modo avião: a chave volta e a linha diz "Sem
   conexão…" com o botão de tentar de novo.
10. Início: rolar até o fim com o modo avião ligado no meio: o rodapé diz "Sem conexão…".
11. Login em modo avião: a frase aparece embaixo dos campos (como antes).

### US3: conteúdo guardado

12. Início em modo avião: faixa azul "Você está sem internet. Mostrando o conteúdo salvo." e as
    notícias guardadas.
13. Alertas em modo avião, com alertas na lista: a mesma faixa. Sem nenhum alerta: "Você está sem
    internet." só.

### Regressão (internet ligada)

14. Telas e ações acima funcionando normalmente; nenhuma diz "sem conexão".
15. App em inglês: repetir os passos 1, 6 e 13 e conferir as frases traduzidas.
