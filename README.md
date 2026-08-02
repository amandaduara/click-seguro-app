# Click Seguro - TCC

> Código-fonte do aplicativo mobile desenvolvido como projeto de Conclusão de Curso (TCC) para o curso de Análise e Desenvolvimento de Sistemas na FATEC.

---

## 🛠️ Stack Tecnológica & Pacotes Principais

O projeto foi construído utilizando o ecossistema **Flutter & Dart**, adotando ferramentas modernas que garantem alta performance, segurança e manutenibilidade.

| Ferramenta / Pacote | Função no Projeto |
| :--- | :--- |
| **Flutter & Dart** | Framework e Linguagem base do projeto |
| **GetIt** | Injeção de Dependências (Garante o desacoplamento do SOLID) |
| **Dio** | Cliente HTTP avançado (Controle de Interceptors, rotas e timeouts) |
| **Lucide Icons** | Biblioteca moderna e minimalista de ícones vetoriais |
| **Flutter Secure Storage** | Armazenamento criptografado de dados sensíveis (Tokens JWT) |
| **Shimmer** | Esqueletos de carregamento visuais para otimizar a UX |
| **Flutter Localizations** | Sistema oficial de suporte a internacionalização (i18n) |
| **Flutter SVG** | Biblioteca quer permite desenhar e exibir arquivos Scalable Vector Graphics |
| **Flutter Lints** | Pacote que fornece um conjunto recomendado de regras, visando incentivar boas práticas de programação e manter a consistência do código |

---

## 📐 Arquitetura do Projeto: DDD + SOLID

Para garantir que o projeto seja escalável, testável e que o desenvolvimento em equipe ocorra sem conflitos, adotamos o **DDD (Domain-Driven Design)** pragmático aliado aos princípios do **SOLID**. O aplicativo é dividido em **módulos independentes (Features)**, onde cada funcionalidade possui três camadas isoladas:

```text
assets/
├── images/                       # Onde ficam as ilustrações (ex: empty_state.svg, logo.svg)
lib/
├── core/                         # Código compartilhado globalmente
│   ├── constants/                # Caminhos de imagens, rotas fixas, chaves
│   ├── errors/                   # Tratamento global de exceções (Failures)
│   ├── http/                     # Configuração do Dio e Interceptors de API
│   ├── i18n/                     # Arquivos de tradução e internacionalização
│   ├── theme/                    # Design System (Cores, fontes e espaçamentos)
│   └── widgets/                  # Componentes puramente visuais e globais
│
└── features/                     # Módulos/Funcionalidades independentes
    └── [nome_da_feature]/        # Exemplo: auth, home, profile
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
            ├── controllers/      # Gerência de estado e lógica de tela
            ├── pages/            # Telas completas da feature
            └── widgets/          # Componentes visuais exclusivos desta tela