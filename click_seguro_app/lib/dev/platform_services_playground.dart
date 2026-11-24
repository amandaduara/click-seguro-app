// Só para desenvolvimento: flutter run -t lib/dev/platform_services_playground.dart
//
// Tela para validar no aparelho os serviços da feature 007 (voz, abrir
// endereço, ligar, compartilhar e fotos), seguindo o quickstart. Não é
// importada pelo app; os textos são fixos por não ser parte do produto,
// como no style guide.
import 'dart:io';

import 'package:click_seguro_app/core/theme/app_theme.dart';
import 'package:click_seguro_app/modules/common/common.dart';
import 'package:click_seguro_app/modules/common/presentation/controller/read_aloud_controller.dart';
import 'package:click_seguro_app/modules/common/services/external_launcher_service.dart';
import 'package:click_seguro_app/modules/common/services/image_storage_service.dart';
import 'package:click_seguro_app/modules/common/services/share_service.dart';
import 'package:click_seguro_app/modules/common/services/text_to_speech_service.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

const String _shortText =
    'Golpe do Pix: desconfie de mensagens que pedem transferência com urgência.';

/// Mais de 4000 caracteres, para testar a leitura em partes.
final String _longText = List.generate(
  90,
  (i) => 'Esta é a frase número ${i + 1} de um texto longo sobre segurança.',
).join(' ');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  // Os serviços vêm do GetIt, como no app (registro real do CommonModule).
  await ModuleManager().registerModules([CommonModule()]);
  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('pt', 'BR'), Locale('en', 'US')],
      path: 'assets/translations',
      fallbackLocale: const Locale('pt', 'BR'),
      child: const _PlaygroundApp(),
    ),
  );
}

class _PlaygroundApp extends StatelessWidget {
  const _PlaygroundApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Serviços de plataforma',
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      theme: AppTheme.lightTheme,
      home: const _HomePage(),
    );
  }
}

/// Abre a tela de testes por cima, para validar que sair dela para a voz.
class _HomePage extends StatelessWidget {
  const _HomePage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Serviços de plataforma')),
      body: Center(
        child: FilledButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const _PlaygroundPage()),
          ),
          child: const Text('Abrir tela de testes'),
        ),
      ),
    );
  }
}

class _PlaygroundPage extends StatefulWidget {
  const _PlaygroundPage();

  @override
  State<_PlaygroundPage> createState() => _PlaygroundPageState();
}

class _PlaygroundPageState extends State<_PlaygroundPage> {
  final ReadAloudController _voice = GetIt.instance<ReadAloudController>();
  final ExternalLauncherService _launcher =
      GetIt.instance<ExternalLauncherService>();
  final ShareService _share = GetIt.instance<ShareService>();
  final ImageStorageService _images = GetIt.instance<ImageStorageService>();

  final TextEditingController _url = TextEditingController(
    text: 'https://www.gov.br',
  );
  final TextEditingController _phone = TextEditingController(
    text: '(11) 9 1234-5678',
  );

  String _linkResult = '-';
  String _shareResult = '-';
  String _photoResult = '-';
  String? _photoPath;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _voice.prepare(context.locale);
  }

  @override
  void dispose() {
    _voice.dispose();
    _url.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _openUrl() async {
    final bool opened = await _launcher.openUrl(_url.text);
    setState(() => _linkResult = opened ? 'abriu' : 'não abriu');
  }

  Future<void> _canCall() async {
    final bool canCall = await _launcher.canCall();
    setState(() => _linkResult = 'pode ligar: ${canCall ? 'sim' : 'não'}');
  }

  Future<void> _call() async {
    final bool opened = await _launcher.call(_phone.text);
    setState(() => _linkResult = opened ? 'discador abriu' : 'não abriu');
  }

  Future<void> _shareText() async {
    final ShareOutcome outcome = await _share.shareText(
      '$_shortText https://www.gov.br',
      subject: 'Click Seguro',
    );
    setState(() => _shareResult = outcome.name);
  }

  Future<void> _pick(PhotoSource source) async {
    final PickImageResult result = await _images.pickImage(source);
    switch (result) {
      case PickedImage(:final path):
        final image = await decodeImageFromList(await File(path).readAsBytes());
        setState(() {
          _photoPath = path;
          _photoResult = '$path\n${image.width} x ${image.height} px';
        });
      case PickImageCancelled():
        setState(() => _photoResult = 'nenhuma foto');
      case PickImagePermissionDenied():
        setState(() => _photoResult = 'sem permissão');
      case PickImageFailed():
        setState(() => _photoResult = 'falhou');
    }
  }

  Future<void> _deletePhoto() async {
    final String? path = _photoPath;
    if (path == null) return;
    await _images.delete(path);
    setState(() => _photoResult = 'apagada: ${!File(path).existsSync()}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tela de testes')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Section(
            title: 'Voz',
            child: ListenableBuilder(
              listenable: _voice,
              builder: (context, _) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Idioma: ${context.locale.toLanguageTag()} · '
                    'Voz disponível: ${_voice.isAvailable ? 'sim' : 'não'} · '
                    'Estado: ${_voice.isSpeaking ? 'lendo' : 'parado'}',
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<ReadingSpeed>(
                    segments: const [
                      ButtonSegment(
                        value: ReadingSpeed.slow,
                        label: Text('Lenta'),
                      ),
                      ButtonSegment(
                        value: ReadingSpeed.normal,
                        label: Text('Normal'),
                      ),
                      ButtonSegment(
                        value: ReadingSpeed.fast,
                        label: Text('Rápida'),
                      ),
                    ],
                    selected: {_voice.speed},
                    onSelectionChanged: (speeds) =>
                        _voice.setSpeed(speeds.single),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilledButton(
                        onPressed: () => _voice.speak(_shortText),
                        child: const Text('Ouvir A (curto)'),
                      ),
                      FilledButton(
                        onPressed: () => _voice.speak(_longText),
                        child: Text('Ouvir B (${_longText.length} caracteres)'),
                      ),
                      OutlinedButton(
                        onPressed: _voice.stop,
                        child: const Text('Parar'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          _Section(
            title: 'Links e ligação',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _url,
                  decoration: const InputDecoration(labelText: 'Endereço'),
                ),
                FilledButton(
                  onPressed: _openUrl,
                  child: const Text('Abrir fonte'),
                ),
                TextField(
                  controller: _phone,
                  decoration: const InputDecoration(labelText: 'Telefone'),
                ),
                Wrap(
                  spacing: 8,
                  children: [
                    OutlinedButton(
                      onPressed: _canCall,
                      child: const Text('Pode ligar?'),
                    ),
                    FilledButton(onPressed: _call, child: const Text('Ligar')),
                  ],
                ),
                Text('Resultado: $_linkResult'),
              ],
            ),
          ),
          _Section(
            title: 'Compartilhar',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FilledButton(
                  onPressed: _shareText,
                  child: const Text('Compartilhar'),
                ),
                Text('Resultado: $_shareResult'),
              ],
            ),
          ),
          _Section(
            title: 'Fotos',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  children: [
                    FilledButton(
                      onPressed: () => _pick(PhotoSource.gallery),
                      child: const Text('Galeria'),
                    ),
                    FilledButton(
                      onPressed: () => _pick(PhotoSource.camera),
                      child: const Text('Câmera'),
                    ),
                    OutlinedButton(
                      onPressed: _deletePhoto,
                      child: const Text('Apagar'),
                    ),
                  ],
                ),
                Text('Resultado: $_photoResult'),
                if (_photoPath case final String path
                    when File(path).existsSync())
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Image.file(File(path), height: 120),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}
