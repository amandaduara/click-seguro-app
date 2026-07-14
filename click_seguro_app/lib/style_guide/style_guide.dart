import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const StyleguideWebScreen()); // O widget principal do seu Style Guide
}

// --- TOKENS DE CORES ---
class DSColors {
  static const primary = Color(0xFFFE3152);
  static const secondary = Color(0xFF182A4E);
  static const background = Color(0xFFFFFDFB);
  static const card = Color(0xFFFFFFFF);
  static const foreground = Color(0xFF121932);
  static const mutedForeground = Color(0xFF596475);
  static const border = Color(0xFFDADEE5);
}

// --- TOKENS DE TIPOGRAFIA ---
class DSTypography {
  static const titleLarge = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: DSColors.foreground,
    fontFamily: 'Montserrat',
  );
  static const titleMedium = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: DSColors.secondary,
    fontFamily: 'Montserrat',
  );
  static const bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: DSColors.mutedForeground,
    fontFamily: 'Montserrat',
  );
}

// --- TOKENS DE ESPAÇAMENTO ---
class DSSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  
  static final radiusLg = BorderRadius.circular(12);
  static final radius2xl = BorderRadius.circular(16);
  static final radiusFull = BorderRadius.circular(99);
}

// --- TELA DO STYLEGUIDE WEB ---
class StyleguideWebScreen extends StatefulWidget {
  const StyleguideWebScreen({super.key});

  @override
  State<StyleguideWebScreen> createState() => _StyleguideWebScreenState();
}

class _StyleguideWebScreenState extends State<StyleguideWebScreen> {
  int _activeSectionIndex = 0;

  // Estrutura de dados do Menu dividida por Categorias e Submenus
  final List<Map<String, dynamic>> _menuStructure = [
    {
      'category': 'FUNDAÇÃO',
      'items': [
        {'label': '🎨 Cores Semânticas', 'index': 0},
        {'label': '🔤 Tipografia', 'index': 1},
      ]
    },
    {
      'category': 'INPUTS & AÇÕES',
      'items': [
        {'label': '🔘 SafeButton', 'index': 2},
        {'label': '📝 SafeTextField', 'index': 3},
      ]
    },
    {
      'category': 'LAYOUT & FEEDBACK',
      'items': [
        {'label': '📦 SafeCard', 'index': 4},
        {'label': '🏷️ SafeBadge', 'index': 5},
      ]
    },
  ];

