# Verificação do assistente — 2026-10-20

## Revalidação do review — 2026-10-22

- 67 testes direcionados de Assistente, barra, SafeBadge e proteção dos logs passaram;
  40 regressões de rotas, shell e Sobre passaram. Comandos completos em `../tasks.md`.
- Análise estática sem erros ou warnings, com 27 infos fora da feature; formatação e diff válidos.
- APK debug recompilado e instalado com `adb install -r` no Pixel_4, preservando os dados.
- Em sessão visitante já existente, o Início apresentou as três ações ao lado do título
  com fonte padrão ([captura](review-barra-padrao.png)). Tocar no Assistente abriu o
  `AccountRequiredSheet` padrão ([captura](review-convite-padrao.png)).
- Fonte do sistema temporariamente em 200%: as ações passaram para a segunda linha,
  sem estouro do cabeçalho ([captura](review-barra-fonte-200.png)). Escala restaurada a 1.0.
- Operações reais de IA autenticadas e permissões/seletor de imagem reais continuam pendentes;
  a revalidação manual acima usou a sessão visitante, sem enviar conteúdo à IA.

## Resultado

APK debug compilado e instalado no Pixel_4, preservando os dados. Uma corrida no
histórico foi reproduzida por teste e corrigida: uma resposta antiga de histórico
não apaga mais a necessidade de atualização após chat ou análise concluídos.

## Emulador, interação manual

- Home carregou notícias do servidor; navegação para Assistente, Ajuda e Perfil funcionou.
- A sessão salva expirou durante a consulta ao servidor. O app mostrou o aviso e
  passou ao estado de visitante; o Assistente apresentou apenas o convite de entrada.
- Fonte do sistema em 200%: cabeçalho e convite de entrada se adaptaram com quebra
  de linhas. Evidência: `visitante-fonte-200.png`. Fonte restaurada para 1.0.
- Perfil mostrou o convite de autenticação. Ajuda mostrou o placeholder esperado
  nesta branch; a B6 está na PR #20, ainda separada.
- APK recompilado com a correção do histórico e instalado com `adb install -r`.

## Automação adversarial

- 56 testes passaram: módulo Assistant, proteção dos logs de IA e cabeçalho.
- 12 testes do controller passaram, incluindo envio duplicado e resposta de
  histórico em trânsito durante conclusão de chat ou análise.
- A suíte de apresentação cobre entrada explícita, visitante, filtros, falhas,
  resultados desconhecidos/nulos e layout a 320 px com fonte 200% e alto contraste.

## Pendente de autenticação

Foi solicitado login manual com uma conta de teste. Não foram enviados chat,
texto ou imagem aos endpoints reais de IA. Teclado, seletor/permissões de imagem,
falhas de rede e paginação reais no emulador continuam pendentes. A cobertura com
serviços simulados não substitui essa verificação. Nenhuma credencial foi extraída.
