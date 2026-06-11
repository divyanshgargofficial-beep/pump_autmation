import 'package:flutter/material.dart';

import '../models/app_settings.dart';
import '../services/settings_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    required this.settingsService,
    super.key,
  });

  final SettingsService settingsService;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _addressController;
  late bool _useMdns;

  @override
  void initState() {
    super.initState();
    final settings = widget.settingsService.settings;
    _addressController = TextEditingController(text: settings.espAddress);
    _useMdns = settings.useMdns;
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await widget.settingsService.save(
      AppSettings(
        espAddress: _addressController.text,
        useMdns: _useMdns,
      ),
    );

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('ESP address saved')),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Use mDNS discovery'),
            subtitle: const Text(AppSettings.defaultMdnsAddress),
            value: _useMdns,
            onChanged: (value) => setState(() => _useMdns = value),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _addressController,
            enabled: !_useMdns,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(
              labelText: 'ESP IP address',
              hintText: 'http://192.168.1.50',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: _save,
            icon: const Icon(Icons.save_outlined),
            label: const Text('SAVE SETTINGS'),
          ),
        ],
      ),
    );
  }
}
