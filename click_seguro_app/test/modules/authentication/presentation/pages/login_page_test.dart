import 'dart:async';

import 'package:click_seguro_app/core/widgets/brand_scene.dart';
import 'package:click_seguro_app/core/widgets/password_rules_list.dart';
import 'package:click_seguro_app/core/widgets/safe_button.dart';
import 'package:click_seguro_app/modules/authentication/domain/failures/auth_failures.dart';
import 'package:click_seguro_app/modules/authentication/presentation/controller/authentication_controller.dart';
import 'package:click_seguro_app/modules/authentication/presentation/pages/login_page.dart';
import 'package:click_seguro_app/modules/authentication/presentation/widgets/auth_header.dart';
import 'package:click_seguro_app/modules/authentication/presentation/widgets/terms_acceptance.dart';
import 'package:click_seguro_app/core/widgets/animated_reveal.dart';
import 'package:click_seguro_app/core/widgets/safe_pill_tabs.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/localized_app.dart';
import '../../fakes/controller_factory.dart';
import '../../fakes/fake_auth_repository.dart';

void main() {
  late FakeAuthRepository repository;
  late AuthenticationController controller;

  setUp(() {
    repository = FakeAuthRepository();
    controller = buildAuthenticationController(repository);
  });

  late GoRouter router;

  Future<void> pumpLogin(
    WidgetTester tester, {
    LoginPage page = const LoginPage(),
  }) => pumpLocalized(
    tester,
    router: router = GoRouter(
      initialLocation: '/login',
      routes: [
        GoRoute(
          path: '/login',
          builder: (_, _) =>
              ChangeNotifierProvider.value(value: controller, child: page),
        ),
        GoRoute(path: '/home', builder: (_, _) => const Text('HOME')),
        GoRoute(
          path: '/activities',
          builder: (_, _) => const Text('ACTIVITIES'),
        ),
        GoRoute(
          path: '/settings/terms',
          builder: (context, _) => TextButton(
            onPressed: () => context.push('/settings/privacy'),
            child: const Text('TERMOS'),
          ),
        ),
        GoRoute(
          path: '/settings/privacy',
          builder: (_, _) => const Text('PRIVACIDADE'),
        ),
      ],
    ),
  );

  Finder field(String placeholder) => find.byWidgetPredicate(
    (w) => w is TextField && w.decoration?.hintText == placeholder,
  );

  Future<void> fillLogin(
    WidgetTester tester, {
    String email = 'maria@exemplo.com',
  }) async {
    await tester.enterText(field('seu@email.com'), email);
    await tester.enterText(field('Digite sua senha'), 'Senha@123');
    await tester.pump(); // habilita o botão com o formulário válido
  }

  /// Marca (ou desmarca) a caixa de aceite do cadastro.
  Future<void> toggleTerms(WidgetTester tester) async {
    final Finder box = find.byType(TermsCheckbox);
    await tester.ensureVisible(box);
    await tester.pumpAndSettle();
    await tester.tap(box);
    await tester.pumpAndSettle();
  }

  Future<void> tapPrimary(WidgetTester tester, String label) async {
    final button = find.widgetWithText(SafeButton, label).last;
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();
  }

  group('US1', () {
    testWidgets('mostra a marca, os campos e o botão Entrar', (tester) async {
      await pumpLogin(tester);

      expect(find.byType(AuthHeader), findsOneWidget);
      expect(field('seu@email.com'), findsOneWidget);
      expect(field('Digite sua senha'), findsOneWidget);
      expect(find.text('Entrar'), findsWidgets);
    });

    testWidgets('campos com rótulo acima, sem o aviso do visitante', (
      tester,
    ) async {
      await pumpLogin(tester);

      expect(find.text('E-mail'), findsOneWidget);
      expect(find.text('Senha'), findsOneWidget);
      // Saiu do login e do cadastro (specs/026 FR-014).
      expect(
        find.text('Sem conta, seu progresso vale só até fechar o app.'),
        findsNothing,
      );

      await tester.tap(registerTab);
      await tester.pumpAndSettle();
      expect(find.text('Nome'), findsOneWidget);
    });

    testWidgets('credenciais válidas levam ao Início', (tester) async {
      await pumpLogin(tester);
      await fillLogin(tester);

      await tapPrimary(tester, 'Entrar');

      expect(find.text('HOME'), findsOneWidget);
    });

    testWidgets('senha errada mostra a mensagem e mantém o e-mail', (
      tester,
    ) async {
      repository.loginResult = const Left(InvalidCredentialsFailure());
      await pumpLogin(tester);
      await fillLogin(tester);

      await tapPrimary(tester, 'Entrar');

      expect(find.text('E-mail ou senha incorretos.'), findsOneWidget);
      expect(find.text('maria@exemplo.com'), findsOneWidget);
    });

    testWidgets('Entrar fica desabilitado até os campos estarem corretos', (
      tester,
    ) async {
      bool disabled() => tester
          .widget<SafeButton>(find.widgetWithText(SafeButton, 'Entrar').last)
          .disabled;
      await pumpLogin(tester);
      expect(disabled(), isTrue);

      await fillLogin(tester, email: 'maria@');
      expect(disabled(), isTrue);

      await fillLogin(tester);
      expect(disabled(), isFalse);
    });

    testWidgets('e-mail inválido mostra o erro ao sair do campo', (
      tester,
    ) async {
      await pumpLogin(tester);
      await tester.enterText(field('seu@email.com'), 'maria@');
      await tester.pump();
      expect(find.text('Digite um e-mail válido.'), findsNothing);

      await tester.tap(field('Digite sua senha')); // sai do campo de e-mail
      await tester.pumpAndSettle();

      expect(find.text('Digite um e-mail válido.'), findsOneWidget);
      expect(repository.loginCalls, 0);
    });

    testWidgets('o olho mostra e oculta a senha', (tester) async {
      await pumpLogin(tester);
      await tester.enterText(field('Digite sua senha'), 'Senha@123');

      expect(
        tester.widget<TextField>(field('Digite sua senha')).obscureText,
        isTrue,
      );
      await tester.tap(find.byTooltip('Mostrar senha'));
      await tester.pump();

      expect(
        tester.widget<TextField>(field('Digite sua senha')).obscureText,
        isFalse,
      );
      expect(find.byTooltip('Ocultar senha'), findsOneWidget);
    });
  });

  group('US2', () {
    Future<void> openRegister(WidgetTester tester) async {
      await tester.tap(registerTab);
      await tester.pumpAndSettle();
    }

    Future<void> fillRegister(WidgetTester tester) async {
      await tester.enterText(field('Seu nome'), 'Maria Silva');
      await tester.enterText(field('seu@email.com'), 'maria@exemplo.com');
      await tester.enterText(field('Digite sua senha'), 'Senha@123');
      await tester.pump();
      await toggleTerms(tester);
    }

    testWidgets('modo cadastro mostra nome e regras e mantém o e-mail', (
      tester,
    ) async {
      await pumpLogin(tester);
      await tester.enterText(field('seu@email.com'), 'maria@exemplo.com');

      await openRegister(tester);

      expect(field('Seu nome'), findsOneWidget);
      expect(find.byType(PasswordRulesList), findsOneWidget);
      expect(find.text('maria@exemplo.com'), findsOneWidget);
    });

    testWidgets('nome e regras entram crescendo e saem encolhendo '
        '(specs/022 FR-023)', (tester) async {
      await pumpLogin(tester);
      double nameHeight() => tester
          .getSize(
            find.ancestor(
              of: field('Seu nome'),
              matching: find.byType(AnimatedReveal),
            ),
          )
          .height;

      await tester.tap(find.text('Criar conta').first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 20));
      final double entering = nameHeight();
      await tester.pumpAndSettle();
      expect(entering, lessThan(nameHeight()));

      await tester.tap(find.text('Entrar').first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(field('Seu nome'), findsOneWidget, reason: 'saindo');
      await tester.pumpAndSettle();
      expect(field('Seu nome'), findsNothing);
      expect(find.byType(PasswordRulesList), findsNothing);
    });

    testWidgets('Criar conta só habilita com a senha cumprindo as regras', (
      tester,
    ) async {
      bool disabled() => tester
          .widget<SafeButton>(
            find.widgetWithText(SafeButton, 'Criar conta').last,
          )
          .disabled;
      await pumpLogin(tester);
      await openRegister(tester);
      await toggleTerms(tester);
      await tester.enterText(field('Seu nome'), 'Maria Silva');
      await tester.enterText(field('seu@email.com'), 'maria@exemplo.com');

      await tester.enterText(field('Digite sua senha'), 'Senha1234');
      await tester.pump();
      expect(disabled(), isTrue);

      await tester.enterText(field('Digite sua senha'), 'Senha@123');
      await tester.pump();
      expect(disabled(), isFalse);
    });

    testWidgets('senha forte marca as 5 regras', (tester) async {
      await pumpLogin(tester);
      await openRegister(tester);

      await tester.enterText(field('Digite sua senha'), 'Senha@123');
      await tester.pump();

      expect(find.byIcon(LucideIcons.circleCheck), findsNWidgets(5));
    });

    testWidgets('cadastro válido leva ao Início', (tester) async {
      await pumpLogin(tester);
      await openRegister(tester);
      await fillRegister(tester);

      await tapPrimary(tester, 'Criar conta');

      expect(find.text('HOME'), findsOneWidget);
    });

    testWidgets('e-mail duplicado oferece entrar com o mesmo e-mail', (
      tester,
    ) async {
      repository.registerResult = const Left(EmailAlreadyExistsFailure());
      await pumpLogin(tester);
      await openRegister(tester);
      await fillRegister(tester);

      await tapPrimary(tester, 'Criar conta');
      expect(find.text('Este e-mail já está cadastrado.'), findsOneWidget);
      await tapPrimary(tester, 'Entrar com este e-mail');

      expect(field('Seu nome'), findsNothing);
      expect(find.text('maria@exemplo.com'), findsOneWidget);
    });

    testWidgets('conta criada sem login volta ao entrar com o aviso', (
      tester,
    ) async {
      repository.registerResult = const Left(AccountCreatedFailure());
      await pumpLogin(tester);
      await openRegister(tester);
      await fillRegister(tester);

      await tapPrimary(tester, 'Criar conta');

      expect(field('Seu nome'), findsNothing);
      expect(
        find.text('Conta criada. Entre com seu e-mail e senha.'),
        findsOneWidget,
      );
    });
  });

  // specs/026 US2: aceite dos Termos de uso e da Política de privacidade.
  group('aceite dos termos', () {
    bool registerDisabled(WidgetTester tester) => tester
        .widget<SafeButton>(find.widgetWithText(SafeButton, 'Criar conta').last)
        .disabled;

    Future<void> openRegisterFilled(WidgetTester tester) async {
      await pumpLogin(tester);
      await tester.tap(registerTab);
      await tester.pumpAndSettle();
      await tester.enterText(field('Seu nome'), 'Maria Silva');
      await tester.enterText(field('seu@email.com'), 'maria@exemplo.com');
      await tester.enterText(field('Digite sua senha'), 'Senha@123');
      await tester.pump();
    }

    bool accepted(WidgetTester tester) =>
        tester.widget<TermsAcceptance>(find.byType(TermsAcceptance)).accepted;

    void expectFormKept(WidgetTester tester) {
      expect(find.text('Maria Silva'), findsOneWidget);
      expect(find.text('maria@exemplo.com'), findsOneWidget);
      expect(find.text('Senha@123'), findsOneWidget);
    }

    Future<void> tapLink(WidgetTester tester, String text) async {
      await tester.ensureVisible(find.byType(TermsAcceptance));
      await tester.pumpAndSettle();
      await tester.tapOnText(find.textRange.ofSubstring(text));
      await tester.pumpAndSettle();
    }

    testWidgets('só no cadastro, abaixo das regras da senha', (tester) async {
      await pumpLogin(tester);
      expect(find.byType(TermsAcceptance), findsNothing);

      await tester.tap(registerTab);
      await tester.pumpAndSettle();

      expect(find.byType(TermsAcceptance), findsOneWidget);
      expect(accepted(tester), isFalse);
      expect(
        tester.getTopLeft(find.byType(TermsAcceptance)).dy,
        greaterThan(tester.getBottomLeft(find.byType(PasswordRulesList)).dy),
      );
    });

    testWidgets('"Criar conta" só ativa com a caixa marcada', (tester) async {
      await openRegisterFilled(tester);
      expect(registerDisabled(tester), isTrue);

      await toggleTerms(tester);
      expect(registerDisabled(tester), isFalse);

      await toggleTerms(tester);
      expect(registerDisabled(tester), isTrue);
    });

    testWidgets('o aceite continua marcado ao trocar de aba', (tester) async {
      await openRegisterFilled(tester);
      await toggleTerms(tester);

      await tester.tap(find.text('Entrar').first);
      await tester.pumpAndSettle();
      await tester.tap(registerTab);
      await tester.pumpAndSettle();

      expect(accepted(tester), isTrue);
      expect(registerDisabled(tester), isFalse);
    });

    testWidgets('"Termos de uso" abre os Termos; ao voltar, nada se perde', (
      tester,
    ) async {
      await openRegisterFilled(tester);
      await toggleTerms(tester);

      await tapLink(tester, 'Termos de uso');
      expect(find.text('TERMOS'), findsOneWidget);
      router.pop();
      await tester.pumpAndSettle();

      expectFormKept(tester);
      expect(accepted(tester), isTrue);
    });

    testWidgets('"Política de privacidade" abre a Privacidade; ao voltar, '
        'nada se perde', (tester) async {
      await openRegisterFilled(tester);

      await tapLink(tester, 'Política de privacidade');
      expect(find.text('PRIVACIDADE'), findsOneWidget);
      router.pop();
      await tester.pumpAndSettle();

      expectFormKept(tester);
      expect(accepted(tester), isFalse);
    });

    testWidgets('Termos → Privacidade → voltar duas vezes: cadastro intacto', (
      tester,
    ) async {
      await openRegisterFilled(tester);
      await toggleTerms(tester);

      await tapLink(tester, 'Termos de uso');
      await tester.tap(find.text('TERMOS'));
      await tester.pumpAndSettle();
      expect(find.text('PRIVACIDADE'), findsOneWidget);
      router.pop();
      await tester.pumpAndSettle();
      router.pop();
      await tester.pumpAndSettle();

      expectFormKept(tester);
      expect(accepted(tester), isTrue);
    });

    testWidgets('reabrir a tela desmarca a caixa', (tester) async {
      controller.setTermsAccepted(true);

      await pumpLogin(
        tester,
        page: const LoginPage(initialMode: AuthMode.register),
      );

      expect(accepted(tester), isFalse);
    });
  });

  group('US3', () {
    testWidgets('continuar sem login aparece nos dois modos e leva ao Início', (
      tester,
    ) async {
      await pumpLogin(tester);
      expect(find.text('Continuar sem login'), findsOneWidget);

      await tester.tap(registerTab);
      await tester.pumpAndSettle();
      expect(find.text('Continuar sem login'), findsOneWidget);
      expect(
        find.text('Sem conta, seu progresso vale só até fechar o app.'),
        findsNothing,
      );

      // Versão A (specs/026 FR-012): link coral no lugar do botão creme.
      final Finder guest = find.widgetWithText(
        TextButton,
        'Continuar sem login',
      );
      await tester.ensureVisible(guest);
      await tester.pumpAndSettle();
      await tester.tap(guest);
      await tester.pumpAndSettle();

      expect(find.text('HOME'), findsOneWidget);
      expect(repository.guestCalls, 1);
    });
  });

  // specs/026 US3: versão A, que continua a splash.
  group('visual da versão A', () {
    testWidgets('ordem: marca, título, slogan, abas, campos, "Esqueci", '
        '"Entrar" e "Continuar sem login"', (tester) async {
      await pumpLogin(tester);

      final List<Finder> order = [
        find.byType(AuthHeader),
        find.byType(SafePillTabs),
        field('seu@email.com'),
        field('Digite sua senha'),
        find.text('Esqueci minha senha'),
        find.widgetWithText(SafeButton, 'Entrar'),
        find.text('Continuar sem login'),
      ];
      for (int i = 1; i < order.length; i++) {
        expect(
          tester.getTopLeft(order[i]).dy,
          greaterThan(tester.getTopLeft(order[i - 1]).dy),
          reason: '${order[i]}',
        );
      }
    });

    testWidgets('sem o divisor "ou"', (tester) async {
      await pumpLogin(tester);

      expect(find.text('ou'), findsNothing);
    });

    testWidgets('"Esqueci minha senha" alinhado à direita', (tester) async {
      await pumpLogin(tester);

      expect(
        tester.getTopRight(find.text('Esqueci minha senha')).dx,
        closeTo(tester.getTopRight(field('seu@email.com')).dx, 24),
      );
      expect(
        tester.getCenter(find.text('Esqueci minha senha')).dx,
        greaterThan(tester.getSize(find.byType(Scaffold)).width / 2),
      );
    });

    testWidgets('"Entrar" e "Criar conta" com a seta à direita', (
      tester,
    ) async {
      await pumpLogin(tester);
      SafeButton primary(String label) =>
          tester.widget<SafeButton>(find.widgetWithText(SafeButton, label));

      expect(
        (primary('Entrar').iconRight! as Icon).icon,
        LucideIcons.arrowRight,
      );

      await tester.tap(registerTab);
      await tester.pumpAndSettle();
      expect(
        (tester
                    .widget<SafeButton>(
                      find.widgetWithText(SafeButton, 'Criar conta').last,
                    )
                    .iconRight!
                as Icon)
            .icon,
        LucideIcons.arrowRight,
      );
    });

    testWidgets('a onda da splash fica no pé da tela', (tester) async {
      await pumpLogin(tester);

      expect(find.byType(BrandWave), findsOneWidget);
      final double screen = tester.getSize(find.byType(Scaffold)).height;
      expect(tester.getBottomLeft(find.byType(BrandWave)).dy, screen);
    });

    testWidgets(
      'fonte 2× numa tela baixa: o fim rola até ficar acima da onda',
      (tester) async {
        tester.view
          ..physicalSize = const Size(1080, 1920)
          ..devicePixelRatio = 3;
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

        await pumpLogin(tester);
        await tester.tap(registerTab);
        await tester.pumpAndSettle();
        await tester.drag(
          find.byType(Scrollable).first,
          const Offset(0, -5000),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        final double screen = tester.getSize(find.byType(Scaffold)).height;
        expect(
          tester.getBottomLeft(find.text('Continuar sem login')).dy,
          lessThan(screen - BrandScene.footerHeight),
        );
      },
    );
  });

  // Sem aviso de servidor lento (validação da usuária, specs/024).
  group('servidor lento', () {
    testWidgets('esperando, sem aviso de servidor; o botão carrega', (
      tester,
    ) async {
      repository.gate = Completer<void>();
      await pumpLogin(tester);
      await fillLogin(tester);

      await tester.tap(find.widgetWithText(SafeButton, 'Entrar').last);
      await tester.pump(); // reconstrói com isSubmitting = true
      await tester.pump(const Duration(seconds: 6));

      expect(
        find.text('Conectando ao servidor. Isso pode levar até um minuto.'),
        findsNothing,
      );
      repository.gate!.complete();
      await tester.pumpAndSettle();
      expect(find.text('HOME'), findsOneWidget);
    });
  });

  group('aberto pelo aviso das atividades (specs/020 R4)', () {
    const LoginPage fromAlert = LoginPage(
      initialMode: AuthMode.register,
      next: '/activities',
    );

    testWidgets('abre direto em "Criar conta"', (tester) async {
      await pumpLogin(tester, page: fromAlert);

      expect(field('Seu nome'), findsOneWidget);
      expect(find.byType(PasswordRulesList), findsOneWidget);
    });

    testWidgets('cadastro leva a Atividades, não ao Início', (tester) async {
      await pumpLogin(tester, page: fromAlert);
      await tester.enterText(field('Seu nome'), 'Maria Silva');
      await tester.enterText(field('seu@email.com'), 'maria@exemplo.com');
      await tester.enterText(field('Digite sua senha'), 'Senha@123');
      await tester.pump();
      await toggleTerms(tester);

      await tapPrimary(tester, 'Criar conta');

      expect(find.text('ACTIVITIES'), findsOneWidget);
      expect(find.text('HOME'), findsNothing);
    });

    testWidgets('trocar para "Entrar" também leva a Atividades', (
      tester,
    ) async {
      await pumpLogin(tester, page: const LoginPage(next: '/activities'));
      await fillLogin(tester);

      await tapPrimary(tester, 'Entrar');

      expect(find.text('ACTIVITIES'), findsOneWidget);
    });
  });
}

/// A aba "Criar conta" do seletor no topo do login.
final Finder registerTab = find.descendant(
  of: find.byType(SafePillTabs),
  matching: find.text('Criar conta'),
);
