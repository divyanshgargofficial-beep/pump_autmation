import 'package:flutter/material.dart';

import 'screens/dashboard_screen.dart';
import 'services/settings_service.dart';
import 'utils/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settingsService = SettingsService();
  await settingsService.load();

  runApp(WaterTankApp(settingsService: settingsService));
}

class WaterTankApp extends StatelessWidget {
  const WaterTankApp({required this.settingsService, super.key});

  final SettingsService settingsService;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Water Tank Controller',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: DashboardScreen(settingsService: settingsService),
    );
  }
}