  // Helper para buscar o nome do componente ativo de forma dinâmica
  String _getActiveTitle() {
    for (var cat in _menuStructure) {
      for (var item in cat['items']) {
        if (item['index'] == _activeSectionIndex) {
          return (item['label'] as String).substring(2); // Remove o emoji do título
        }
      }
    }
    return 'Componente';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DSColors.background,
      body: Row(
        children: [
          // 1. BARRA LATERAL CATEGORIZADA
          Container(
            width: 290,
            color: DSColors.secondary,
            padding: const EdgeInsets.symmetric(horizontal: DSSpacing.lg, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header do App
                Row(
                  children: [
                    const Text(
                      'SafeNews',
                      style: TextStyle(
                        color: DSColors.primary,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: DSColors.primary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Docs v1.2',
                        style: TextStyle(
                          color: DSColors.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                
                // Menu de Navegação com Submenus
                Expanded(
                  child: ListView.builder(
                    itemCount: _menuStructure.length,
                    itemBuilder: (context, catIndex) {
                      final category = _menuStructure[catIndex];
                      final List<Map<String, dynamic>> items = category['items'];

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Título da Categoria (Ex: FUNDAÇÃO)
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0, top: 16.0, bottom: 8.0),
                            child: Text(
                              category['category'],
                              style: const TextStyle(
                                color: Colors.white38,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                          // Submenus da Categoria
                          ...items.map((item) {
                            final isSelected = _activeSectionIndex == item['index'];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 4.0),
                              child: InkWell(
                                onTap: () => setState(() => _activeSectionIndex = item['index']),
                                borderRadius: DSSpacing.radiusLg,
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isSelected ? Colors.white.withOpacity(0.08) : Colors.transparent,
                                    borderRadius: DSSpacing.radiusLg,
                                  ),
                                  child: Text(
                                    item['label'],
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : Colors.white70,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      fontSize: 13.5,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                          const SizedBox(height: 8),
                        ],
                      );
                    },
                  ),
                ),
                const Divider(color: Colors.white12),
                const Text(
                  'SafeNews Design System\nSistema de Design Modular',
                  style: TextStyle(color: Colors.white30, fontSize: 11),
                ),
              ],
            ),
          ),

          // 2. PAINEL DE CONTEÚDO PRINCIPAL
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(40),
              child: Center(
                child: SizedBox(
                  width: 1000,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 30),
                      _buildActiveContent(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _getActiveTitle(),
          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: DSColors.secondary),
        ),
        const SizedBox(height: 8),
        const Text(
          'Documentação detalhada com exemplo visual, regras de uso e código fonte.',
          style: TextStyle(color: DSColors.mutedForeground, fontSize: 14),
        ),
        const Divider(height: 40, color: DSColors.border),
      ],
    );
  }

  Widget _buildActiveContent() {
    switch (_activeSectionIndex) {
      case 0:
        return _buildCoresSection();
      case 1:
        return _buildTipografiaSection();
      case 2:
        return _buildBotoesSection();
      case 3:
        return _buildInputsSection();
      case 4:
        return _buildCardsSection();
      case 5:
        return _buildBadgesSection();
      default:
        return const SizedBox();
    }
  }

  // --- RENDERS DAS SEÇÕES ---

  Widget _buildCoresSection() {
    return _buildComponentDocumentation(
      componentName: 'DSColors',
      description: 'A paleta de cores centraliza a identidade do SafeNews, assegurando conformidade estética em todos os fluxos.',
      previewWidget: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildColorCircle('Primary', DSColors.primary),
          _buildColorCircle('Secondary', DSColors.secondary),
          _buildColorCircle('Background', DSColors.background, hasBorder: true),
          _buildColorCircle('Card', DSColors.card, hasBorder: true),
        ],
      ),
      properties: [
        _Prop('DSColors.primary', 'Color', '0xFFFE3152', 'Cor de destaque primário para botões ativos e estados de alerta/erro.'),
        _Prop('DSColors.secondary', 'Color', '0xFF182A4E', 'Azul escuro institucional para contrastes de barras, fontes e menus.'),
        _Prop('DSColors.background', 'Color', '0xFFFFFDFB', 'Cor do canvas do aplicativo (off-white) para máxima legibilidade.'),
        _Prop('DSColors.card', 'Color', '0xFFFFFFFF', 'Cor padrão de superfícies elevadas e agrupamentos de conteúdo.'),
      ],
      codeExample: '''
// Importe a classe de tokens de cores no seu widget:
import 'package:click_seguro_app/core/theme/ds_colors.dart';

Container(
  padding: const EdgeInsets.all(16),
  color: DSColors.background,
  child: Text(
    'Alerta Critíco',
    style: TextStyle(
      color: DSColors.primary,
      fontWeight: FontWeight.bold,
    ),
  ),
);''',
    );
  }

  Widget _buildTipografiaSection() {
    return _buildComponentDocumentation(
      componentName: 'DSTypography',
      description: 'Definições tipográficas padronizadas usando a fonte Montserrat para estruturação hierárquica clara.',
      previewWidget: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Título de Página', style: DSTypography.titleLarge),
          const SizedBox(height: 8),
          Text('Subtítulo de Seção', style: DSTypography.titleMedium),
          const SizedBox(height: 8),
          Text('Este é o corpo de texto padrão para descrições.', style: DSTypography.bodyMedium),
        ],
      ),
      properties: [
        _Prop('DSTypography.titleLarge', 'TextStyle', '28px • Bold', 'Ideal para títulos principais de telas e cabeçalhos de destaque.'),
        _Prop('DSTypography.titleMedium', 'TextStyle', '18px • SemiBold', 'Ideal para cabeçalhos internos de cards ou sessões secundárias.'),
        _Prop('DSTypography.bodyMedium', 'TextStyle', '14px • Regular', 'Estilo padrão para parágrafos de texto corrido e informativos.'),
      ],
      codeExample: '''
// Importe a classe de tokens tipográficos:
import 'package:click_seguro_app/core/theme/ds_typography.dart';

Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Text(
      'Título do Conteúdo',
      style: DSTypography.titleLarge,
    ),
    const SizedBox(height: 12),
    Text(
      'Este parágrafo descreve os detalhes adicionais do componente.',
      style: DSTypography.bodyMedium,
    ),
  ],
);''',
    );
  }

  Widget _buildBotoesSection() {
    return _buildComponentDocumentation(
      componentName: 'SafeButton',
      description: 'Botão primário e secundário parametrizável com feedback tátil integrado.',
      previewWidget: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SafeButton(label: 'Ação Principal', onPressed: () {}, isPrimary: true),
          const SizedBox(height: 16),
          SafeButton(label: 'Ação Secundária', onPressed: () {}, isPrimary: false),
        ],
      ),
      properties: [
        _Prop('label', 'String', 'Obrigatório', 'Título do botão exibido de forma centralizada.'),
        _Prop('onPressed', 'VoidCallback', 'Obrigatório', 'Evento executado no clique do usuário.'),
        _Prop('isPrimary', 'bool', 'true', 'Alterna o estilo entre a cor primária (true) ou secundária (false).'),
      ],
      codeExample: '''
SafeButton(
  label: 'Próxima Etapa',
  isPrimary: true,
  onPressed: () {
    print('Botão acionado');
  },
)''',
    );
  }

  Widget _buildInputsSection() {
    return _buildComponentDocumentation(
      componentName: 'SafeTextField',
      description: 'Elemento de input otimizado com alteração visual de bordas em foco.',
      previewWidget: SafeTextField(
        label: 'Usuário',
        controller: TextEditingController(),
        prefixIcon: Icons.person_outline,
      ),
      properties: [
        _Prop('label', 'String', 'Obrigatório', 'Texto flutuante identificador do input.'),
        _Prop('controller', 'TextEditingController', 'Obrigatório', 'Controlador de leitura do texto digitado.'),
        _Prop('isPassword', 'bool', 'false', 'Se ativo, mascara os caracteres (ocultar senha).'),
        _Prop('prefixIcon', 'IconData?', 'null', 'Ícone auxiliar exibido no início do campo de texto.'),
      ],
      codeExample: '''
SafeTextField(
  label: 'Senha de Acesso',
  controller: senhaController,
  isPassword: true,
  prefixIcon: Icons.lock_open_outlined,
)''',
    );
  }

  Widget _buildCardsSection() {
    return _buildComponentDocumentation(
      componentName: 'SafeCard',
      description: 'Contêiner de isolamento visual com sombra minimalista e bordas responsivas.',
      previewWidget: const SafeCard(
        child: Text(
          'Conteúdo envelopado de forma padronizada.',
          style: TextStyle(color: DSColors.foreground),
        ),
      ),
      properties: [
        _Prop('child', 'Widget', 'Obrigatório', 'Conteúdo interno a ser renderizado na área útil do card.'),
      ],
      codeExample: '''
SafeCard(
  child: Text(
    'Alocado dentro da estrutura com espaçamento interno padrão.',
  ),
)''',
    );
  }

  Widget _buildBadgesSection() {
    return _buildComponentDocumentation(
      componentName: 'SafeBadge',
      description: 'Pequena etiqueta semitransparente usada para status rápidos e tags categorizadoras.',
      previewWidget: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SafeBadge(label: 'Falso', color: DSColors.primary),
          SizedBox(width: 12),
          SafeBadge(label: 'Fato', color: Colors.green),
        ],
      ),
      properties: [
        _Prop('label', 'String', 'Obrigatório', 'Texto curto de identificação.'),
        _Prop('color', 'Color', 'Obrigatório', 'Cor base do texto (que gera também o preenchimento de fundo com 10% de opacidade).'),
      ],
      codeExample: '''
SafeBadge(
  label: 'Análise Concluída',
  color: Colors.green,
)''',
    );
  }

  // --- COMPONENTE DE DOCUMENTAÇÃO PADRÃO ---

  Widget _buildComponentDocumentation({
    required String componentName,
    required String description,
    required Widget previewWidget,
    required List<_Prop> properties,
    required String codeExample,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(description, style: const TextStyle(fontSize: 14, color: DSColors.mutedForeground)),
        const SizedBox(height: 24),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Painel Vivo (Esquerda)
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Visualização Viva', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: DSColors.secondary)),
                  const SizedBox(height: 12),
                  Container(
                    height: 220,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: DSColors.card,
                      borderRadius: DSSpacing.radius2xl,
                      border: Border.all(color: DSColors.border),
                    ),
                    child: Center(child: previewWidget),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 24),
            // Bloco de Código (Direita)
            Expanded(
              flex: 5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Exemplo de Implementação', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: DSColors.secondary)),
                      IconButton(
                        icon: const Icon(Icons.copy_all, size: 20, color: DSColors.primary),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: codeExample));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Código copiado com sucesso!'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                        tooltip: 'Copiar código',
                      )
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    height: 220,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E2E),
                      borderRadius: DSSpacing.radius2xl,
                    ),
                    child: SingleChildScrollView(
                      child: Text(
                        codeExample,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          color: Color(0xFFA6ADC8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        // Tabela Técnica de Atributos/Tokens
        const Text('Especificações Técnicas', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: DSColors.secondary)),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: DSColors.card,
            borderRadius: DSSpacing.radius2xl,
            border: Border.all(color: DSColors.border),
          ),
          child: Table(
            columnWidths: const {
              0: FlexColumnWidth(2.5),
              1: FlexColumnWidth(2),
              2: FlexColumnWidth(2),
              3: FlexColumnWidth(4.5),
            },
            children: [
              TableRow(
                decoration: const BoxDecoration(
                  color: Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
                ),
                children: [
                  _buildTableCell('Token / Atributo', isHeader: true),
                  _buildTableCell('Tipo', isHeader: true),
                  _buildTableCell('Padrão', isHeader: true),
                  _buildTableCell('Aplicação / Uso', isHeader: true),
                ],
              ),
              ...properties.map((prop) => TableRow(
                decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: DSColors.border))),
                children: [
                  _buildTableCell(prop.name, isToken: true),
                  _buildTableCell(prop.type, isType: true),
                  _buildTableCell(prop.defaultValue),
                  _buildTableCell(prop.description),
                ],
              )),
            ],
          ),
        ),
        const Divider(height: 60, color: DSColors.border),
      ],
    );
  }

  Widget _buildTableCell(String text, {bool isHeader = false, bool isType = false, bool isToken = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isHeader || isToken ? FontWeight.bold : FontWeight.normal,
          color: isHeader 
              ? DSColors.secondary 
              : (isType || isToken ? DSColors.primary : DSColors.foreground),
          fontFamily: isType || isToken ? 'monospace' : null,
        ),
      ),
    );
  }

  // --- AUXILIARES ---

  Widget _buildColorCircle(String name, Color color, {bool hasBorder = false}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: hasBorder ? Border.all(color: DSColors.border, width: 2) : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: DSColors.foreground),
        ),
      ],
    );
  }
}

