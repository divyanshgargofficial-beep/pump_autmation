import 'package:flutter_test/flutter_test.dart';
import 'package:water_tank_controller/models/esp_status.dart';
import 'package:water_tank_controller/utils/time_format.dart';

void main() {
  test('parses ESP status JSON', () {
    final status = EspStatus.fromJson(const {
      'wifiConnected': true,
      'pump': false,
      'tankFull': true,
      'lockout': true,
      'runtime': 123,
    });

    expect(status.wifiConnected, isTrue);
    expect(status.pump, isFalse);
    expect(status.tankFull, isTrue);
    expect(status.lockout, isTrue);
    expect(status.runtime, 123);
  });

  test('formats runtime as HH:MM:SS', () {
    expect(formatRuntime(3661), '01:01:01');
  });
}
