import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

/// Reconstrói todas as telas quando o idioma do app muda (RF-042,
/// specs/013-configuracoes R5).
///
/// Os textos usam `'chave'.tr()`, que não registra dependência do idioma:
/// sem isto, telas `const` (e as que ficam embaixo na pilha) continuariam
/// no idioma antigo até outra mudança. Fica no `builder` do `MaterialApp`.
class LocaleRebuilder extends StatefulWidget {
  const LocaleRebuilder({super.key, required this.child});

  final Widget child;

  @override
  State<LocaleRebuilder> createState() => _LocaleRebuilderState();
}

class _LocaleRebuilderState extends State<LocaleRebuilder> {
  Locale? _locale;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final Locale locale = context.locale;
    if (_locale != null && _locale != locale) {
      (context as Element).visitChildren(_markNeedsBuild);
    }
    _locale = locale;
  }

  static void _markNeedsBuild(Element element) {
    element
      ..markNeedsBuild()
      ..visitChildren(_markNeedsBuild);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
