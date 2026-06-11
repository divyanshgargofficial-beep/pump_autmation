class EspStatus {
  const EspStatus({
    required this.wifiConnected,
    required this.pump,
    required this.tankFull,
    required this.lockout,
    required this.runtime,
  });

  final bool wifiConnected;
  final bool pump;
  final bool tankFull;
  final bool lockout;
  final int runtime;

  factory EspStatus.fromJson(Map<String, dynamic> json) {
    return EspStatus(
      wifiConnected: _readBool(json, 'wifiConnected'),
      pump: _readBool(json, 'pump'),
      tankFull: _readBool(json, 'tankFull'),
      lockout: _readBool(json, 'lockout'),
      runtime: _readInt(json, 'runtime'),
    );
  }

  static bool _readBool(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is bool) {
      return value;
    }
    throw FormatException('Expected boolean "$key" in ESP response.');
  }

  static int _readInt(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    throw FormatException('Expected integer "$key" in ESP response.');
  }
}
