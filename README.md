# Click Seguro - TCC

> Código-fonte do aplicativo mobile desenvolvido como projeto de Conclusão de Curso (TCC) para o curso de Análise e Desenvolvimento de Sistemas na FATEC.

---

## 🛠️ Stack Tecnológica & Pacotes Principais

O projeto foi construído utilizando o ecossistema **Flutter & Dart**, adotando ferramentas modernas que garantem alta performance, segurança e manutenibilidade.

| Ferramenta / Pacote | Função no Projeto |
| :--- | :--- |
| **Flutter & Dart** | Framework e Linguagem base do projeto |
| **GetIt** | Injeção de Dependências (Garante o desacoplamento do SOLID) |
| **Provider** | Estado reativo da UI (`ChangeNotifier` + `MultiProvider`) |
| **go_router** | Navegação declarativa por rotas (`GoRoute`, `context.go`) |
| **fpdart** | Programação funcional — `Either<Failure, T>` para tratamento de erro no domain layer, em vez de exceptions soltas |
| **shared_preferences** | Persistência local simples (ex: flag de "onboarding já visto") |
| **Dio** | Cliente HTTP avançado (Controle de Interceptors, rotas e timeouts) |
| **Lucide Icons** (`lucide_icons_flutter`) | Biblioteca moderna e minimalista de ícones vetoriais |
| **Flutter Secure Storage** | Armazenamento criptografado de dados sensíveis (Tokens JWT) |
| **Shimmer** | Esqueletos de carregamento visuais para otimizar a UX |
| **Flutter Localizations** (`easy_localization`) | Sistema oficial de suporte a internacionalização (i18n) |
| **Flutter SVG** | Biblioteca quer permite desenhar e exibir arquivos Scalable Vector Graphics |
| **Flutter Lints** | Pacote que fornece um conjunto recomendado de regras, visando incentivar boas práticas de programação e manter a consistência do código |

---

## 📐 Arquitetura do Projeto: DDD + SOLID

Para garantir que o projeto seja escalável, testável e que o desenvolvimento em equipe ocorra sem conflitos, adotamos o **DDD (Domain-Driven Design)** pragmático aliado aos princípios do **SOLID**. O aplicativo é dividido em **módulos independentes (Features)**, onde cada funcionalidade possui três camadas isoladas:

```text
assets/
├── images/                       # Onde ficam as ilustrações (ex: empty_state.svg, logo.svg)
├── translations/                 # Arquivos de i18n (pt-BR.json, en-US.json)
lib/
├── core/                         # Código compartilhado globalmente
│   ├── constants/                # Caminhos de imagens, rotas fixas, chaves
│   ├── errors/                   # Failure (classe base) e subclasses (ex: CacheFailure)
│   ├── http/                     # Configuração do Dio e Interceptors de API
│   ├── i18n/                     # Chaves de tradução (AppStrings) e internacionalização
│   ├── routing/                  # Configuração do go_router (rotas do app)
│   ├── theme/                    # Design System (Cores, fontes e espaçamentos)
│   └── widgets/                  # Componentes puramente visuais e globais
│
└── modules/                      # Módulos/Funcionalidades independentes
    └── [nome_do_modulo]/         # Exemplo: onboarding, splash, authentication
        ├── data/                 # CAMADA DATA: Conexão com infraestrutura externa
        │   ├── datasources/      # Requisições HTTP brutas para a API
        │   ├── models/           # Mapeamento e serialização de/para JSON
        │   └── repositories/     # Implementações concretas dos contratos do Domain
        │
        ├── domain/               # CAMADA DOMAIN: Regras de Negócio Puras (Dart)
        │   ├── entities/         # Objetos de negócio puros
        │   ├── repositories/     # Contratos/Interfaces (Classes abstratas)
        │   └── usecases/         # Ações isoladas do usuário (Responsabilidade Única)
        │
        └── presentation/         # CAMADA PRESENTATION: Interface com o Usuário
            ├── controller/       # Gerência de estado e lógica de tela (ChangeNotifier)
            ├── pages/            # Telas completas da feature
            └── widgets/          # Componentes visuais exclusivos desta tela
```

> `data/` e `domain/` só existem em módulos com regra de negócio ou acesso a dados reais (ex: `onboarding`, que lê/escreve em `shared_preferences`). Um módulo puramente de bootstrap, como `splash`, pode ter só `presentation/` e consumir o domain de outro módulo.

### Tratamento de erro: `Either<Failure, T>`

Repositories e usecases não lançam exceptions para cima — eles retornam `Either<Failure, T>` (pacote [`fpdart`](https://pub.dev/packages/fpdart)). `Failure` é a classe base em `core/errors/failure.dart`; subclasses (ex: `CacheFailure`) representam falhas concretas. Quem consome o resultado resolve com `.fold((falha) => ..., (sucesso) => ...)`. Veja `lib/modules/onboarding/domain/` para um exemplo completo desse padrão.

### Navegação: `go_router`

O app usa rotas declarativas em vez de `Navigator.push` espalhado pelo código. A tabela de rotas fica em `lib/core/routing/app_router.dart`; para navegar, use `context.go('/rota')` a partir de qualquer widget.