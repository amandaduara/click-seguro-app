# Quickstart: Tela de Acessibilidade

**Feature**: [spec.md](spec.md) · **Plan**: [plan.md](plan.md) · **Contrato**:
[contracts/accessibility-ui.md](contracts/accessibility-ui.md)

## 1. Testes automáticos

Em `click_seguro_app/`:

```bash
flutter analyze
flutter test test/modules/settings test/modules/shell test/modules/profile test/accessibility_app_test.dart
flutter test
```

Esperado: `analyze` sem avisos e a suíte toda verde, incluindo `accessibility_page_test.dart`
(tela → app → gravação → próxima abertura, sobre o `FakeLocalCacheService`) e os grupos do
visitante de `settings_page_test.dart`, `app_top_bar_test.dart` e `profile_page_test.dart`.

## 2. No aparelho

```bash
flutter run --dart-define=API_URL=<url de dev>
```

O servidor de desenvolvimento pode levar ~40 s para acordar; a tela de Acessibilidade não depende
dele.

### Com conta

1. Início › engrenagem › **Acessibilidade**: abre a tela nova (não o "Em breve"), com "Padrão",
   contraste e leitura automática desligados e velocidade "Normal" marcados.
2. Tocar em **Muito grande**: a prévia e a tela crescem na hora; a opção fica marcada.
3. Voltar: Configurações e Início estão com a letra grande. Rolar a tela de Acessibilidade de novo:
   nada cortado, tudo tocável.
4. Ligar **Alto contraste**: a tela e o app mudam de cores na hora. Desligar: voltam.
5. Ligar **Ler automaticamente**, voltar e abrir uma notícia: a leitura começa sozinha.
6. Escolher **Lenta** e tocar "Ouvir" numa notícia: lê devagar.
7. Deixar "Maior", alto contraste ligado e "Lenta"; **fechar o app** (tirar da lista de recentes) e
   abrir: o splash já aparece grande e em alto contraste; a tela mostra as três escolhas.
8. Com a letra do celular aumentada nas configurações do sistema + "Muito grande": a tela continua
   rolável e utilizável.
9. Com TalkBack: cada opção anuncia o nome e "selecionado"/"não selecionado"; as chaves anunciam
   "ligado"/"desligado".
10. Trocar o idioma para **English**: todos os textos da tela aparecem em inglês.
11. Modo avião: a tela abre e as escolhas funcionam.

### Visitante

12. Sair da conta e entrar como visitante: a engrenagem aparece no topo do Início, de Atividades,
    da Ajuda e do Perfil.
13. Engrenagem: só **Leitura e aparência** (Acessibilidade, Idioma) e **Sobre** (Privacidade, Sobre o
    SafeNews). Sem cartão, sem Conta, sem Alertas, sem "Sair", sem convite.
14. Acessibilidade como visitante: as escolhas valem e continuam iguais depois de entrar numa conta.
15. Idioma como visitante: o app muda na hora.
16. O visitante não tem caminho até "Alterar senha" na interface; o convite com o texto novo
    ("Para trocar a senha, entre na sua conta.") é conferido só no teste da `ChangePasswordPage`.

### Sessão expirada

17. Com conta, abrir as Configurações e forçar a sessão a expirar (por exemplo, apagar a sessão no
    servidor ou esperar o token vencer): a tela passa para a lista do visitante, sem erro.
