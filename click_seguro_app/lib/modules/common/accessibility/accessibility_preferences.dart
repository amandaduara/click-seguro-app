import 'dart:math' as math;

import 'package:click_seguro_app/modules/common/services/text_to_speech_service.dart';

/// Tamanho da fonte do app: padrão e três níveis maiores (RF-038).
enum FontScaleLevel {
  standard(1.0),
  large(1.15),
  larger(1.3),
  largest(1.5);

  const FontScaleLevel(this.factor);

  final double factor;

  /// Teto da escala total (sistema × app), para as telas continuarem
  /// utilizáveis (FR-004).
  static const double maxTotalScale = 2.0;

  /// Escala aplicada ao texto: a do sistema ([systemScale], RNF-004) vezes
  /// este nível, limitada a [maxTotalScale].
  double totalScale(double systemScale) =>
      math.min(systemScale * factor, maxTotalScale);
}

/// Preferências de acessibilidade do aparelho, não da conta (RF-038 a
/// RF-041, FR-010).
class AccessibilityPreferences {
  const AccessibilityPreferences({
    required this.fontScale,
    required this.highContrast,
    required this.autoReadAloud,
    required this.readingSpeed,
  });

  const AccessibilityPreferences.defaults()
    : fontScale = FontScaleLevel.standard,
      highContrast = false,
      autoReadAloud = false,
      readingSpeed = ReadingSpeed.normal;

  final FontScaleLevel fontScale;
  final bool highContrast;

  /// Ler sozinho ao abrir uma notícia ou pergunta (RF-040; A5 e B2).
  final bool autoReadAloud;
  final ReadingSpeed readingSpeed;

  AccessibilityPreferences copyWith({
    FontScaleLevel? fontScale,
    bool? highContrast,
    bool? autoReadAloud,
    ReadingSpeed? readingSpeed,
  }) => AccessibilityPreferences(
    fontScale: fontScale ?? this.fontScale,
    highContrast: highContrast ?? this.highContrast,
    autoReadAloud: autoReadAloud ?? this.autoReadAloud,
    readingSpeed: readingSpeed ?? this.readingSpeed,
  );

  @override
  bool operator ==(Object other) =>
      other is AccessibilityPreferences &&
      other.fontScale == fontScale &&
      other.highContrast == highContrast &&
      other.autoReadAloud == autoReadAloud &&
      other.readingSpeed == readingSpeed;

  @override
  int get hashCode =>
      Object.hash(fontScale, highContrast, autoReadAloud, readingSpeed);
}
