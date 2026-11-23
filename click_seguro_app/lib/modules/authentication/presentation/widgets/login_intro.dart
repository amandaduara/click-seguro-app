import 'package:click_seguro_app/core/theme/app_motion.dart';
import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/widgets/brand_mark.dart';
import 'package:click_seguro_app/core/widgets/brand_scene.dart';
import 'package:flutter/material.dart';

/// Linha do tempo da passagem da splash para o login (specs/026 R1).
/// Tempos fixos da passagem aprovada (fora da escala de `AppMotion`, como a
/// `SplashTimeline`); o movimento reduzido pula a abertura inteira.
abstract final class _LoginIntroTimeline {
  static const Duration total = Duration(milliseconds: 1250);

  static double _at(int ms) => ms / total.inMilliseconds;

  /// O nome e o slogan da splash somem subindo.
  static final Interval splashText = Interval(
    0,
    _at(300),
    curve: AppMotion.exit,
  );

  /// A marca vai do lugar da splash ao cabeçalho (curva da splash).
  static final Interval flight = Interval(
    _at(150),
    _at(750),
    curve: Curves.fastOutSlowIn,
  );

  /// Entrada do bloco [index] do login (0 a 4), 125 ms depois do anterior.
  static Interval step(int index) => Interval(
    _at(450 + 125 * index),
    _at(750 + 125 * index),
    curve: AppMotion.enter,
  );
}

/// Faz a abertura do login quando ele vem da splash: o primeiro quadro é o
/// último da splash (a marca e o nome no mesmo lugar); a marca voa até o
/// cabeçalho ([LoginIntroLogoSlot]) e os blocos ([LoginIntroReveal]) entram
/// em sequência. Enquanto anima, ignora toques. Com o movimento reduzido,
/// nasce pronta.
class LoginIntro extends StatefulWidget {
  const LoginIntro({super.key, required this.child});

  final Widget child;

  @override
  State<LoginIntro> createState() => _LoginIntroState();
}

class _LoginIntroState extends State<LoginIntro>
    with SingleTickerProviderStateMixin {
  static const double _textExitOffset = 10;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _LoginIntroTimeline.total,
  );
  final GlobalKey _logoSlot = GlobalKey();

  /// Onde a marca termina (o espaço dela no cabeçalho), medido depois do
  /// primeiro quadro.
  Rect? _target;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureTarget());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (AppMotion.of(context).reduced) {
      _controller.value = 1;
    } else if (_controller.isDismissed) {
      _controller.forward();
    }
  }

  void _measureTarget() {
    final RenderObject? slot = _logoSlot.currentContext?.findRenderObject();
    final RenderObject? stack = context.findRenderObject();
    if (!mounted || slot is! RenderBox || stack is! RenderBox) return;
    setState(() {
      _target = slot.localToGlobal(Offset.zero, ancestor: stack) & slot.size;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _LoginIntroScope(
      animation: _controller,
      logoSlotKey: _logoSlot,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final Rect start = BrandScene.logoRectFor(
            width: constraints.maxWidth,
            viewportHeight: constraints.maxHeight,
            topInset: MediaQuery.paddingOf(context).top,
          );
          return AnimatedBuilder(
            animation: _controller,
            child: widget.child,
            builder: (context, child) {
              final double t = _controller.value;
              final double flight = _LoginIntroTimeline.flight.transform(t);
              final double textExit = _LoginIntroTimeline.splashText.transform(
                t,
              );
              return Stack(
                children: [
                  IgnorePointer(ignoring: t < 1, child: child),
                  if (textExit < 1)
                    Positioned(
                      left: 0,
                      right: 0,
                      top:
                          BrandScene.titleTopFor(start) -
                          _textExitOffset * textExit,
                      child: Opacity(
                        opacity: 1 - textExit,
                        child: const _SplashTitle(),
                      ),
                    ),
                  if (flight < 1)
                    Positioned.fromRect(
                      rect: Rect.lerp(start, _target ?? start, flight)!,
                      child: const LoginIntroLogo(),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

/// A marca em voo, desenhada como a da splash e a do cabeçalho.
class LoginIntroLogo extends StatelessWidget {
  const LoginIntroLogo({super.key});

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: CustomPaint(
      size: Size.infinite,
      painter: BrandMarkPainter(color: context.colors.primary),
    ),
  );
}

/// O nome e o slogan como no fim da splash (só imagem: o leitor de tela já
/// leu a splash).
class _SplashTitle extends StatelessWidget {
  const _SplashTitle();

  @override
  Widget build(BuildContext context) => const ExcludeSemantics(
    child: Column(
      children: [
        BrandName(),
        SizedBox(height: BrandScene.taglineGap),
        BrandTagline(),
      ],
    ),
  );
}

class _LoginIntroScope extends InheritedWidget {
  const _LoginIntroScope({
    required this.animation,
    required this.logoSlotKey,
    required super.child,
  });

  final Animation<double> animation;
  final GlobalKey logoSlotKey;

  static _LoginIntroScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_LoginIntroScope>();

  @override
  bool updateShouldNotify(_LoginIntroScope oldWidget) =>
      animation != oldWidget.animation || logoSlotKey != oldWidget.logoSlotKey;
}

/// Bloco do login que entra subindo 14 px no passo [step] da abertura. Fora
/// da abertura, mostra [child] como está.
class LoginIntroReveal extends StatelessWidget {
  const LoginIntroReveal({super.key, required this.step, required this.child});

  static const double _rise = 14;

  final int step;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final _LoginIntroScope? scope = _LoginIntroScope.maybeOf(context);
    if (scope == null) return child;
    final Interval interval = _LoginIntroTimeline.step(step);
    return AnimatedBuilder(
      animation: scope.animation,
      child: child,
      builder: (context, child) {
        final double progress = interval.transform(scope.animation.value);
        return Opacity(
          opacity: progress,
          child: Transform.translate(
            offset: Offset(0, _rise * (1 - progress)),
            child: child,
          ),
        );
      },
    );
  }
}

/// Espaço da marca no cabeçalho: destino do voo, vazio até a marca chegar.
/// Fora da abertura, mostra [child] como está.
class LoginIntroLogoSlot extends StatelessWidget {
  const LoginIntroLogoSlot({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final _LoginIntroScope? scope = _LoginIntroScope.maybeOf(context);
    if (scope == null) return child;
    return KeyedSubtree(
      key: scope.logoSlotKey,
      child: AnimatedBuilder(
        animation: scope.animation,
        child: child,
        builder: (context, child) => Opacity(
          opacity:
              _LoginIntroTimeline.flight.transform(scope.animation.value) >= 1
              ? 1
              : 0,
          child: child,
        ),
      ),
    );
  }
}
