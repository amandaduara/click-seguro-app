import 'dart:ui' as ui;

import 'package:click_seguro_app/core/theme/app_motion.dart';
import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/widgets/safe_icon_button.dart';
import 'package:click_seguro_app/core/widgets/safe_illustration.dart';
import 'package:click_seguro_app/modules/news/presentation/extensions/news_presentation_extension.dart';
import 'package:click_seguro_app/modules/news/presentation/routes/news_detail_preview.dart';
import 'package:click_seguro_app/modules/news/presentation/widgets/news_cover.dart';
import 'package:click_seguro_app/modules/news/presentation/widgets/news_detail_actions.dart';
import 'package:click_seguro_app/modules/news/presentation/widgets/news_detail_cover_bar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../fakes/hanging_http_client.dart';
import '../../../../helpers/localized_app.dart';
import '../../fakes/fake_news_repository.dart';

const String _url = 'https://img.test/n.jpg';
const String _tag = 'news-image-recent-n1';

void main() {
  setUp(() => imageCache.clear());

  /// O cliente que nunca responde é trocado de volta no fim do próprio teste
  /// (o framework confere as variáveis de depuração antes do tearDown).
  void coverTest(String name, Future<void> Function(WidgetTester) body) =>
      testWidgets(name, (tester) async {
        await body(tester);
        debugNetworkImageHttpClientProvider = null;
      });

  Future<void> pumpCover(
    WidgetTester tester, {
    String? heroTag = _tag,
    bool reduceMotion = false,
    bool withActions = true,
    bool isSaved = false,
    bool isLiked = false,
    NewsActionTags? actionTags,
    VoidCallback? onShare,
  }) async {
    debugNetworkImageHttpClientProvider = HangingHttpClient.new;
    tester.view
      ..physicalSize = const Size(1080, 2340)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await pumpLocalized(
      tester,
      settle: false,
      child: AppMotionScope(
        appReduceMotion: reduceMotion,
        child: Scaffold(
          body: CustomScrollView(
            slivers: [
              NewsDetailCoverBar(
                news: newsItem('n1', imageUrl: _url),
                heroTag: heroTag,
                actions: withActions
                    ? NewsDetailActions(
                        heroTags: actionTags,
                        isLiked: isLiked,
                        likesCount: 1200,
                        onLike: () {},
                        isSaved: isSaved,
                        onSave: () {},
                        onShare: onShare ?? () {},
                      )
                    : null,
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 2000)),
            ],
          ),
        ),
      ),
    );
  }

  /// A capa do cartão já no cache, como depois do feed: decodificada pela
  /// largura da tela (360 dp × 3), a mesma chave que o detalhe pede.
  Future<void> cacheCardCover(WidgetTester tester) async {
    final ui.Image image =
        await tester.runAsync(() => createTestImage()) as ui.Image;
    final Object key = await const ResizeImage(
      NetworkImage(_url),
      width: 1080,
    ).obtainKey(ImageConfiguration.empty);
    imageCache.putIfAbsent(
      key,
      () => OneFrameImageStreamCompleter(
        SynchronousFuture(ImageInfo(image: image)),
      ),
    );
  }

  Finder paintedImage() =>
      find.byWidgetPredicate((w) => w is RawImage && w.image != null);

  group('capa', () {
    // specs/022 FR-017: o detalhe mostra na hora a imagem que o cartão já
    // tinha. A capa do redesign pede a mesma chave de cache do cartão.
    coverTest('aberto por um cartão: a capa já aparece pronta', (tester) async {
      await cacheCardCover(tester);

      await pumpCover(tester);
      await tester.pump();

      expect(paintedImage(), findsOneWidget);
    });

    coverTest('sem a imagem no cache, a ilustração cobre a espera', (
      tester,
    ) async {
      await pumpCover(tester, heroTag: null);
      await tester.pump();

      expect(paintedImage(), findsNothing);
      expect(find.byType(SafeIllustration), findsOneWidget);
    });

    coverTest('capa de 270 até a borda, sem título na barra', (tester) async {
      await pumpCover(tester);

      final Rect cover = tester.getRect(find.byType(FlexibleSpaceBar));
      expect(cover.left, 0);
      expect(cover.width, 360);
      expect(cover.height, NewsDetailCoverBar.coverHeight);
      expect(find.text('Notícia n1'), findsNothing);
    });

    // O mesmo texto do cartão: a capa não muda de desenho ao abrir.
    coverTest('tema da capa: o mesmo texto do cartão', (tester) async {
      await pumpCover(tester);

      expect(
        tester.widget<NewsCover>(find.byType(NewsCover)).themeText,
        newsItem('n1', imageUrl: _url).illustrationText,
      );
    });

    coverTest('a imagem voa com o Hero do cartão', (tester) async {
      await pumpCover(tester);

      expect(
        find.byWidgetPredicate((w) => w is Hero && w.tag == _tag),
        findsOneWidget,
      );
    });

    // specs/022 FR-010: com "Reduzir animações", a imagem não voa.
    coverTest('movimento reduzido: sem Hero', (tester) async {
      await pumpCover(tester, reduceMotion: true);

      expect(find.byType(Hero), findsNothing);
    });
  });

  group('botões sobre a capa', () {
    coverTest('voltar à esquerda; curtir, compartilhar e salvar à direita, '
        'brancos e com 48 dp', (tester) async {
      await pumpCover(tester);

      final Rect back = tester.getRect(find.byKey(NewsDetailCoverBar.backKey));
      final Rect like = tester.getRect(find.byKey(NewsDetailActions.likeKey));
      final Rect share = tester.getRect(find.byKey(NewsDetailActions.shareKey));
      final Rect save = tester.getRect(find.byKey(NewsDetailActions.saveKey));
      for (final Rect rect in [back, like, share, save]) {
        expect(rect.width, greaterThanOrEqualTo(48));
        expect(rect.height, greaterThanOrEqualTo(48));
      }
      expect(back.center.dx, lessThan(like.left));
      expect(share.left, greaterThanOrEqualTo(like.right));
      expect(save.left, greaterThanOrEqualTo(share.right));
      // Os quatro ficam sobre a capa.
      final Rect cover = tester.getRect(find.byType(FlexibleSpaceBar));
      for (final Rect rect in [back, like, share, save]) {
        expect(cover.contains(rect.center), isTrue);
      }
      expect(
        tester
            .widgetList<SafeIconButton>(find.byType(SafeIconButton))
            .every((b) => b.onImage),
        isTrue,
      );
    });

    coverTest('rótulos para o leitor de tela, na ordem da esquerda para a '
        'direita', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpCover(tester);

      final Offset back = tester.getTopLeft(find.bySemanticsLabel('Voltar'));
      final Offset like = tester.getTopLeft(
        find.bySemanticsLabel('Curtir, 1,2 mil curtidas'),
      );
      final Offset share = tester.getTopLeft(
        find.bySemanticsLabel('Compartilhar'),
      );
      final Offset save = tester.getTopLeft(find.bySemanticsLabel('Salvar'));
      expect(like.dx, greaterThan(back.dx));
      expect(share.dx, greaterThan(like.dx));
      expect(save.dx, greaterThan(share.dx));
      handle.dispose();
    });

    coverTest('salvo: ícone marcado, rótulo "Salvo" e selecionado', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpCover(tester, isSaved: true);

      expect(find.byIcon(LucideIcons.bookmarkCheck), findsOneWidget);
      expect(
        tester.getSemantics(find.byKey(NewsDetailActions.saveKey)),
        matchesSemantics(
          label: 'Salvo',
          isButton: true,
          isSelected: true,
          hasSelectedState: true,
          hasTapAction: true,
          hasEnabledState: true,
          isEnabled: true,
        ),
      );
      handle.dispose();
    });

    coverTest('curtido: coração cheio coral, rótulo "Curtido" e '
        'selecionado', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpCover(tester, isLiked: true);

      final Icon heart = tester.widget<Icon>(find.byIcon(Icons.favorite));
      final BuildContext context = tester.element(find.byIcon(Icons.favorite));
      expect(heart.color, context.colors.primary);
      expect(
        tester.getSemantics(find.byKey(NewsDetailActions.likeKey)),
        matchesSemantics(
          label: 'Curtido, 1,2 mil curtidas',
          isButton: true,
          isSelected: true,
          hasSelectedState: true,
          hasTapAction: true,
        ),
      );
      handle.dispose();
    });

    coverTest('aberto por um Reel: os três botões são destino de Hero', (
      tester,
    ) async {
      final NewsActionTags tags = NewsActionsPreview.tagsFor('n1');
      await pumpCover(tester, heroTag: null, actionTags: tags);

      for (final String tag in [tags.like, tags.share, tags.save]) {
        expect(
          find.byWidgetPredicate((w) => w is Hero && w.tag == tag),
          findsOneWidget,
          reason: tag,
        );
      }
    });

    coverTest('aberto por um Reel com movimento reduzido: sem Hero', (
      tester,
    ) async {
      await pumpCover(
        tester,
        heroTag: null,
        reduceMotion: true,
        actionTags: NewsActionsPreview.tagsFor('n1'),
      );

      expect(find.byType(Hero), findsNothing);
    });

    coverTest('sem ações (antes da carga), só o voltar', (tester) async {
      await pumpCover(tester, withActions: false);

      expect(find.byKey(NewsDetailCoverBar.backKey), findsOneWidget);
      expect(find.byKey(NewsDetailActions.likeKey), findsNothing);
      expect(find.byKey(NewsDetailActions.shareKey), findsNothing);
      expect(find.byKey(NewsDetailActions.saveKey), findsNothing);
    });

    coverTest('ao rolar, a capa some e os botões continuam no topo', (
      tester,
    ) async {
      var shares = 0;
      await pumpCover(tester, onShare: () => shares++);

      await tester.drag(find.byType(CustomScrollView), const Offset(0, -600));
      await tester.pump();

      final Rect back = tester.getRect(find.byKey(NewsDetailCoverBar.backKey));
      expect(back.top, greaterThanOrEqualTo(0));
      expect(back.bottom, lessThan(NewsDetailCoverBar.coverHeight / 2));
      await tester.tap(find.byKey(NewsDetailActions.shareKey));
      expect(shares, 1);
    });
  });
}
