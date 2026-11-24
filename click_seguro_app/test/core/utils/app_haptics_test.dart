import 'package:click_seguro_app/core/utils/app_haptics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final List<Object?> vibrations = [];

  setUp(() {
    vibrations.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'HapticFeedback.vibrate') {
            vibrations.add(call.arguments);
          }
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  test('cada ação dá uma vibração do seu tipo (FR-022, FR-028)', () async {
    await AppHaptics.selection();
    await AppHaptics.success();
    await AppHaptics.error();

    expect(vibrations, [
      'HapticFeedbackType.selectionClick',
      'HapticFeedbackType.lightImpact',
      'HapticFeedbackType.heavyImpact',
    ]);
  });
}
