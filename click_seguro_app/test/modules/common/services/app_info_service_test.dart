import 'package:click_seguro_app/modules/common/services/app_info_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('devolve a versão instalada', () async {
    PackageInfo.setMockInitialValues(
      appName: 'Click Seguro',
      packageName: 'com.example.click_seguro_app',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    );

    expect(await PackageInfoAppInfoService().version(), '1.0.0');
  });

  test('falha ao ler → texto vazio, sem lançar', () async {
    final service = PackageInfoAppInfoService(
      load: () => Future<PackageInfo>.error(StateError('sem plataforma')),
    );

    expect(await service.version(), '');
  });
}
