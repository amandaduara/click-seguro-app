# Quickstart: Painel de atividades

**Feature**: [spec.md](spec.md) · **Plan**: [plan.md](plan.md) · **Contrato**:
[contracts/activities-dashboard.md](contracts/activities-dashboard.md)

## 1. Testes automáticos

Em `click_seguro_app/`:

```bash
flutter analyze
flutter test test/modules/activities test/modules/common test/modules/authentication test/modules/profile
flutter test
```

Esperado: `analyze` sem avisos novos e a suíte toda verde, incluindo o `GuestProgressStore` com a
sessão de verdade, a transferência no repositório e a página nos dois layouts.

## 2. No aparelho

```bash
curl https://clickseguro-api.onrender.com/          # acorda o servidor (~40 s)
flutter run --dart-define=API_URL=https://clickseguro-api.onrender.com/api/v1
```

### Com conta

1. Aba **Atividades**: aparece "Seu progresso" ("X de 9 lições concluídas") e os três módulos, na
   ordem: Golpes Digitais, Golpes no WhatsApp, Fake News, com ícone, descrição e selo.
2. Letra do celular e do app no normal: os cartões ficam em **duas colunas**, descrição até 3
   linhas; o terceiro cartão fica sozinho, com meia largura.
3. Configurações › Acessibilidade › "Grande": voltando, os cartões ficam em **uma coluna**, com a
   descrição inteira. "Muito grande" + letra do celular no máximo: tudo legível e tocável.
4. Tocar num cartão: abre a tela do módulo (ainda "Em breve", B2). Dois toques rápidos abrem uma
   vez só. Voltar: o painel recarrega sem mostrar "carregando".
5. Trocar para outra aba e voltar: recarrega.
6. Modo avião + "Tentar novamente": mensagem de erro; desligar o modo avião e tocar: carrega.
7. Abrir a aba com o servidor dormindo: "carregando" e, depois de 5 s, o aviso de servidor
   acordando.
8. Alto contraste ligado: cartões, selos e barra legíveis.
9. TalkBack: cada cartão é lido como um item (título, status, progresso, descrição) e anunciado
   como botão.
10. Idioma English: textos do app em inglês; títulos e descrições dos módulos em português.

### Visitante

11. Sair e entrar como visitante: o aviso "Sem conta, seu progresso vale até fechar o app." com
    "Entrar ou criar conta" aparece acima dos cartões; módulos com "0 de 3 lições".
12. "Entrar ou criar conta" leva à tela de entrar.

A gravação de respostas do visitante só existe a partir da B3; até lá, a transferência
(progresso do visitante indo para a conta criada) e o painel do visitante com lições feitas são
conferidos pelos testes automáticos.

## 3. Conferência no servidor

Feita no plano (R0 do [research](research.md)); não precisa ser repetida.