class _Prop {
  final String name;
  final String type;
  final String defaultValue;
  final String description;

  const _Prop(this.name, this.type, this.defaultValue, this.description);
}

// =========================================================================
// 🚀 COMPONENTES DO DESIGN SYSTEM (Prontos para reuso global)
// =========================================================================

class SafeCard extends StatelessWidget {
  final Widget child;
  const SafeCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DSSpacing.md),
      decoration: BoxDecoration(
        color: DSColors.card,
        borderRadius: DSSpacing.radius2xl,
        border: Border.all(color: DSColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class SafeButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isPrimary;

  const SafeButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isPrimary = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary ? DSColors.primary : DSColors.secondary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: DSSpacing.radius2xl),
        ),
        onPressed: onPressed,
        child: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    );
  }
}

class SafeTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool isPassword;
  final IconData? prefixIcon;

  const SafeTextField({
    super.key,
    required this.label,
    required this.controller,
    this.isPassword = false,
    this.prefixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      cursorColor: DSColors.primary,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: DSColors.mutedForeground, fontSize: 14),
        floatingLabelStyle: const TextStyle(color: DSColors.primary),
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: DSColors.mutedForeground) : null,
        filled: true,
        fillColor: DSColors.card,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        enabledBorder: OutlineInputBorder(
          borderRadius: DSSpacing.radius2xl,
          borderSide: const BorderSide(color: DSColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: DSSpacing.radius2xl,
          borderSide: const BorderSide(color: DSColors.primary, width: 2),
        ),
      ),
    );
  }
}

class SafeBadge extends StatelessWidget {
  final String label;
  final Color color;

  const SafeBadge({
    super.key,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: DSSpacing.radiusFull,
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}