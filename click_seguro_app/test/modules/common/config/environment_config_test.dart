import 'package:click_seguro_app/modules/common/config/environment_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('sem --dart-define, a URL padrão é o servidor de desenvolvimento', () {
    // Com a URL vazia o Dio falhava antes de chamar a rede, e a tela mostrava
    // "Não foi possível completar a ação" (rodando pelo VS Code).
    expect(
      EnvironmentConfig.apiBaseUrl,
      'https://clickseguro-api.onrender.com/api/v1',
    );
  });
}
