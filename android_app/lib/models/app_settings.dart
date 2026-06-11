class AppSettings {
  const AppSettings({
    required this.espAddress,
    required this.useMdns,
  });

  static const defaultMdnsAddress = 'http://watertank.local';

  final String espAddress;
  final bool useMdns;

  AppSettings copyWith({
    String? espAddress,
    bool? useMdns,
  }) {
    return AppSettings(
      espAddress: espAddress ?? this.espAddress,
      useMdns: useMdns ?? this.useMdns,
    );
  }
}
