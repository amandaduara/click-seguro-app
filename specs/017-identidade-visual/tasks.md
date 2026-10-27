# Identidade visual do Click Seguro

**Prioridade máxima**, solicitada pelo usuário em 27/10/2026.
Branch: `feat/click-seguro-branding-states`, criada a partir do trabalho local
do Assistente de IA. A mudança não altera a integração da API.

## Implementação

- [x] Preservar o SVG oficial fornecido na raiz do PI, sem alterar seus paths,
  máscaras ou cor, e versionar uma cópia em `assets/branding/`.
- [x] Aplicar a logo oficial no login, splash Flutter e Sobre.
- [x] Gerar ícones Android tradicionais/adaptativos, iOS e web, além das imagens
  nativas de abertura; incluir script para reprodução sem acesso à rede.
- [x] Usar Click Seguro nos textos visíveis em português e inglês, nome instalado,
  metadados web, Assistente e guia de estilos. Preservar identificadores técnicos
  de pacote, rotas e dados de sessão.
- [x] Integrar ilustrações vetoriais estáticas aos componentes compartilhados de
  erro e vazio; manter texto, retry, ações opcionais, alto contraste e semântica.
- [x] Aplicar a ilustração também aos estados próprios de notícias: listas
  salvas/lidas/curtidas vazias e notícia não encontrada, preservando dicas,
  retorno ao Início e ausência de retry no 404.
- [x] Permitir rolagem em telas curtas com texto ampliado, incluindo splash.

## Validação inicial

- [x] 116 testes direcionados e regressões, em 15 arquivos: logo carregada,
  proporções e semântica; autenticação; splash em 320×480 e fonte 200%; traduções;
  configurações, Sobre e privacidade; estados compartilhados; Assistente e shell.
- [x] Análise com Flutter 3.47.6 / Dart 3.13.5: nenhum erro ou warning;
  permanecem 27 infos preexistentes, principalmente no guia de estilos.
- [x] Build web JavaScript aprovado, com PNG e SVG presentes no bundle.
- [x] AAPT2 compilou todos os recursos Android; dimensões de 29 ícones Android/iOS,
  opacidade dos ícones iOS, XMLs e JSONs conferidos. Cópia do SVG idêntica à origem.
- [x] AAPT2 vinculou os recursos com a plataforma Android 35 e confirmou o rótulo
  Click Seguro e o ícone adaptativo. Esse pacote contém somente recursos de
  validação, sem código do app, e não substitui o APK instalável.
- [x] Conferir visualmente a [prévia dos componentes reais](../../click_seguro_app/previews/click-seguro-branding-states.png).
- [ ] Gerar APK e validar ícone/abertura no aparelho: a primeira tentativa foi
  bloqueada pela gravação do lock do Gradle em `~/.gradle`, somente leitura.
  A tentativa com cache gravável em `/tmp/pi-app-gradle`, offline e sem daemon,
  superou esse lock, mas o Gradle não conseguiu criar seu serviço de controle
  de locks: `Could not determine a usable wildcard IP for this machine`.
  Não foi instalado um novo APK nesta rodada.
- [ ] Validar build e instalação iOS em macOS/Xcode.

## Evidências e método

Os testes foram executados diretamente no `flutter_tester` com o backend do
`test_api` (Declarer, Suite, Test.load), assertions habilitadas e assets reais.
Esse método evita o socket local exigido pelo runner padrão, proibido neste
ambiente; não equivale a uma execução bem-sucedida de `flutter test` pelo CLI.
As traduções e assets foram sincronizados no bundle temporário de testes.

Logs desta sessão: `/tmp/pi-app-brand-results.log`, `/tmp/pi-app-analyze.log`,
`/tmp/pi-app-web-build.log` e `/tmp/pi-app-apk-build.log`. A prévia foi renderizada
pelos widgets reais com dados ilustrativos, sem chamadas de rede.

O aviso do diagnóstico Wasm no build web não impediu a compilação JavaScript.
Nenhum teste realizou chamadas à API de produção. O SDK original permaneceu
intacto; arquivos de cache graváveis foram preparados em `/tmp`.

## Continuação — suíte completa e estados próprios de notícias

- **1.397 testes aprovados**, em 133 arquivos, sem falhas no resultado final:
  [resumo por arquivo](evidencias/test-summary.json).
- Cada arquivo foi executado em um processo separado do Flutter Tester para
  preservar o isolamento entre suites. Após a revisão, foram reexecutados os
  arquivos afetados: detalhe de notícia (50 testes), listas pessoais (22) e
  smoke do app (1). As contagens acima consideram a última rodada de cada
  arquivo, sem somar execuções repetidas.
- O smoke agora aguarda o splash ser montado antes de avançar os dois segundos
  do relógio falso; o atraso real fixo anterior era sensível ao carregamento
  dos assets. Ele verifica a marca Click Seguro e mantém a navegação pelas
  cinco abas.
- As páginas de notícias verificam a nova ilustração nas listas vazias e no
  404, incluindo viewport baixo com fonte 200%, sem overflow e sem retry no 404.
- Build web JavaScript e análise repetidos após as mudanças nas páginas:
  aprovados; permanecem os mesmos 27 infos, sem erros ou warnings.
- Logs adicionais: `/tmp/pi-app-isolated-progress.log`,
  `/tmp/pi-app-isolated-results/`, `/tmp/pi-app-news-detail-final.log`,
  `/tmp/pi-app-user-news-final.log`, `/tmp/pi-app-smoke-final.log`,
  `/tmp/pi-app-final-analyze.log`, `/tmp/pi-app-final-web-build.log` e
  `/tmp/pi-app-gradle-build.log`.
