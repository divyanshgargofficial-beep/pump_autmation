import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_settings.dart';

class SettingsService extends ChangeNotifier {
  static const _espAddressKey = 'esp_address';
  static const _useMdnsKey = 'use_mdns';

  AppSettings _settings = const AppSettings(
    espAddress: AppSettings.defaultMdnsAddress,
    useMdns: true,
  );

  AppSettings get settings => _settings;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _settings = AppSettings(
      espAddress:
          prefs.getString(_espAddressKey) ?? AppSettings.defaultMdnsAddress,
      useMdns: prefs.getBool(_useMdnsKey) ?? true,
    );
    notifyListeners();
  }

  Future<void> save(AppSettings settings) async {
    final normalized = _normalize(settings);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_espAddressKey, normalized.espAddress);
    await prefs.setBool(_useMdnsKey, normalized.useMdns);
    _settings = normalized;
    notifyListeners();
  }

  AppSettings _normalize(AppSettings settings) {
    final address = settings.espAddress.trim();
    final hasScheme =
        address.startsWith('http://') || address.startsWith('https://');

    return settings.copyWith(
      espAddress: hasScheme ? address : 'http://$address',
    );
  }
}
